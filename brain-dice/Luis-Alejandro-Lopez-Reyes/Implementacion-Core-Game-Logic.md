---
title: Implementacion Core Game Logic
tags:
  - integrante
  - core
  - game-logic
  - plan
aliases:
  - Plan Luis Core
owner: LoesssLR
status: active
---

# Implementacion Core Game Logic

> [!info] Responsable
> Luis Alejandro Lopez Reyes (`LoesssLR`)

## Objetivo del modulo

Implementar la logica de negocio del juego para clasificar combinaciones, calcular puntajes, resolver desempates y aplicar reglas de prediccion sin depender de la UI.

## Contexto del proyecto

- El proyecto actual tiene base Flutter minima en `lib/main.dart`.
- La comunicacion online existe como wrapper en `lib/services/websocket_service.dart`.
- Este modulo debe ser independiente de red para que sea testeable.

## Entregables obligatorios

- Motor de evaluacion de combinaciones:
  - Triple.
  - Escalera.
  - Doble.
  - Sencillo.
- Sistema de desempate por jerarquia y valores altos.
- Calculo de puntos por presentacion y ronda.
- Integracion de cartas de prediccion (Zero, Min, More, Max).
- API interna clara para consumo desde UI y capa de socket.

## Propuesta tecnica

> [!tip] Estructura sugerida
> Crear modulos nuevos dentro de `lib/` cuando inicie implementacion real:
>
> - `lib/models/` para entidades del juego.
> - `lib/utils/` para reglas y evaluadores puros.

### Entidades sugeridas

- `DieValue` (1..6).
- `CombinationType` (`triple`, `escalera`, `doble`, `sencillo`).
- `PresentedHand` (3 dados + metadatos).
- `RoundScore` (puntos de presentaciones + bonus).
- `PredictionCard` (`zero`, `min`, `more`, `max`).

### Funciones clave sugeridas

- `evaluateCombination(List<int> dice)`.
- `compareHands(PresentedHand a, PresentedHand b)`.
- `calculateRoundScore(...)`.
- `applyPredictionBonus(...)`.

## Criterios de aceptacion

- Reglas del README implementadas sin ambiguedad funcional.
- Metodos puros (sin dependencias de UI/socket).
- Cobertura de pruebas unitarias para casos normales y bordes.
- Documentacion corta de reglas y decisiones.

## Backlog inicial del owner

- [ ] Definir entidades del dominio.
- [ ] Implementar evaluador de combinaciones.
- [ ] Implementar comparador de desempates.
- [ ] Implementar puntaje por ronda.
- [ ] Implementar bonus por prediccion.
- [ ] Escribir pruebas unitarias de reglas.

## Dependencias y colaboracion

- Consulta con [[../Samiel-Marin-Cambronero/Implementacion-WebSocket|owner WebSocket]] para formato de payload de resultados.
- Consulta con [[../Sebastian-Rodriguez-Mesen/Implementacion-UI-UX|owner UI/UX]] para datos minimos a mostrar en pantallas.

## Definicion de listo para PR

- [ ] Rama personal `dev/LoesssLR`.
- [ ] Issue asignado a `LoesssLR`.
- [ ] PR con `Closes #ID`.
- [ ] 1 aprobacion minima.
