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

## Dependencias y colaboracion

- Con [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic|owner Core]] para payload de resultados y puntaje.
- Con [[../Sebastian-Rodriguez-Mesen/Implementacion-UI-UX|owner UI/UX]] para estados visibles de conexion y errores.

## Definicion de listo para PR

- [ ] Rama personal `dev/Sacariel76`.
- [ ] Issue asignado a `Sacariel76`.
- [ ] PR con ejemplos de payload en descripcion.
- [ ] 1 aprobacion minima.
