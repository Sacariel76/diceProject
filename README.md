# 🎲 Proyecto Final: Dado Triple

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## 📋 Información General

* **Universidad:** Universidad Técnica Nacional (UTN) - Sede Pacífico
* **Curso:** ITI-721 - Desarrollo de Aplicaciones para Dispositivos Móviles II
* **Profesor:** Jorge Ruiz.
* **Periodo:** 1C-2026.
* **Integrantes:**
    * Luis Alejandro López Reyes
    * Sebastián Rodriguez Mesen
    * Samiel Marín Cambronero

## 🏗️ Estructura del Proyecto (Arquitectura)

Para mantener el código escalable, limpio y separado por responsabilidades, el proyecto utiliza una arquitectura orientada a funcionalidades. Todo el código fuente se encuentra dentro del directorio `lib/`:

* 📄 **`main.dart`**: Punto de entrada de la app. Inicializa tema, rutas y el proveedor principal de estado.
* 📁 **`app/`**: Configuración global (tema, colores y enrutamiento con `go_router`).
* 📁 **`models/`**: Clases de datos (`player_model.dart`, `round_score_model.dart`).
* 📁 **`screens/`**: Pantallas agrupadas por flujo/feature: `access/`, `lobby/`, `room/`, `game/`, `results/`, `help/`, `splash/`, `dev/`.
* 📁 **`widgets/`**: UI reutilizable. `common/` (app bar, navegación, overlay de estado) y `game/` (dados).
* 📁 **`services/`**: Comunicación en tiempo real (`websocket_service.dart`). El servidor WebSocket corre en una VM (EC2) de AWS con backend en Rust y base de datos MongoDB.
* 📁 **`state/`**: Estado central con `GameProvider` (ChangeNotifier) y sincronización con el WebSocket.
* 📁 **`utils/`**: Utilidades de plataforma, como el portapapeles de código de sala (`room_code_clipboard.dart` + variantes web/IO).

## 🚀 Configuración Inicial

Este proyecto es el punto de partida para la aplicación. Para levantar el entorno de desarrollo localmente:

