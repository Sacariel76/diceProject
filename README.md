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

* 📁 **`models/`**: Contiene las clases de datos puras. Aquí se define la estructura lógica de los objetos del juego que no tienen interfaz gráfica (ej. `Dado`, `Jugador`, `Partida`).
* 📁 **`screens/`**: Almacena las pantallas principales de la aplicación (vistas completas). Por ejemplo, la pantalla de inicio para unirse a la sala, la mesa de juego principal y la pantalla de puntajes finales.
* 📁 **`widgets/`**: Componentes visuales reutilizables. Elementos de UI independientes que se repiten en varias partes de la app, como el diseño visual de un dado individual, la "torre" para ocultar los dados o las tarjetas de perfil de los rivales.
* 📁 **`services/`**: Maneja toda la comunicación con el exterior. Aquí reside la lógica de red, específicamente el gestor de WebSockets encargado de enviar y recibir las acciones (en formato JSON) hacia y desde el servidor centralizado.
* 📁 **`state/`**: Controladores y gestores del estado local de la aplicación. Se encarga de notificar a la interfaz gráfica cuándo los datos de la partida cambian (ej. cuando otro jugador lanza sus dados o termina la ronda).
* 📁 **`utils/`**: Herramientas globales y lógica de negocio pura. Incluye archivos críticos como `game_rules.dart`, donde se alojan los algoritmos matemáticos para calcular los puntos, determinar desempates y evaluar las combinaciones presentadas.

## 🚀 Configuración Inicial

Este proyecto es el punto de partida para la aplicación. Para levantar el entorno de desarrollo localmente:

1. Clonar este repositorio.
2. Asegurarse de tener el [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y la variable `Path` configurada en el sistema.
3. Ejecutar `flutter pub get` en la terminal para descargar todas las dependencias requeridas.
4. Ejecutar `flutter run` teniendo un emulador de Android/iOS abierto o un dispositivo físico conectado.

Para más ayuda con el desarrollo en Flutter, consulta la [documentación en línea](https://docs.flutter.dev/).

## 📦 Dependencias

Para el funcionamiento de este proyecto, se han integrado las siguientes librerías clave:

* flutter pub add web_socket_channel
* **dart:convert:** Librería nativa de Dart empleada para la serialización y deserialización de objetos JSON, permitiendo que la App y el servidor de Rust intercambien datos complejos de forma eficiente.

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
19. Son 4 rondas y el juego termina justo después de la 4ta ronda, el que tenga la mayor cantidad de puntos gana, en caso de que varios tengan el mismo puntaje al finalizar, la victoria se anulará y se la dará al siguiente en la lista del puntaje del más alto.
