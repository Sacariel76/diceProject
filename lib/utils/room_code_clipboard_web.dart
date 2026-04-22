import 'package:flutter/services.dart';

Future<void> copyRoomCodeToClipboard(String roomCode) async {
  await Clipboard.setData(ClipboardData(text: roomCode));
}
