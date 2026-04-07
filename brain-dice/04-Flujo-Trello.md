---
title: Flujo Trello
tags:
  - trello
  - gestion
  - tareas
aliases:
  - Tablero de trabajo
status: active
---

# Flujo Trello

> [!info] Objetivo
> Trazar tareas, responsables y avance en paralelo con GitHub para demostrar control del proceso.

## Listas del tablero

- `Backlog`
- `Ready`
- `In Progress`
- `Review PR`
- `QA`
- `Done`

## Etiquetas sugeridas

- `app-core`
- `app-ws`
- `app-ui`
- `web-core`
- `web-ws`
- `web-ui`
- `blocked`
- `high-priority`

## Plantilla de tarjeta

```markdown
Titulo: [APP][WS] Reconexion al perder red

Descripcion:
- Objetivo:
- Criterios de aceptacion:

GitHub:
- Issue: <url>
- Branch: dev/<usuario>
- PR: <url>

Checklist DoD:
- [ ] Implementado
- [ ] Probado local
- [ ] PR abierto
- [ ] Review aprobado
- [ ] Merge realizado
```

## Reglas de movimiento

- Issue creado y bien definido -> `Ready`.
- Desarrollo iniciado -> `In Progress`.
- PR abierto -> `Review PR`.
- Validacion funcional -> `QA`.
- Merge + verificacion final -> `Done`.

## Stitch dentro del tablero

- Crear tarjeta por pantalla: Inicio, Lobby, Mesa, Resultados.
- Adjuntar enlace/export de Stitch en cada tarjeta.
- Marcar `done` solo cuando la UI implementada coincida con el mockup aprobado.

## Participacion del profesor

> [!tip] Transparencia
> Invitar al profesor al tablero para revisar avance, asignaciones y evidencias de PR por integrante.

Relacionado: [[03-Flujo-GitHub]] y [[05-Sprints]].