1. Clonar este repositorio.
2. Asegurarse de tener el [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y la variable `Path` configurada en el sistema.
3. Ejecutar `flutter pub get` en la terminal para descargar todas las dependencias requeridas.
4. Ejecutar `flutter run` teniendo un emulador de Android/iOS abierto o un dispositivo físico conectado.

Para más ayuda con el desarrollo en Flutter, consulta la [documentación en línea](https://docs.flutter.dev/).

## 📦 Dependencias

Para el funcionamiento de este proyecto, se han integrado las siguientes librerías clave:

* **web_socket_channel:** Comunicación en tiempo real vía WebSocket.
* **provider:** Manejo del estado con `GameProvider`.
* **go_router:** Enrutamiento declarativo de pantallas.
* **google_fonts:** Tipografías personalizadas.
* **dart:convert:** Serialización y deserialización JSON entre app y servidor.

## 📜 Reglas del Juego

**Objetivo principal:** Alcanzar la mayor puntuación posible jugando con tres dados.

### Reglas para el jugador:

1. Cada jugador recibe 9 dados blancos normales, 1 rojo y 1 azul.
2. Cuando inicie la partida cada jugador deberá lanzar los 9 dados blancos.
3. Los dados blancos que sean lanzados son abiertos, es decir, todos los demás jugadores pueden ver el resultado.
4. Después de lanzar los dados blancos, cada jugador debe poner los dados de colores en las llamadas "torres de dados", las cuales ocultarán los resultados de los dados lanzados dentro, solo los dueños de los dados pueden verlos.
5. Después de lanzar todos los dados, los jugadores deberán escoger tres para presentar como su primera combinación de puntos, se pueden elegir también los dados de colores.
6. Los dados ocultos son revelados después de que todos los jugadores hayan presentado sus combinaciones.
7. Al terminar la ronda los puntos de los dados serán sumados de forma clasificada dependiendo de las clasificaciones (combinaciones) de los dados presentados, las combinaciones son:
   * **Triple:** Los tres dados deben ser del mismo número.
   * **Escalera:** Los tres dados deben estar de forma consecutiva (1,2,3) (6 y 1 no son considerados consecutivos).
   * **Doble:** Dos de los tres dados deben ser iguales (2,2,3).
   * **Sencillos:** No forma parte de ninguna de las clasificaciones anteriores.
8. En caso de que varios jugadores tengan la misma combinación (por ejemplo doble) su clasificación se determina por el jugador que tiene los números más altos, es decir, si dos jugadores sacan doble, uno con dos dados de 4 y el otro de 5, el de 5 se lleva la clasificación.
9. Si llega a suceder que los jugadores tienen por ejemplo dos dados de 5, el desempate viene con el número más alto del tercer dado.
10. Si las presentaciones de varios de los jugadores da Triple, la ronda queda en empate.
11. Los puntos de las clasificaciones son:
    * **Triple:** 6 puntos.
    * **Escalera:** 3 puntos.
    * **Doble:** 1 punto.
    * **Sencillo:** 0 puntos.
12. En el caso de un empate definitivo (cuando hay varios que presenten la misma combinación exacta), por ejemplo, cuando dos jugadores sacan una clasificación Triple, los resultados de la clasificación Triple y Escalera se suman y son divididos a los jugadores involucrados.
13. Para la segunda presentación, el jugador que tenga el puntaje más alto de la ronda pasada irá primero seleccionando 3 de los 8 dados que le queden para su segunda presentación.
14. Si varios jugadores llegan a empatar en las clasificaciones de la presentación anterior el que tenga la mayor cantidad de puntos va primero.
15. Al hacer la tercera presentación se escogen 3 dados más y los dos restantes se descartan, así terminado la primera ronda.
16. Antes de presentar las presentaciones de cada ronda, los jugadores darán una carta de predicción secreta al grupo prediciendo su puntaje para la ronda.
17. Hay 4 tarjetas de predicción a elegir:
    * **Zero:** El puntaje de la ronda quede en 0.
    * **Min:** El puntaje de la ronda queda entre 1 y 6.
    * **More:** El puntaje de la ronda queda entre 7 y 10.
    * **Max:** El puntaje de la ronda queda de 10 para arriba.
18. Los jugadores que predigan su puntuación de forma correcta en esa ronda se le recompensará con puntos adicionales dependiendo de la carta seleccionada, en caso de acertar, al jugador se le otorgarán el doble del puntaje que tenga en ese momento, sin embargo, el que prediga un puntaje de 0 se le otorgarán 40 puntos automáticamente.
19. Son 4 rondas (2 para la demostración) y el juego termina justo después de la 4ta ronda, el que tenga la mayor cantidad de puntos gana, en caso de que varios tengan el mismo puntaje al finalizar, la victoria se anulará y se la dará al siguiente en la lista del puntaje del más alto.

## 🔄 Lógica y Flujo de Desarrollo

Para la implementación técnica en Flutter, el ciclo de vida del juego y la gestión de la visibilidad de datos se rigen bajo los siguientes parámetros:

### 🏗️ Ciclo de Vida de la Partida (Game Loop)

La partida se compone de 4 Rondas Grandes (2 para efectos de demostración). Cada una de estas rondas debe ejecutar obligatoriamente las siguientes fases:

#### Fase 1: Preparación y Lanzamiento

* **Generación de Dados:** El backend (o el gestor de estado) genera 11 valores aleatorios (1-6) por jugador.
* **Gestión de Visibilidad:**
    * **9 Dados Blancos:** Públicos (visibles en la UI de todos los jugadores).
    * **1 Dado Rojo y 1 Azul:** Privados (almacenados en la "Torre de Dados", solo visibles para el dueño).
* **Fase de Predicción:** Antes de jugar, cada jugador envía su carta de predicción (Zero, Min, More, Max). Esta información permanece encriptada/oculta para los oponentes hasta el cierre de la ronda.

#### Fase 2: Ciclo de las 3 Presentaciones

Cada ronda se divide en tres actos de selección:

* **Presentación 1:** Selección simultánea de 3 dados. Se revela el puntaje y se determina el orden de turno para la siguiente fase.
* **Presentación 2:** El jugador con mayor puntaje en la P1 elige primero sus 3 dados de los 8 restantes.
* **Presentación 3:** Se eligen 3 dados de los 5 restantes. Los 2 dados sobrantes se marcan como descartados en el estado de la aplicación.

#### Fase 3: Resolución y Bonificaciones

* **Cálculo Total:** Se suma el puntaje bruto de las tres presentaciones.
* **Validación de Carta:** El sistema compara el total obtenido con la predicción inicial:
    * **Acierto:** Se aplica el multiplicador (x2) o el bono de +40 (si fue Zero).
    * **Fallo:** Se conserva únicamente el puntaje base de la ronda.

### 📊 Matriz de Visibilidad de Datos

| Información | Jugador Dueño | Oponentes | Lógica (Backend/State) |
| --- | --- | --- | --- |
| Dados Blancos | ✅ Visible | ✅ Visible | ✅ Registrado |
| Dados de Color | ✅ Visible | ❌ Oculto | ✅ Registrado |
| Carta de Predicción | ✅ Visible | ❌ Oculto | ✅ Registrado |
| Dados en Mano | ✅ Visible | ❌ Oculto | ✅ Registrado |
| Dados Presentados | ✅ Visible | ✅ Visible | ✅ Procesado |

### 🛠️ Algoritmo de Evaluación de Combinaciones

La detección de la combinación que se muestra al usuario se realiza en la UI (por ejemplo, en `SelectDiceScreen`) con la siguiente jerarquía de prioridad:

* **Triple (6 pts):** `d1 == d2 && d2 == d3`.
* **Escalera (3 pts):** Se ordena la lista y se verifica que sean consecutivos. Importante: La combinación `(6, 1, 2)` no es válida.
* **Doble (1 pt):** Al menos dos dados iguales.
* **Sencillo (0 pts):** No cumple ninguna de las anteriores.

**Nota sobre Desempates:** Si dos jugadores presentan la misma combinación (ej. Doble), el sistema compara el valor nominal de los dados. Si el empate persiste, se suman los puntos de la categoría y se dividen equitativamente entre los involucrados.

### 💡 Notas de Implementación (Flutter)

* **Gestión de Estado:** Se utiliza Provider con `GameProvider` para sincronizar los datos recibidos por WebSocket y la UI en tiempo real.
* **Componentes Visuales:** El DiceWidget debe ser capaz de renderizar diferentes temas (Blanco, Rojo, Azul) y estados (Oculto en torre/Revelado).
* **Seguridad de la Información:** La lógica de "qué dados tiene el rival" no debe enviarse completa a todos los clientes para evitar trampas (inspección de estado), solo se deben enviar los datos marcados como "Públicos" en la matriz de visibilidad.
