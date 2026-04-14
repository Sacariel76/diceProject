---
title: Backlog Inicial
tags:
  - backlog
  - tareas
  - inicio
aliases:
  - Tareas iniciales
status: active
---

# Backlog Inicial

> [!important] Nota
> Este backlog se transforma en Issues de GitHub y tarjetas de Trello.

## Diseno (Stitch)

- [x] Definir flujo UX completo (inicio, sala, lobby, mesa, resultados).
- [x] Crear mockups mobile v1.
- [x] Crear mockups web v1.
- [ ] Validar mockups con todo el equipo.

## Core (LoesssLR)

- [ ] Modelar entidades de juego para rondas y presentaciones.
- [ ] Implementar evaluacion de combinaciones.
- [ ] Implementar reglas de desempate.
- [ ] Implementar calculo de puntaje por ronda y total.
- [ ] Implementar cartas de prediccion y bonificacion.

## UI/UX (SebastianRodMes)

- [x] Implementar pantalla de inicio.
- [x] Implementar pantalla de lobby.
- [x] Implementar pantalla de mesa de juego.
- [x] Implementar pantalla de resultados.
- [x] Alinear componentes a Stitch v1.

## WebSocket (Sacariel76)

- [x] Definir contrato de eventos cliente-servidor.
- [x] Implementar crear sala y unirse sala.
- [x] Sincronizar estado de sala y turnos.
- [x] Manejar errores de conexion y reconexion.
- [ ] Estandarizar payloads de error al cliente.

## Gestion

- [ ] Crear board Trello con listas y etiquetas definidas en [[04-Flujo-Trello]].
- [ ] Invitar profesor al tablero.
- [ ] Crear ramas personales oficiales.
- [ ] Configurar protecciones de branch en GitHub.

## Pendientes bloqueantes para demo final

- [ ] Ejecutar QA end-to-end de 4 rondas con al menos 2 clientes y registrar evidencia.
- [ ] Cerrar y documentar regla oficial de desempate y bonus de prediccion entre README, backend y Flutter.
- [x] Formalizar contrato de eventos WebSocket (nombres, payloads y errores) con ejemplos JSON reales.
- [x] Verificar navegacion automatica por fase (`Prediction`, `RoundSummary`, `GameOver`) sin bloqueos de flujo.
- [ ] Validar manejo de reconexion/desconexion critica en partida activa (banner, modal, reintento y salida segura).
