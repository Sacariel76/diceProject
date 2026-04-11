---
title: Checklist UI por Pantalla
tags:
  - integrante
  - ui
  - ux
  - flutter
  - qa
  - stitch
aliases:
  - QA UI Sebas
  - Checklist Stitch a Flutter
owner: SebastianRodMes
status: active
---

# Checklist UI por Pantalla

> [!info] Objetivo
> Checklist operativo para pasar mockups de Stitch a Flutter por pantalla, con control de estados, componentes, datos y eventos en tiempo real.

## Navegacion del modulo

- [[Implementacion-UI-UX]]
- [[Modulos-UI-UX]]
- [[Prompts-Stitch-UI-UX]]
- [[Planeacion-Implementacion-Flutter]]

## Regla de cierre por pantalla

- [x] Layout base implementado en Flutter.
- [x] Estado `normal` implementado.
- [x] Estado `loading` implementado.
- [x] Estado `error` implementado.
- [x] Estado `desconectado` implementado (si aplica).
- [x] Validaciones de UI aplicadas (botones, formularios, mensajes).
- [x] Conectada a datos reales (core + websocket).
- [ ] Evidencia visual adjunta en PR (mobile y web cuando aplique).

## M0 - Fundacional UI

### Splash

- Referencia: `stitch/splash_screen/code.html`
- [x] Pantalla de carga inicial con identidad visual.
- [x] Estado de inicializacion de app conectado al flujo real.
- [x] Navegacion automatica a acceso al completar init.

### Design system

- Referencia: `stitch/ivory_felt/DESIGN.md`
- [x] Paleta y tokens base definidos en `ThemeData`.
- [x] Tipografia definida para titulos y contenido.
- [x] Estilos de botones, chips, cards y modales reutilizables.

## M1 - Acceso

### Inicio de acceso

- Referencia: `stitch/inicio_de_acceso/code.html`
- [x] CTA `Crear sala` y `Unirse a sala` implementados.
- [x] Navegacion correcta segun accion seleccionada.

### Registro de jugador

- Referencia: `stitch/registro_de_jugador/code.html`
- [x] Formulario de nombre de jugador con validacion.
- [x] Boton de continuar habilitado solo con input valido.

### Ingreso de codigo con error

- Referencia: `stitch/ingreso_de_c_digo_error/code.html`
- [x] Input de codigo de sala (6 caracteres) implementado.
- [x] Mensaje de error por codigo invalido.
- [x] Manejo de error de servidor no disponible.

## M2 - Lobby

### Lobby principal

- Referencia: `stitch/lobby_principal_m_vil/code.html`
- [x] Lista de partidas y accion de unirse.
- [x] Tarjetas de estadisticas/perfil visibles.
- [x] Empty state cuando no hay partidas activas.

## M3 - Sala y espera

### Sala host

- Referencia: `stitch/sala_de_espera_host/code.html`
- [x] Codigo de sala visible con accion copiar.
- [x] Lista de jugadores con estado `ready/not ready`.
- [x] Control host: iniciar partida/cancelar sala.

### Sala invitado

- Referencia: `stitch/sala_de_espera_invitado/code.html`
- [x] Vista de espera para invitados.
- [x] Indicador de host y estado de jugadores.
- [x] Estado de reconexion no bloqueante.

### Jugador abandono sala

- Referencia: `stitch/jugador_abandon_sala/code.html`
- [x] Overlay o mensaje de abandono aplicado.
- [x] Comportamiento de pausa/reanudacion segun reglas.

## M4 - Mesa de juego

### Esperando turno

- Referencia: `stitch/mesa_de_juego_esperando/code.html`
- [x] Estado visual de espera de oponentes.
- [x] Acciones bloqueadas cuando no es turno del jugador.

### Gameplay principal

- Referencia: `stitch/mesa_de_juego_gameplay/code.html`
- [x] Zona de dados visibles y ocultos implementada.
- [x] Panel de ronda/turno/fase actualizado en tiempo real.
- [x] Acciones principales (`lanzar`, `pasar turno`) conectadas.

### Variante mobile

- Referencia: `stitch/mesa_de_juego_m_vil/code.html`
- [x] Layout mobile first optimizado para lectura rapida.
- [x] Panel de puntajes compacto y navegable.

### Variante web

- Referencia: `stitch/mesa_de_juego_web/code.html`
- [x] Layout responsive en desktop implementado.
- [x] Panel lateral de actividad/chat (si aplica) visible.

