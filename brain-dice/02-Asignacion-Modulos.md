---
title: Asignacion de Modulos
tags:
  - equipo
  - roles
  - modulos
aliases:
  - Roles del equipo
status: active
---

# Asignacion de Modulos

> [!important] Principio de ownership
> Cada modulo tiene un owner primario y apoyo cruzado en review.

## Mapa de responsables

### Luis Alejandro Lopez Reyes (`LoesssLR`)

- Modulo: Core Game Logic.
- Responsabilidades:
  - Reglas de combinaciones (triple, escalera, doble, sencillo).
  - Desempates y ranking.
  - Puntajes por ronda y acumulados.
  - Regla de cartas de prediccion.
- Repositorio objetivo: app/web (logica compartida por comportamiento).

### Sebastian Rodriguez Mesen (`SebastianRodMes`)

- Modulo: UI/UX + Stitch.
- Responsabilidades:
  - Mockups en Stitch (mobile y web).
  - Sistema visual y consistencia de pantallas.
  - Componentes reutilizables y navegacion.
  - Ajustes de experiencia de usuario.
- Repositorio objetivo: app/web (presentacion).

### Samiel Marin Cambronero (`Sacariel76`)

- Modulo: Tiempo Real / WebSocket.
- Responsabilidades:
  - Conexion y reconexion.
  - Envio y recepcion de eventos JSON.
  - Manejo de errores de red y estados de sesion.
  - Sincronizacion de sala y turnos.
- Repositorio objetivo: app/web (flujo online).

## Matriz RACI simplificada

| Area | Responsible | Accountable | Consulted | Informed |
| --- | --- | --- | --- | --- |
| Core Game Logic | LoesssLR | LoesssLR | SebastianRodMes, Sacariel76 | Equipo |
| WebSocket y sync | Sacariel76 | Sacariel76 | LoesssLR, SebastianRodMes | Equipo |
| UI/UX y Stitch | SebastianRodMes | SebastianRodMes | LoesssLR, Sacariel76 | Equipo |

## Regla de reviews

- Ningun owner aprueba su propio PR.
- Todo PR debe tener minimo 1 aprobacion de otro integrante.
- Si un cambio toca mas de un modulo, se solicita review al owner afectado.

Relacionado: [[03-Flujo-GitHub]] y [[04-Flujo-Trello]].
