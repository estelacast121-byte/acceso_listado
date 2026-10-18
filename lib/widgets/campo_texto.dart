import 'package:flutter/material.dart';

/// Un mismo campo resuelve etiquetas, iconos, errores y visibilidad de claves.
class CampoTexto extends StatefulWidget {
  const CampoTexto({super.key, required this.controlador, required this.etiqueta,
    required this.validar, this.esContrasena = false, this.tipoTeclado,
    this.alCambiar, this.claveCampo, this.habilitado = true, this.ayuda});
  final TextEditingController controlador;
  final String etiqueta;
  final String? Function(String?) validar;
  final bool esContrasena;
  final TextInputType? tipoTeclado;
  final ValueChanged<String>? alCambiar;
  final GlobalKey<FormFieldState<String>>? claveCampo;
  final bool habilitado;
  final String? ayuda;
  @override
  State<CampoTexto> createState() => _CampoTextoState();
}
class _CampoTextoState extends State<CampoTexto> {
  bool _ocultar = true;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      TextFormField(key: widget.claveCampo, controller: widget.controlador,
        enabled: widget.habilitado,
        decoration: InputDecoration(
          hintText: widget.esContrasena ? 'Mínimo 8 caracteres' : widget.tipoTeclado == TextInputType.emailAddress ? 'nombre@dominio.com' : 'Tu nombre completo',
          helperText: widget.ayuda, helperMaxLines: 2, errorMaxLines: 3,
          prefixIcon: Icon(widget.esContrasena ? Icons.lock_outline : widget.tipoTeclado == TextInputType.emailAddress ? Icons.mail_outline : Icons.person_outline),
          suffixIcon: widget.esContrasena ? IconButton(
            tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: widget.habilitado ? () => setState(() => _ocultar = !_ocultar) : null,
            icon: Icon(_ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined)) : null),
        obscureText: widget.esContrasena && _ocultar,
        autocorrect: !widget.esContrasena, enableSuggestions: !widget.esContrasena,
        keyboardType: widget.tipoTeclado, validator: widget.validar,
        onChanged: widget.alCambiar, autovalidateMode: AutovalidateMode.onUserInteraction),
    ]));
}
