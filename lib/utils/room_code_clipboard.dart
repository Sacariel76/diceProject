import 'room_code_clipboard_io.dart'
    if (dart.library.html) 'room_code_clipboard_web.dart'
    as impl;

Future<void> copyRoomCodeToClipboard(String roomCode) {
  return impl.copyRoomCodeToClipboard(roomCode);
}
