---
title: Modulos UI UX
tags:
  - ui
  - ux
  - modulos
  - stitch
aliases:
  - Modulos de interfaz
owner: SebastianRodMes
status: active
---

# Modulos UI UX

> [!info] Objetivo
> Definir todos los modulos visuales de la app para diseno incremental en Stitch, manteniendo consistencia con las reglas del juego y flujo en tiempo real.

## Orden recomendado de diseno

1. M0 - Fundacional UI.
2. M1 - Acceso.
3. M2 - Sala y Lobby.
4. M3 - Mesa de juego.
5. M4 - Presentacion de combinacion.
6. M5 - Prediccion secreta.
7. M6 - Resultado de ronda.
8. M7 - Resultado final.
9. M8 - Estados transversales.
10. M9 - Ayuda y reglas.

> [!tip] Regla practica
> Cada modulo debe incluir estados: normal, cargando, vacio, error y desconectado.

## M0 - Fundacional UI

- Alcance: tokens visuales, componentes base, patrones de navegacion.
- Pantallas: UI kit page y layout de referencia mobile/web.
- Resultado esperado: lenguaje visual unificado para todos los modulos.

## M1 - Acceso

- Alcance: splash, inicio, nombre de jugador, crear/unirse sala.
- Resultado esperado: entrada al juego clara con validaciones de formulario.

## M2 - Sala y Lobby

- Alcance: codigo de sala, lista de jugadores, estado listo, controles de host.
- Resultado esperado: antesala de partida entendible y controlada.

## M3 - Mesa de juego

- Alcance: tablero principal, dados visibles/ocultos, turno y ronda, resumen de puntaje.
- Resultado esperado: pantalla principal legible en tiempo real.

## M4 - Presentacion de combinacion

- Alcance: seleccion de 3 dados, validacion, vista previa de combinacion, confirmacion.
- Resultado esperado: decision de jugada sin ambiguedad.

## M5 - Prediccion secreta

- Alcance: seleccion de carta Zero/Min/More/Max, confirmacion privada.
- Resultado esperado: accion rapida y confidencial.

## M6 - Resultado de ronda

- Alcance: ranking de ronda, puntos por combinacion, bonus por prediccion, desempate.
- Resultado esperado: transparencia de puntajes.

## M7 - Resultado final

- Alcance: ranking final, ganador, resumen por rondas, acciones posteriores.
- Resultado esperado: cierre de experiencia con claridad.

## M8 - Estados transversales

- Alcance: reconexion, offline, errores de servidor, abandono de jugador, reintento.
- Resultado esperado: UX estable ante fallas de red.

## M9 - Ayuda y reglas

- Alcance: reglas resumidas, ejemplos de combinaciones, desempates y predicciones.
- Resultado esperado: consulta rapida dentro de la app.

## Dependencias con otros modulos

- Core de reglas: [[../Luis-Alejandro-Lopez-Reyes/Implementacion-Core-Game-Logic]].
- Tiempo real: [[../Samiel-Marin-Cambronero/Implementacion-WebSocket]].
- Flujo global: [[../03-Flujo-GitHub]] y [[../04-Flujo-Trello]].
