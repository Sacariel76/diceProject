---
title: Planeacion Implementacion Flutter UI UX
tags:
  - integrante
  - ui
  - ux
  - flutter
  - stitch
  - plan
aliases:
  - Plan Flutter Sebas
owner: SebastianRodMes
status: active
---

# Planeacion Implementacion Flutter UI UX

> [!info] Alcance
> Planeacion tecnica para convertir los mockups HTML de `E:\diceProject\stitch` en pantallas Flutter navegables y sincronizadas por WebSocket.

## Navegacion del modulo

- [[Implementacion-UI-UX]]
- [[Modulos-UI-UX]]
- [[Prompts-Stitch-UI-UX]]

## Estado actual del codigo

- Entrada de app actual: `lib/main.dart`.
- Servicio de red actual: `lib/services/websocket_service.dart`.
- La app aun es una prueba de socket (`TestSocketScreen`), sin flujo completo del juego.

## Referencias Stitch por modulo

### M0 - Fundacional

- `stitch/splash_screen/code.html`
- `stitch/ivory_felt/DESIGN.md`

### M1 - Acceso

- `stitch/inicio_de_acceso/code.html`
- `stitch/registro_de_jugador/code.html`
- `stitch/ingreso_de_c_digo_error/code.html`

### M2 - Lobby

- `stitch/lobby_principal_m_vil/code.html`

### M3 - Sala y espera

- `stitch/sala_de_espera_host/code.html`
- `stitch/sala_de_espera_invitado/code.html`
- `stitch/jugador_abandon_sala/code.html`

### M4 - Mesa de juego

- `stitch/mesa_de_juego_esperando/code.html`
- `stitch/mesa_de_juego_gameplay/code.html`
- `stitch/mesa_de_juego_m_vil/code.html`
- `stitch/mesa_de_juego_web/code.html`

### M5 - Presentacion de combinacion

- `stitch/selecci_n_de_dados_activa/code.html`
- `stitch/error_de_selecci_n_feedback/code.html`
- `stitch/confirmaci_n_de_jugada_modal/code.html`

### M6 - Prediccion secreta

- `stitch/selecci_n_de_predicci_n/code.html`
- `stitch/confirmaci_n_de_predicci_n/code.html`
- `stitch/predicci_n_enviada/code.html`

### M7 - Resultados

- `stitch/resultados_de_la_ronda/code.html`
- `stitch/resultados_finales_partida_completa/code.html`
- `stitch/resultados_finales_empate/code.html`

### M8 - Estados transversales

- `stitch/banner_y_toast_de_conexi_n/code.html`
- `stitch/desconexi_n_cr_tica_modal/code.html`
- `stitch/error_recuperable/code.html`
- `stitch/estado_de_error_m_vil/code.html`

### M9 - Ayuda y reglas

- `stitch/manual_de_reglas_y_ayuda/code.html`

## Matriz de implementacion Flutter

| Modulo | Rutas sugeridas | Datos minimos | Eventos WS | Estados UI | Prioridad |
| --- | --- | --- | --- | --- | --- |
| M0 | `/splash` | estado de inicializacion | `connection_state_changed` | loading, error init | Alta |
| M1 | `/home`, `/player-name`, `/join-room` | nombre de jugador, codigo de sala | `create_room`, `join_room`, `join_failed` | normal, error input, error server | Alta |
| M2 | `/lobby` | partidas activas, perfil, estadisticas | `lobby_updated` | loading, vacio, error, offline | Media |
| M3 | `/room-wait` | room code, jugadores, host, ready state | `player_joined`, `player_left`, `player_ready_changed`, `game_started` | waiting, reconnecting, player left | Alta |
| M4 | `/game-table` | ronda, turno, dados, score board | `turn_changed`, `dice_rolled`, `phase_changed` | esperando, en turno, offline | Alta |
| M5 | `/play/select-dice` | dados seleccionados, combinacion detectada | `hand_selection_updated`, `hand_submitted` | valido, invalido, confirm modal | Alta |
| M6 | `/play/prediction` | carta seleccionada, progreso de envio | `prediction_submitted`, `prediction_waiting` | normal, confirm, enviada | Alta |
| M7 | `/round-results`, `/final-results` | ranking, bonus, desempate | `round_result_ready`, `final_result_ready`, `tie_detected` | normal, empate, loading | Alta |
| M8 | overlays globales | estado de red y error code | `reconnecting`, `reconnected`, `critical_disconnect` | banner, toast, modal bloqueante, retry | Alta |
| M9 | `/help` | reglas, combinaciones, FAQ | opcional `rules_updated` | lectura, fallback de contenido | Baja |

## Flujo funcional target

1. `Splash` -> `Inicio acceso`.
2. Registro de jugador y crear/unirse sala.
3. Lobby y sala de espera (host o invitado).
4. Mesa de juego (esperando turno -> turno activo).
5. Seleccion de dados y confirmacion de jugada.
6. Prediccion secreta y confirmacion.
7. Resultados de ronda.
8. Resultado final (normal o empate).
9. Estados M8 pueden interrumpir cualquier paso sin romper sesion.

## Estructura Flutter sugerida

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  models/
  screens/
    splash/
    access/
    lobby/
    room/
    game/
    results/
    help/
  widgets/
    common/
    game/
  state/
    app_state.dart
    room_state.dart
    game_state.dart
    connection_state.dart
  services/
    websocket_service.dart
```

## Backlog tecnico por sprint

### Sprint 1 - Base navegable

- [ ] Crear rutas y shell de pantallas M0, M1 y M3.
- [ ] Formularios de nombre/codigo con validaciones.
- [ ] Integracion WS minima: crear sala y unirse sala.

### Sprint 2 - Loop de partida

- [ ] Implementar M4 mesa de juego (turno, ronda y score board).
- [ ] Implementar M5 seleccion/confirmacion de jugada.
- [ ] Integrar estados de error de seleccion y espera.

### Sprint 3 - Prediccion y cierre

- [ ] Implementar M6 prediccion secreta completa.
- [ ] Implementar M7 resultados de ronda y final.
- [ ] Soportar pantalla final de empate tecnico.

### Sprint 4 - Robustez UX

- [ ] Implementar M8 reconexion, offline y errores recuperables.
- [ ] Implementar M9 ayuda y reglas.
- [ ] Pulir responsive mobile/web y accesibilidad base.

## Criterios de aceptacion medibles

- Cada modulo implementa estados definidos: normal, loading, vacio (si aplica), error, desconectado.
- Flujo end-to-end ejecutable sin bloqueos: acceso -> partida -> resultados.
- Eventos WS actualizan UI en tiempo real sin reiniciar pantalla.
- Mesa de juego valida en mobile y en web.
- Cambios listos para PR con evidencia visual por pantalla.

## Dependencias cruzadas

- Reglas y puntaje: [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic|owner Core]].
- Contrato de eventos y reconexion: [[../Samiel-Marin-Cambronero/Implementacion-WebSocket|owner WebSocket]].
- Plan maestro y sprints: [[../01-Plan-Maestro]] y [[../05-Sprints]].
