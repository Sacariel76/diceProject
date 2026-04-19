import 'dart:html' as html;

import 'package:flutter/services.dart';

Future<void> copyRoomCodeToClipboard(String roomCode) async {
  final clipboard = html.window.navigator.clipboard;
  if (clipboard != null) {
    try {
      await clipboard.writeText(roomCode);
      return;
    } catch (_) {
      // Some browsers block navigator.clipboard in insecure contexts.
    }
  }

  await Clipboard.setData(ClipboardData(text: roomCode));
}