## M5 - Presentacion de combinacion

### Seleccion activa de dados

- Referencia: `stitch/selecci_n_de_dados_activa/code.html`
- [x] Interaccion seleccionar/deseleccionar dados.
- [x] Preview de combinacion detectada.

### Error de seleccion

- Referencia: `stitch/error_de_selecci_n_feedback/code.html`
- [x] Mensaje de validacion cuando faltan dados.
- [x] CTA de confirmacion bloqueada en estado invalido.

### Confirmacion de jugada

- Referencia: `stitch/confirmaci_n_de_jugada_modal/code.html`
- [x] Modal de confirmacion con cancelar/confirmar.
- [x] Envio de jugada al backend solo tras confirmacion.

## M6 - Prediccion secreta

### Seleccion de prediccion

- Referencia: `stitch/selecci_n_de_predicci_n/code.html`
- [x] Cartas `Zero`, `Min`, `More`, `Max` seleccionables.
- [x] Estado visual de seleccion actual.

### Confirmacion de prediccion

- Referencia: `stitch/confirmaci_n_de_predicci_n/code.html`
- [x] Modal de confirmacion privada.
- [x] Texto y UX de confidencialidad aplicado.

### Prediccion enviada

- Referencia: `stitch/predicci_n_enviada/code.html`
- [x] Estado de espera por otros jugadores (`N/total`).
- [x] Bloqueo de reenvio luego de confirmar.

## M7 - Resultados

### Resultado de ronda

- Referencia: `stitch/resultados_de_la_ronda/code.html`
- [x] Tabla de puntajes por jugador y bonus.
- [x] Nota de desempate visible cuando aplique.
- [x] CTA para continuar a siguiente ronda.

### Resultado final (partida completa)

- Referencia: `stitch/resultados_finales_partida_completa/code.html`
- [x] Ranking final completo implementado.
- [x] Acciones `Jugar de nuevo` y `Volver al inicio`.

### Resultado final (empate)

- Referencia: `stitch/resultados_finales_empate/code.html`
- [x] Estado especial de empate tecnico.
- [x] Mensaje de reglas de desempate claro.

## M8 - Estados transversales

### Banner y toast de conexion

- Referencia: `stitch/banner_y_toast_de_conexi_n/code.html`
- [x] Banner de reconexion global en tiempo real.
- [x] Toast de eventos del sistema sin bloquear flujo.

### Desconexion critica modal

- Referencia: `stitch/desconexi_n_cr_tica_modal/code.html`
- [x] Modal bloqueante con `Reintentar` y `Salir`.
- [x] Manejo de salida segura de sesion.

### Error recuperable

- Referencia: `stitch/error_recuperable/code.html`
- [x] Vista de error recuperable con boton reintento.
- [x] Codigo de error visible para soporte tecnico.

### Estado de error movil

- Referencia: `stitch/estado_de_error_m_vil/code.html`
- [x] Pantalla mobile de error de conexion.
- [x] CTA de recuperacion y sincronizacion.

## M9 - Ayuda y reglas

### Manual de reglas

- Referencia: `stitch/manual_de_reglas_y_ayuda/code.html`
- [x] Reglas resumidas y escaneables.
- [x] Ejemplos visuales de combinaciones.
- [x] Seccion de desempates y predicciones.
- [x] FAQ breve dentro de la app.

## Checklist de integracion con WebSocket

- [x] `create_room` conectado desde acceso.
- [x] `join_room` conectado desde ingreso de codigo.
- [x] Eventos de sala (`player_joined`, `player_left`, `player_ready_changed`) conectados en M3.
- [x] Eventos de turno/fase (`turn_changed`, `phase_changed`, `dice_rolled`) conectados en M4.
- [x] Eventos de jugada/prediccion (`hand_submitted`, `prediction_submitted`) conectados en M5 y M6.
- [x] Eventos de cierre (`round_result_ready`, `final_result_ready`, `tie_detected`) conectados en M7.
- [x] Estados de conectividad (`reconnecting`, `reconnected`, `critical_disconnect`) conectados en M8.

## Definicion de listo para PR (UI)

- [ ] Issue asignado al owner de UI/UX.
- [ ] Mockup de referencia indicado en descripcion del PR.
- [ ] Capturas de evidencia mobile/web incluidas.
- [ ] Flujo principal probado manualmente (acceso -> sala -> mesa -> resultados).
- [ ] Review de Core y WebSocket cuando hay impacto cruzado.
