String? validarNombre(String? valor) =>
    (valor ?? '').trim().isEmpty ? 'Ingresa tu nombre.' : null;
String? validarCorreo(String? valor) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((valor ?? '').trim())
    ? null
    : 'Ingresa un correo válido.';
String? validarContrasena(String? valor) => (valor ?? '').length < 8
    ? 'La contraseña debe tener al menos 8 caracteres.'
    : null;
String? validarConfirmacion(String? valor, String contrasena) {
  if (valor == null || valor.isEmpty) return 'Confirma tu contraseña.';
  return valor == contrasena ? null : 'Las contraseñas no coinciden.';
}
