import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/database_helper.dart';
import '../models/perfil.dart';
import '../utils/app_colors.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _fraseController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _cargando = true;
  String _fotoPath = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final perfil = await DatabaseHelper.instance.getPerfil();

    if (perfil != null) {
      _nombreController.text = perfil.nombre;
      _apellidoController.text = perfil.apellido;
      _matriculaController.text = perfil.matricula;
      _fraseController.text = perfil.frase;
      _fotoPath = perfil.fotoPath;
    }

    setState(() {
      _cargando = false;
    });
  }

  Future<void> _seleccionarFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _fotoPath = image.path;
    });
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    final perfil = Perfil(
      id: 1,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      matricula: _matriculaController.text.trim(),
      fotoPath: _fotoPath,
      frase: _fraseController.text.trim(),
    );

    await DatabaseHelper.instance.savePerfil(perfil);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil guardado correctamente')),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white10,
    );
  }

  Widget _buildFotoPerfil() {
    if (_fotoPath.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, size: 50, color: Colors.white70),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundImage: FileImage(File(_fotoPath)),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _matriculaController.dispose();
    _fraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil / Acerca de'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFotoPerfil(),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _seleccionarFoto,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Seleccionar foto'),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Información del observador',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.light,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _nombreController,
                          decoration: _inputDecoration(
                            'Nombre',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese su nombre'
                                  : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _apellidoController,
                          decoration: _inputDecoration(
                            'Apellido',
                            icon: Icons.person,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese su apellido'
                                  : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _matriculaController,
                          decoration: _inputDecoration(
                            'Matrícula',
                            icon: Icons.badge,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese su matrícula'
                                  : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _fraseController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'Frase motivadora',
                            icon: Icons.format_quote,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese una frase'
                                  : null,
                        ),
                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _guardarPerfil,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}