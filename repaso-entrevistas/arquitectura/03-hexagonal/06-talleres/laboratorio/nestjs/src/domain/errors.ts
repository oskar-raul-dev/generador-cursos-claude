// Errores de negocio del dominio: rechazos esperados con nombre propio. El borde les pone
// código HTTP; aquí no hay números.
export abstract class DomainError extends Error {
  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

export class EmptyOrder extends DomainError {
  constructor() {
    super("an order must have at least one line");
  }
}

export class OrderNotPayable extends DomainError {
  constructor(readonly status: string) {
    super(`order is ${status}`);
  }
}

export class OrderNotCancellable extends DomainError {
  constructor(readonly status: string) {
    super(`order is ${status}`);
  }
}

// La lanza el adaptador de inventario al primer faltante; la unidad de trabajo revierte el resto.
export class InsufficientInventory extends DomainError {
  constructor(
    readonly sku: string,
    readonly requested: number,
    readonly available: number,
    readonly lineIndex: number,
  ) {
    super(`${sku}: requested ${requested}, available ${available}`);
  }
}
