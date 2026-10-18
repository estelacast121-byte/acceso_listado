import 'package:flutter_riverpod/flutter_riverpod.dart';

final sesionProvider = NotifierProvider<Sesion, String?>(Sesion.new);

class Sesion extends Notifier<String?> {
  @override
  String? build() => null;
  Future<void> iniciar(String correo) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!ref.mounted) return;
    state = correo.trim();
  }

  void cerrar() => state = null;
}
