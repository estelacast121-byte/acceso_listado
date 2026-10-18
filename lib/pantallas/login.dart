import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../estado/sesion.dart';
import '../utilidades/validaciones.dart';
import '../widgets/campo_texto.dart';
import '../widgets/marca_acceso.dart';
import 'registro.dart';
import 'listado.dart';

class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});
  @override
  ConsumerState<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends ConsumerState<PantallaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;
  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    if (_cargando || !_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(sesionProvider.notifier).iniciar(_correo.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const PantallaListado()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo iniciar sesión. Intenta de nuevo.';
      });
    }
  }

  Future<void> _abrirRegistro() async {
    final correo = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const PantallaRegistro()));
    if (!mounted || correo == null) return;
    _correo.text = correo;
    _contrasena.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro completado. Ya puedes iniciar sesión.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  const Center(child: MarcaAcceso()),
                  const SizedBox(height: 18),
                  const EtiquetaAcceso(texto: 'ACCESO Y LISTADO'),
                  const SizedBox(height: 12),
                  Text('Bienvenido', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Inicia sesión para continuar en el sistema', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  CampoTexto(
                    controlador: _correo,
                    etiqueta: 'Correo electrónico',
                    validar: validarCorreo,
                    tipoTeclado: TextInputType.emailAddress,
                    ayuda: 'Usa un correo con formato válido.',
                    habilitado: !_cargando,
                  ),
                  CampoTexto(
                    controlador: _contrasena,
                    etiqueta: 'Contraseña',
                    validar: validarContrasena,
                    esContrasena: true,
                    habilitado: !_cargando,
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FilledButton(
                    onPressed: _cargando ? null : _iniciar,
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Iniciar sesión'), SizedBox(width: 12), Icon(Icons.arrow_forward)]),
                  ),
                  const SizedBox(height: 16),
                  const Text('¿No tienes una cuenta?', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _cargando ? null : _abrirRegistro,
                    child: const Text('Crear cuenta'),
                  ),
                  const Text(
                    'Acceso de demostración: usa cualquier correo válido y una contraseña de 8 caracteres o más.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
