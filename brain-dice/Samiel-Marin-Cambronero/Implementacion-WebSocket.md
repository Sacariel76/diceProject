---
title: Implementacion WebSocket
tags:
  - integrante
  - websocket
  - realtime
  - plan
aliases:
  - Plan Samiel WebSocket
owner: Sacariel76
status: active
---

# Implementacion WebSocket

> [!info] Responsable
> Samiel Marin Cambronero (`Sacariel76`)

## Objetivo del modulo

Definir y robustecer la comunicacion en tiempo real cliente-servidor para soporte de salas, turnos y sincronizacion del juego.

## Contexto del proyecto

- Servicio actual: `lib/services/websocket_service.dart`.
- Endpoint hardcodeado actual: `ws://3.228.25.228:5000`.
- Existe conexion basica y envio/recepcion simple; falta formalizar contrato y manejo de estado.

## Entregables obligatorios

- Contrato de eventos JSON cliente-servidor documentado.
- Manejo de eventos clave:
  - `create_room`.
  - `join_room`.
  - Eventos de turno y presentacion.
  - Eventos de cierre de ronda.
- Manejo de errores y reconexion.
- Mapeo de mensajes a modelos internos.

## Propuesta tecnica

> [!tip] Evolucion sugerida del servicio
> Mantener `WebSocketService` como fachada y separar:
>
> - `socket_events.dart` (tipos de evento).
> - `socket_models.dart` (payloads tipados).
> - `socket_mapper.dart` (json <-> modelo).

### Responsabilidades tecnicas

- Normalizar payloads enviados.
- Validar payloads recibidos.
- Manejar desconexion y reintento controlado.
- Exponer estado de conexion para UI.

## Criterios de aceptacion

- Eventos criticos sin errores de parseo.
- Reconexion funcional sin romper sesion del usuario.
- Mensajes de error consistentes para UI.
- Pruebas basicas de flujo online (crear/unirse y recibir estado).

## Backlog inicial del owner

- [ ] Definir contrato de eventos con ejemplos JSON.
- [ ] Refactorizar servicio socket por capas.
- [ ] Implementar reconexion y manejo de estado.
- [ ] Implementar manejo de errores estandar.
- [ ] Probar flujo end-to-end con app.

## Contrato WS actual (cliente Flutter)

> [!note] Que significa "formalizar contrato"
> Es dejar por escrito, en un solo lugar, el idioma exacto entre app y backend: nombre de evento, campos obligatorios, tipos y errores esperados. Asi no se rompe la integracion cuando alguien cambia algo en backend o frontend.

### Reglas generales

- Todos los mensajes viajan en JSON.
- Todo mensaje debe incluir `type`.
- Si el backend responde `error`, se espera `message` y opcionalmente `code` o `error_code`.
- El cliente usa `state_update` como fuente de verdad del estado de partida.

### Cliente -> Servidor

#### `create_room`

```json
{
  "type": "create_room",
  "player_name": "Sebastian"
}
```

#### `join_room`

```json
{
  "type": "join_room",
  "player_name": "Luis",
  "room_code": "A1B2C3"
}
```

#### `start_game`

```json
{
  "type": "start_game",
  "room_code": "A1B2C3",
  "player_id": "p1"
}
```

#### `roll_all_dice`

```json
{
  "type": "roll_all_dice",
  "room_code": "A1B2C3",
  "player_id": "p1"
}
```

#### `submit_combination`

```json
{
  "type": "submit_combination",
  "room_code": "A1B2C3",
  "player_id": "p1",
  "dice_ids": ["w1", "w2", "r1"]
}
```

#### `select_prediction`

```json
{
  "type": "select_prediction",
  "room_code": "A1B2C3",
  "player_id": "p1",
  "prediction": "More"
}
```

### Servidor -> Cliente

#### `room_created`

Campos usados por cliente:

- `room_code` (String)
- `player_id` (String)

Ejemplo:

```json
{
  "type": "room_created",
  "room_code": "A1B2C3",
  "player_id": "p1"
}
```

#### `room_joined`

Campos usados por cliente:

- `room_code` (String)
- `player_id` (String)

Ejemplo:

```json
{
  "type": "room_joined",
  "room_code": "A1B2C3",
  "player_id": "p2"
}
```

#### `state_update`

Campos minimos esperados dentro de `state`:

