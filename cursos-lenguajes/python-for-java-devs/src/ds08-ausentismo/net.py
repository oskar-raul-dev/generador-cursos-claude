"""La red neuronal: un perceptrón multicapa sobre las mismas cinco variables.

    from net import train_network, score_network

Cinco entradas, dos capas ocultas, una salida. En CPU, sobre 72.396 filas. No es una red
grande y ese es el punto: **es la red que alguien construiría de verdad para este problema**,
no un modelo de juguete puesto para perder ni un transformer puesto para impresionar.

🧭 **Todo lo que decide el resultado se fija y se declara**: la semilla, la arquitectura, el
optimizador, el tamaño del lote y el criterio de parada. Un modelo cuyo resultado cambia
entre corridas no se puede comparar con nada, y menos con una regresión logística que es
determinista.

⚠️ **El escalado es el mismo de `ds07`, ajustado solo con el tramo de entrenamiento.** Una
red sin escalar no converge con estas variables —la distancia va de 0,8 a 34 y la lluvia de 0
a 30— y escalarla con el conjunto completo sería la fuga silenciosa que `ds07` §5.3 explica.
"""

from __future__ import annotations

from dataclasses import dataclass

from shared import build_matrix

# La arquitectura. Dos capas ocultas de 16 y 8 con ReLU: suficiente para representar
# interacciones entre las cinco variables y lo bastante chica para entrenar en segundos.
# Crecerla es el ejercicio 12, y la sección 6 dice qué pasa cuando se hace.
HIDDEN = (16, 8)

SEED = 20260913
EPOCHS = 60
BATCH_SIZE = 512
LEARNING_RATE = 0.01

# Paciencia del criterio de parada: épocas sin mejorar la pérdida de validación antes de
# cortar. Sin esto, la red sigue "mejorando" sobre el entrenamiento mucho después de haber
# dejado de mejorar sobre datos que no ha visto, y el resultado que se reporta es el de una
# red sobreajustada.
PATIENCE = 8


@dataclass(frozen=True, slots=True)
class TrainingReport:
    """Lo que hay que saber de un entrenamiento para poder discutirlo."""

    epochs_run: int
    best_epoch: int
    train_loss: float
    validation_loss: float
    parameters: int
    seconds: float


def _tensors(rows, mean, deviation):
    import torch

    matrix, target = build_matrix(rows)
    features = torch.tensor(matrix, dtype=torch.float32)
    features = (features - mean) / deviation
    return features, torch.tensor(target, dtype=torch.float32).unsqueeze(1)


def _scaler(rows):
    """Media y desviación del **entrenamiento**, nada más. Devueltas como tensores."""
    import torch

    matrix, _ = build_matrix(rows)
    data = torch.tensor(matrix, dtype=torch.float32)
    deviation = data.std(dim=0)
    # Una columna constante tendría desviación cero y produciría infinitos silenciosos.
    deviation[deviation == 0] = 1.0
    return data.mean(dim=0), deviation


def build_network(inputs: int):
    import torch
    from torch import nn

    torch.manual_seed(SEED)
    layers: list[nn.Module] = []
    previous = inputs
    for width in HIDDEN:
        layers += [nn.Linear(previous, width), nn.ReLU()]
        previous = width
    layers.append(nn.Linear(previous, 1))
    return nn.Sequential(*layers)


def train_network(train_rows, validation_fraction: float = 0.2):
    """Entrena y devuelve (red, escalador, informe).

    La validación sale del **final** del tramo de entrenamiento, no de una muestra al azar:
    es el mismo criterio temporal de `ds07`, aplicado una vez más hacia adentro. Cortar por
    pérdida de validación usando un trozo elegido al azar sería decidir cuándo parar con
    información del futuro.
    """
    import time

    import torch
    from torch import nn

    started = time.perf_counter()
    split_at = int(len(train_rows) * (1 - validation_fraction))
    fit_rows, validation_rows = train_rows[:split_at], train_rows[split_at:]

    mean, deviation = _scaler(fit_rows)
    features, target = _tensors(fit_rows, mean, deviation)
    validation_features, validation_target = _tensors(validation_rows, mean, deviation)

    torch.manual_seed(SEED)
    network = build_network(features.shape[1])
    optimizer = torch.optim.Adam(network.parameters(), lr=LEARNING_RATE)
    # `BCEWithLogitsLoss` y no `BCELoss` sobre una sigmoide: es numéricamente estable y es
    # la razón de que la red devuelva logits y la sigmoide viva en `score_network`.
    criterion = nn.BCEWithLogitsLoss()

    best_loss, best_state, best_epoch = float("inf"), None, 0
    generator = torch.Generator().manual_seed(SEED)

    for epoch in range(1, EPOCHS + 1):
        network.train()
        order = torch.randperm(len(features), generator=generator)
        for start in range(0, len(order), BATCH_SIZE):
            batch = order[start:start + BATCH_SIZE]
            optimizer.zero_grad()
            loss = criterion(network(features[batch]), target[batch])
            loss.backward()
            optimizer.step()

        network.eval()
        with torch.no_grad():
            validation_loss = float(criterion(network(validation_features),
                                              validation_target))
            train_loss = float(criterion(network(features), target))

        if validation_loss < best_loss - 1e-5:
            best_loss, best_epoch = validation_loss, epoch
            best_state = {key: value.clone()
                          for key, value in network.state_dict().items()}
        elif epoch - best_epoch >= PATIENCE:
            break

    if best_state is not None:
        network.load_state_dict(best_state)

    report = TrainingReport(
        epochs_run=epoch, best_epoch=best_epoch, train_loss=train_loss,
        validation_loss=best_loss,
        parameters=sum(parameter.numel() for parameter in network.parameters()),
        seconds=time.perf_counter() - started)
    return network, (mean, deviation), report


def score_network(network, scaler, rows) -> list[float]:
    """Probabilidad de **no** asistir, fila por fila. La sigmoide se aplica aquí."""
    import torch

    mean, deviation = scaler
    features, _ = _tensors(rows, mean, deviation)
    network.eval()
    with torch.no_grad():
        return torch.sigmoid(network(features)).squeeze(1).tolist()
