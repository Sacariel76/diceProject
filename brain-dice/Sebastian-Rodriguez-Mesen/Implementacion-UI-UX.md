---
title: Implementacion UI UX
tags:
  - integrante
  - ui
  - ux
  - stitch
  - plan
aliases:
  - Plan Sebas UI
owner: SebastianRodMes
status: active
---

# Implementacion UI UX

> [!info] Responsable
> Sebastian Rodriguez Mesen (`SebastianRodMes`)

## Navegacion del modulo

- [[Modulos-UI-UX]]
- [[Prompts-Stitch-UI-UX]]
- [[Planeacion-Implementacion-Flutter]]
- [[Checklist-UI-por-Pantalla]]

> [!note] Enfoque recomendado
> El diseno en Stitch se trabaja por modulo para iterar mas rapido y reducir retrabajo.

## Objetivo del modulo

Disenar y llevar a implementacion las pantallas y componentes del juego usando Stitch como base visual, asegurando consistencia y claridad de flujo en mobile y web.

## Contexto del proyecto

- Entrada actual de app: `lib/main.dart`.
- UI actual es solo prueba de socket; falta construir flujo completo del juego.
- Este modulo convierte mockups en vistas funcionales consumiendo datos del core y socket.

## Entregables obligatorios

- Mockups Stitch v1 para:
  - Inicio.
  - Crear/Unirse sala.
  - Lobby de espera.
  - Mesa de juego.
  - Resultados de ronda/final.
- Guia visual minima:
  - Tipografia y escala.
  - Paleta y estados.
  - Componentes base reutilizables.
- Implementacion Flutter de pantallas priorizadas por sprint.

## Propuesta tecnica

> [!tip] Estructura sugerida
> Crear cuando inicie implementacion:
>
> - `lib/screens/` para pantallas.
> - `lib/widgets/` para componentes reutilizables.
> - `lib/state/` para estado de interfaz (si aplica).

### Pantallas objetivo

- `HomeScreen`.
- `RoomAccessScreen`.
- `LobbyScreen`.
- `GameTableScreen`.
- `ResultsScreen`.

### Componentes sugeridos

- `DiceWidget`.
- `HiddenTowerWidget`.
- `PlayerCardWidget`.
- `ScoreBoardWidget`.
- `PredictionCardSelector`.

## Criterios de aceptacion

- Flujos navegables sin bloqueos.
- UI alineada a Stitch v1 aprobado.
- Estados vacio/cargando/error definidos.
- Accesibilidad basica (contraste y legibilidad).

## Backlog inicial del owner

- [ ] Definir flujo UX final en Stitch.
- [ ] Crear set de mockups v1 (mobile/web).
- [ ] Acordar componentes reutilizables.
- [ ] Implementar pantallas base (inicio, sala, lobby).
- [ ] Implementar mesa y resultados.
- [ ] Ajustar UI con feedback de QA.

## Dependencias y colaboracion

- Con [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic|owner Core]] para estructura de datos en pantalla.
- Con [[../Samiel-Marin-Cambronero/Implementacion-WebSocket|owner WebSocket]] para estados de conexion y eventos en tiempo real.

## Definicion de listo para PR

- [ ] Rama personal `dev/SebastianRodMes`.
- [ ] Issue asignado a `SebastianRodMes`.
- [ ] PR con evidencia visual (capturas/mockup).
- [ ] 1 aprobacion minima.
