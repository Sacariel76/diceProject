---
title: Prompts Stitch UI UX
tags:
  - ui
  - ux
  - stitch
  - prompts
aliases:
  - Prompt pack Stitch
owner: SebastianRodMes
status: active
---

# Prompts Stitch UI UX

> [!info] Uso recomendado
> Ejecutar estos prompts por modulo en el orden definido en [[Modulos-UI-UX]].

## Prompt base (usar siempre)

```text
Disena interfaces para una app de juego de dados multijugador en tiempo real llamada "Dado Triple".
Plataformas: mobile first (Android/iOS) y variante web responsive.
Idioma: espanol.
Estilo visual: moderno tipo tabletop/casino elegante, limpio, legible y con jerarquia fuerte.
Paleta sugerida: verde mesa, marfil, carbon, acentos ambar/rojo para estados importantes (evitar morado como color principal).
Tipografia: expresiva para titulos y sans legible para contenido.
Incluir componentes reutilizables: cards, botones primario/secundario, chips de estado, dados, panel de puntuacion, banners de conexion.
Para cada pantalla incluye estados: normal, loading, vacio, error y desconectado.
Entregar layout de mobile y su adaptacion web.
```

## M0 - Fundacional UI

```text
Usando el contexto base, crea el Design System inicial:
1) tokens visuales (color, tipografia, spacing, radios, sombras),
2) biblioteca de componentes (botones, inputs, cards, modal, toast, badges, dados, tarjeta jugador),
3) patrones de navegacion (top bar, back, acciones primarias),
4) estados globales (loading, error, offline, exito).
Incluye una "UI kit page" y ejemplos de uso en mini-layouts.
```

## M1 - Acceso

```text
Disena el modulo de acceso:
- Splash/portada con branding "Dado Triple"
- Pantalla de inicio con acciones: "Crear sala" y "Unirse a sala"
- Formulario para nombre de jugador
- Flujo para ingresar codigo de sala
Incluye validaciones visuales (campos requeridos, formato de codigo), y estados de error (codigo invalido, servidor no disponible).
```

## M2 - Sala y Lobby

```text
Disena el modulo de sala/lobby:
- Pantalla de sala con codigo visible y boton copiar
- Lista de jugadores conectados
- Estado listo/no listo por jugador
- Controles del host: iniciar partida, expulsar jugador (si aplica), cancelar sala
Incluye estados: esperando jugadores, sala llena, jugador desconectado temporalmente.
Debe verse claramente quien es host y cuando se puede iniciar.
```

## M3 - Mesa de juego

```text
Disena la pantalla principal de juego:
- Zona de dados blancos (visibles para todos)
- Zona de dados de color en "torres" (ocultos para rivales)
- Panel lateral o superior con turno actual, ronda actual (de 4), y estado de fase
- Resumen rapido de puntaje por jugador
Prioriza claridad en tiempo real y acciones disponibles del usuario.
Incluye estado de "esperando a otros jugadores".
```

## M4 - Presentacion de combinacion

```text
Disena el flujo de seleccion de 3 dados:
- Interaccion para seleccionar/deseleccionar dados
- Vista previa de combinacion detectada (Triple/Escalera/Doble/Sencillo)
- Confirmacion de presentacion con modal de seguridad
- Feedback visual cuando la jugada es valida
Incluye mensajes claros para casos invalidos y confirmacion exitosa.
```

## M5 - Prediccion secreta

```text
Disena el flujo de carta de prediccion secreta:
- Seleccion entre Zero, Min, More, Max
- Explicacion corta de cada carta
- Confirmacion privada (sin revelar a otros)
- Estado de carta ya enviada
Debe transmitir confidencialidad y facilidad de uso en pocos toques.
```

## M6 - Resultado de ronda

```text
Disena resultados de ronda:
- Tabla con jugadores, combinacion presentada, puntos obtenidos y bonus de prediccion
- Indicadores de desempate y criterio usado
- Resumen de lider de ronda y acumulado total
- CTA para continuar a la siguiente presentacion/ronda
Incluye visualizacion clara para empates y division de puntos cuando aplique.
```

## M7 - Resultado final

```text
Disena pantalla final despues de 4 rondas:
- Ranking final completo
- Ganador destacado
- Resumen por ronda
- Botones: "Jugar de nuevo", "Volver al inicio", "Compartir resultado" (opcional)
Incluye estado especial cuando hay anulacion de victoria por empate definitivo segun reglas.
```

## M8 - Estados transversales

```text
Disena patrones UX transversales para tiempo real:
- Banner de reconexion
- Modal de desconexion critica
- Toast de evento recibido
- Pantalla de error recuperable con boton reintentar
- Estado cuando otro jugador abandona la sala
Todo debe ser consistente con el design system y no bloquear innecesariamente la partida.
```

## M9 - Ayuda y reglas

```text
Disena modulo de ayuda:
- Reglas resumidas y ejemplos visuales de Triple, Escalera, Doble, Sencillo
- Seccion de desempates
- Seccion de cartas de prediccion
- FAQ breve
Debe ser escaneable, didactico y usable durante la partida.
```

## Prompt completo (todo en una sola corrida)

> [!warning] Usar solo si el tiempo es limitado
> Es mejor modular, pero este prompt sirve para una corrida unica.

```text
Disena toda la experiencia UI/UX de "Dado Triple" (mobile first + web responsive) en espanol.
Incluye:
1) Design system completo,
2) Acceso (splash, inicio, crear/unirse),
3) Sala/lobby,
4) Mesa de juego en tiempo real,
5) Seleccion de combinacion,
6) Prediccion secreta,
7) Resultado de ronda,
8) Resultado final,
9) Estados transversales de red y error,
10) Pantalla de ayuda con reglas.
Estilo: elegante tipo mesa de juego, alta legibilidad, sin color morado dominante.
Agregar variantes: normal, loading, vacio, error, desconectado.
Entregar para mobile y adaptacion web por pantalla.
```

Relacionado: [[Implementacion-UI-UX]] y [[Modulos-UI-UX]].
