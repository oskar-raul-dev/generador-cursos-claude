-- =====================================================================================
-- Cordillera Media · SIGE · Observabilidad del codigo heredado
-- Fase 19 — la sesion de eventos extendidos que permite ver DENTRO de un procedimiento
--           de 1997 y correlacionar cada instruccion con la traza que la origino.
--
-- ⚠️ ESTE ARCHIVO ES INSTRUMENTACION, NO MIGRACION.
--    Vive en legacy/ a proposito: no cambia el estilo del proyecto ni lo mueve a modern/,
--    porque lo que entra aqui no es logica de negocio. Es la unica excepcion declarada
--    del curso a "el legado no se toca sin cambiar de generacion"
--    (prompts/congelamiento-de-nombres.md §2).
--
-- ⚠️ Y TIENE COSTO EN EL MOTOR. Se activa para diagnosticar y SE APAGA. Dejarla prendida
--    permanentemente es una de las lineas que la fase 20 tiene que costear, y la medicion
--    de la fase 19 la mide aparte por esa razon.
-- =====================================================================================

USE master;
GO

-- -------------------------------------------------------------------------------------
-- 1. La sesion.
--
-- La clave del cruce del borde 🧬 esta en la ACCION sqlserver.session_context: el runner
-- de C# (TracedProcedureRunner) fija el identificador de traza por conexion con
-- sp_set_session_context, y cada evento que se captura lo trae adjunto. Sin esa accion,
-- esta sesion dice que algo tardo pero no de que peticion venia.
--
-- El filtro por duracion es deliberado: SP_CATALOGO tiene 340 lineas y capturar todas
-- produce mas ruido que dato. 100.000 microsegundos = 100 ms.
-- -------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = N'cordillera_legacy')
    DROP EVENT SESSION [cordillera_legacy] ON SERVER;
GO

CREATE EVENT SESSION [cordillera_legacy] ON SERVER

-- Cada instruccion DENTRO de un procedimiento almacenado. Es el evento que abre el borde.
ADD EVENT sqlserver.sp_statement_completed (
    ACTION (
        sqlserver.session_context,      -- ← el identificador de traza, puesto por el runner
        sqlserver.sql_text,
        sqlserver.database_name,
        sqlserver.client_app_name
    )
    WHERE duration > 100000             -- microsegundos: solo lo que pasa de 100 ms
),

-- Y el procedimiento completo, para poder comprobar que las partes suman el total.
-- Si no suman, falta una instruccion por capturar — y es probablemente la interesante.
ADD EVENT sqlserver.module_end (
    ACTION (
        sqlserver.session_context,
        sqlserver.database_name,
        sqlserver.client_app_name
    )
    WHERE duration > 100000
)

ADD TARGET package0.event_file (
    SET filename        = N'cordillera_legacy.xel',
        max_file_size   = 64,          -- MB por archivo
        max_rollover_files = 4         -- 256 MB en total y se recicla: no llena el disco
)
WITH (
    MAX_MEMORY                  = 8 MB,
    EVENT_RETENTION_MODE        = ALLOW_SINGLE_EVENT_LOSS,   -- ← perder un evento antes que frenar el motor
    MAX_DISPATCH_LATENCY        = 10 SECONDS,
    STARTUP_STATE               = OFF                        -- ← NO arranca con el motor. Se enciende a mano.
);
GO

-- -------------------------------------------------------------------------------------
-- 2. Encender y apagar. Las dos lineas que hay que tener a mano.
-- -------------------------------------------------------------------------------------
-- ALTER EVENT SESSION [cordillera_legacy] ON SERVER STATE = START;
-- ALTER EVENT SESSION [cordillera_legacy] ON SERVER STATE = STOP;
GO

-- -------------------------------------------------------------------------------------
-- 3. Leer lo capturado, ya correlacionado con la traza.
--
-- Esta consulta es la que convierte "el catalogo esta lento" en el reparto de la tabla A
-- de la medicion de la fase 19: cada instruccion del procedimiento, su duracion, y la
-- traza de la peticion HTTP que la origino.
-- -------------------------------------------------------------------------------------
WITH eventos AS (
    SELECT CAST(event_data AS xml) AS dato
    FROM sys.fn_xe_file_target_read_file(N'cordillera_legacy*.xel', NULL, NULL, NULL)
)
SELECT
    dato.value('(event/@timestamp)[1]',                                'datetime2')    AS momento,
    dato.value('(event/@name)[1]',                                     'varchar(60)')  AS evento,
    dato.value('(event/data[@name="duration"]/value)[1]',              'bigint') / 1000
                                                                                       AS duracion_ms,
    dato.value('(event/data[@name="object_name"]/value)[1]',           'varchar(128)') AS objeto,
    dato.value('(event/data[@name="statement"]/value)[1]',             'nvarchar(max)') AS instruccion,
    -- El identificador de traza viaja en el contexto de sesion. Este es el campo que
    -- pega este archivo con la traza de OpenTelemetry del lado moderno.
    dato.value('(event/action[@name="session_context"]/value)[1]',      'nvarchar(max)') AS contexto_sesion
FROM eventos
ORDER BY duracion_ms DESC;
GO

-- -------------------------------------------------------------------------------------
-- 4. Lo que este archivo NO hace, y conviene que quede escrito.
--
--    No reconstruye el pasado. Lo que no estaba capturado cuando ocurrio, no existe —
--    y esa es la respuesta honesta a la pregunta del incidente de marzo (¿que consulto
--    ese traductor en dos anios?): la observabilidad responde hacia adelante.
--
--    No sustituye el plan de ejecucion. Esta sesion dice CUANTO tardo cada instruccion;
--    por que tardo lo dice el plan, y ese es el ejercicio 17 de la fase.
-- -------------------------------------------------------------------------------------
