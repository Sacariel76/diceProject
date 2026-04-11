import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/access/home_screen.dart';
import '../screens/access/player_name_screen.dart';
import '../screens/access/join_room_screen.dart';
import '../screens/lobby/lobby_screen.dart';
import '../screens/room/room_host_screen.dart';
import '../screens/room/room_guest_screen.dart';
import '../screens/game/game_table_screen.dart';
import '../screens/game/select_dice_screen.dart';
import '../screens/game/prediction_screen.dart';
import '../screens/results/round_results_screen.dart';
import '../screens/results/final_results_screen.dart';
import '../screens/help/help_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
    GoRoute(
      path: '/player-name',
      builder: (ctx, state) {
        final action = state.uri.queryParameters['action'] ?? 'create';
        return PlayerNameScreen(action: action);
      },
    ),
    GoRoute(
      path: '/join-room',
      builder: (ctx, state) => const JoinRoomScreen(),
    ),
    GoRoute(
      path: '/room-host',
      builder: (ctx, state) => const RoomHostScreen(),
    ),
    GoRoute(
      path: '/room-guest',
      builder: (ctx, state) => const RoomGuestScreen(),
    ),
    GoRoute(path: '/lobby', builder: (ctx, state) => const LobbyScreen()),
    GoRoute(
      path: '/game-table',
      builder: (ctx, state) => const GameTableScreen(),
    ),
    GoRoute(
      path: '/play/select-dice',
      builder: (ctx, state) => const SelectDiceScreen(),
    ),
    GoRoute(
      path: '/play/prediction',
      builder: (ctx, state) {
        final combination =
            state.uri.queryParameters['combination'] ?? 'Sencillo';
        return PredictionScreen(combination: combination);
      },
    ),
    GoRoute(
      path: '/round-results',
      builder: (ctx, state) => const RoundResultsScreen(),
    ),
    GoRoute(
      path: '/final-results',
      builder: (ctx, state) => const FinalResultsScreen(),
    ),
    GoRoute(path: '/help', builder: (ctx, state) => const HelpScreen()),
  ],
);