- `room_code` (String)
- `current_round` (int)
- `started` (bool)
- `current_phase` (String): `WaitingPlayers`, `RollingDice`, `Prediction`, `Presentation1`, `Presentation2`, `Presentation3`, `RoundSummary`, `GameOver`
- `players` (List)

Campos adicionales que cliente ya consume cuando existen:

- `host_id`, `turn_order`, `turn_index`, `last_result`
- Por jugador: `id`/`player_id`, `name`/`player_name`, `connected`/`is_connected`, `prediction`, `score_round`, `score_total`, `dice`, `combinations_submitted`

Ejemplo:

```json
{
  "type": "state_update",
  "state": {
    "room_code": "A1B2C3",
    "host_id": "p1",
    "started": true,
    "current_round": 2,
    "current_phase": "RoundSummary",
    "turn_order": ["p2", "p1"],
    "turn_index": 0,
    "players": [
      {
        "id": "p1",
        "name": "Sebastian",
        "connected": true,
        "prediction": "More",
        "score_round": 8,
        "score_total": 23,
        "dice": [
          {"id": "w1", "value": 5, "hidden": false, "used": true},
          {"id": "r1", "value": 3, "hidden": true, "used": false}
        ],
        "combinations_submitted": [
          {"dice_ids": ["w1", "w2", "w3"], "combination": "Escalera"}
        ]
      }
    ],
    "last_result": {
      "tie": false,
      "round_scores": [
        {
          "player_id": "p1",
          "player_name": "Sebastian",
          "combination": "Escalera",
          "base_points": 6,
          "bonus_points": 2,
          "total_points": 8
        }
      ]
    }
  }
}
```

#### `error`

Campos usados por cliente:

- `message` (String)
- `code` o `error_code` (String, opcional)

Ejemplo:

```json
{
  "type": "error",
  "message": "Room code invalido",
  "code": "ROOM_NOT_FOUND"
}
```

### Matriz fase backend -> UI Flutter

| Fase backend (`state.current_phase`) | Estado Flutter (`GameTurnPhase`) | Ruta objetivo |
| --- | --- | --- |
| `WaitingPlayers` | `waiting` | sala/lobby |
| `RollingDice` | `rolling` | `/game-table` |
| `Prediction` | `predicting` | `/play/prediction` |
| `Presentation1/2/3` | `selecting` | `/game-table` + `/play/select-dice` |
| `RoundSummary` | `roundResults` | `/round-results` |
| `GameOver` | `finalResults` | `/final-results` |

### Estado de avance del contrato

- [x] Contrato base documentado con eventos clave y ejemplos JSON.
- [ ] Confirmar payload final de `last_result.round_scores` con backend Rust.
- [ ] Estandarizar catalogo de errores (`code`) compartido backend/frontend.

## Catalogo inicial de errores (frontend fallback)

> [!info] Nota operativa
> Si backend envia `code`, ese valor manda. Si no envia, Flutter aplica un fallback para mostrar soporte consistente en UI.

Codigos usados hoy por frontend:

- `CONN-INIT`: fallo al conectar al iniciar.
- `CONN-CLOSED`: servidor cerro conexion.
- `CONN-STREAM`: error de stream/socket activo.
- `CONN-CRITICAL`: error de conexion durante partida activa (modal bloqueante).
- `WS-ERROR`: error WS generico sin `code`.
- `ROOM-NOT-FOUND`: sala invalida/no encontrada (fallback por texto).
- `PREDICTION-INVALID`: prediccion invalida en fase/valor.
- `COMBINATION-INVALID`: combinacion invalida.
- `DICE-INVALID`: dados seleccionados invalidos.
- `TURN-NOT-ALLOWED`: accion fuera de turno.
- `PHASE-INVALID`: accion fuera de fase.

Ejemplo recomendado backend:

```json
{
  "type": "error",
  "message": "No puedes enviar combinacion fuera de fase",
  "code": "PHASE-INVALID"
}
```

## Dependencias y colaboracion

- Con [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic|owner Core]] para payload de resultados y puntaje.
- Con [[../Sebastian-Rodriguez-Mesen/Implementacion-UI-UX|owner UI/UX]] para estados visibles de conexion y errores.

## Definicion de listo para PR

- [ ] Rama personal `dev/Sacariel76`.
- [ ] Issue asignado a `Sacariel76`.
- [ ] PR con ejemplos de payload en descripcion.
- [ ] 1 aprobacion minima.
