import 'package:flutter/material.dart';

import '../utilidades/validaciones.dart';
import '../widgets/campo_texto.dart';
import '../widgets/marca_acceso.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});
  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formulario = GlobalKey<FormState>();
  final _confirmacionCampo = GlobalKey<FormFieldState<String>>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _aceptaTerminos = false;
  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _registrar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.pop(context, _correo.text.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const EtiquetaAcceso(texto: 'ACCESO Y LISTADO')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: const Color(0xFF102C44), borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('REGISTRO', style: TextStyle(color: Color(0xFFBFD5F4), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text('Crear cuenta', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text('Completa tus datos para registrarte.', style: TextStyle(color: Color(0xFFCCD9EB))),
                    ])), const SizedBox(width: 12), const Icon(Icons.shield_outlined, size: 44, color: Color(0xFFBFD5F4))])),
                  const SizedBox(height: 24),
                  CampoTexto(
                    controlador: _nombre,
                    etiqueta: 'Nombre',
                    validar: validarNombre,
                  ),
                  CampoTexto(
                    controlador: _correo,
                    etiqueta: 'Correo electrónico',
                    validar: validarCorreo,
                    tipoTeclado: TextInputType.emailAddress,
                  ),
                  CampoTexto(
                    controlador: _contrasena,
                    etiqueta: 'Contraseña',
                    validar: validarContrasena,
                    esContrasena: true,
                    alCambiar: (_) {
                      if (_confirmacion.text.isNotEmpty) {
                        _confirmacionCampo.currentState?.validate();
                      }
                    },
                  ),
                  CampoTexto(
                    controlador: _confirmacion,
                    etiqueta: 'Confirmar contraseña',
                    claveCampo: _confirmacionCampo,
                    esContrasena: true,
                    validar: (valor) =>
                        validarConfirmacion(valor, _contrasena.text),
                  ),
                  const Text(
                    'Demostración académica: los datos no se guardan ni se crea una cuenta real.',
                  ),
                  FormField<bool>(
                    initialValue: false,
                    validator: (_) =>
                        _aceptaTerminos ? null : 'Debes aceptar los términos.',
                    builder: (campo) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Acepto los términos de esta demostración',
                          ),
                          value: _aceptaTerminos,
                          onChanged: (valor) {
                            setState(() => _aceptaTerminos = valor ?? false);
                            campo.didChange(_aceptaTerminos);
                            campo.validate();
                          },
                        ),
                        if (campo.hasError)
                          Text(
                            campo.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _registrar,
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Registrarme'), SizedBox(width: 12), Icon(Icons.arrow_forward)]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al inicio de sesión')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
