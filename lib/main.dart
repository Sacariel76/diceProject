import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_theme.dart';
import 'app/router.dart';
import 'state/game_provider.dart';
import 'widgets/common/realtime_status_overlay.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => GameProvider(), child: const App()),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dado Triple',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            RealtimeStatusOverlay(
              onExitSession: () {
                context.read<GameProvider>().dismissCriticalDisconnect();
                appRouter.go('/home');
              },
            ),
          ],
        );
      },
    );
  }
}
