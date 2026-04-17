---
title: Plan Integracion WS y Pendientes de Logica
tags:
  - integrante
  - websocket
  - flutter
  - backend
  - plan
aliases:
  - Plan WS Flutter AWS
owner: SebastianRodMes
status: active
---

# Plan Integracion WS y Pendientes de Logica

> [!info] Contexto actual
> Flutter ya se comunica con el backend Rust por WebSocket y consume `state_update` como fuente de verdad. El flujo base funciona en pruebas con 2 clientes (crear sala, unirse, iniciar, lanzar).

## Objetivo

Cerrar los pendientes de logica para que el flujo completo de partida (4 rondas) sea consistente entre reglas del README, backend Rust y UI Flutter.

## Estado validado

- Conexion WS activa contra `ws://34.232.89.243:5000`.
- Evento servidor principal: `state_update`.
- Flujo validado: crear sala, unir jugador, iniciar partida, lanzar dados.
- Fases backend detectadas: `WaitingPlayers`, `RollingDice`, `Prediction`, `Presentation1`, `Presentation2`, `Presentation3`, `RoundSummary`, `GameOver`.

## Pendientes de logica por cerrar

### 1) Regla final de desempates (definicion unica)

- Hay diferencia de interpretacion entre README y comportamiento backend.
- Decidir una sola regla oficial para empate exacto y documentarla.

> [!warning] Decision requerida
> Confirmar si el empate exacto reparte `9 / N` (como backend actual) o `puntos de categoria / N` (como se puede interpretar en README).

### 2) Navegacion automatica por fase (Flutter)

- Al entrar en `Prediction`, abrir pantalla de prediccion de forma guiada.
- Al entrar en `RoundSummary`, navegar a resultados de ronda.
- Al entrar en `GameOver`, navegar a resultados finales.

### 3) Presentaciones por ronda (P1, P2, P3)

- Mostrar claramente en UI cual presentacion toca.
- Bloquear envios extra cuando el jugador ya envio en esa presentacion.
- Confirmar orden de turno en P2 y P3 con `turn_order` y `turn_index` del backend.

### 4) Visibilidad de datos sensibles

- Mantener ocultos para oponentes:
  - `prediction`
  - valor de dados ocultos (`red/blue`) antes de resumen.
- Verificar que Flutter nunca renderiza datos privados de otro jugador fuera de fase permitida.

### 5) Bonificaciones de prediccion

- Confirmar con pruebas manuales que se aplica:
  - `ZERO` => +40 cuando ronda queda 0.
  - `MIN/MORE/MAX` => x2 cuando acierta rango.
- Reflejar correctamente en resultados de ronda y total.

### 6) Hardening operativo del servidor

- Levantar backend con `systemd` estable (sin procesos manuales paralelos).
- Definir script/comando unico para start/stop/logs.
- Dejar health-check basico (puerto activo y proceso unico).

## Plan de ejecucion recomendado

1. Alinear regla de desempate final (README + backend + Flutter).
2. Completar navegacion por fase y guardas de flujo en Flutter.
3. Verificar puntuacion y bonus en 4 rondas completas con 2 clientes.
4. Estabilizar despliegue backend con `systemd`.
5. Cerrar checklist y evidencia para PR final.

## Matriz comando -> respuesta esperada (contrato actual)

| Cliente Flutter envia | Backend responde | Impacto UI |
| --- | --- | --- |
| `create_room` | `room_created` + `state_update` | Sala host |
| `join_room` | `room_joined` + `state_update` | Sala invitado |
| `start_game` | `state_update` (`RollingDice`) | Mesa |
| `roll_all_dice` | `state_update` | Dados visibles/ocultos |
| `select_prediction` | `state_update` | Prediccion -> presentacion |
| `submit_combination` | `state_update` | Avance P1/P2/P3 y resumen |

## Verificacion manual sugerida

- Cliente A crea sala.
- Cliente B se une.
- Host inicia partida.
- Ambos lanzan dados.
- Ambos envian prediccion.
- Completar P1, P2 y P3 con turnos correctos.
- Validar resumen de ronda y acumulado total.
- Repetir hasta ronda 4 y validar `GameOver`.

## Dependencias

- Reglas oficiales: [[../README]] (fuente funcional).
- UI/UX owner: [[Implementacion-UI-UX]].
- WS owner: [[../Samiel-Marin-Cambronero/Implementacion-WebSocket]].
- Core owner: [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic]].
