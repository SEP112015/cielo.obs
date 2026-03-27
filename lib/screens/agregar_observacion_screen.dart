import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../db/database_helper.dart';
import '../models/observacion.dart';
import '../utils/app_colors.dart';

class AgregarObservacionScreen extends StatefulWidget {
  const AgregarObservacionScreen({super.key});

  @override
  State<AgregarObservacionScreen> createState() =>
      _AgregarObservacionScreenState();
}

class _AgregarObservacionScreenState extends State<AgregarObservacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _fechaHoraController = TextEditingController();
  final TextEditingController _ubicacionTextoController =
      TextEditingController();
  final TextEditingController _duracionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _categoriaSeleccionada;
  String? _condicionSeleccionada;
  String? _fotoPath;
  String? _audioPath;

  double? _lat;
  double? _lng;
  bool _obteniendoUbicacion = false;
  bool _grabando = false;

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final List<String> _categorias = [
    'Fenómeno atmosférico',
    'Astronomía',
    'Aves',
    'Aeronave/Objeto artificial',
    'Otro',
  ];

  final List<String> _condiciones = [
    'Despejado',
    'Nublado',
    'Bruma',
    'Lluvia ligera',
  ];

  Future<void> _seleccionarFechaHora() async {
    final DateTime ahora = DateTime.now();

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(ahora),
    );

    if (hora == null) return;

    final DateTime fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      _fechaHoraController.text =
          DateFormat('yyyy-MM-dd HH:mm').format(fechaHora);
    });
  }

  Future<void> _seleccionarFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _fotoPath = image.path;
    });
  }

  Future<void> _iniciarGrabacion() async {
    try {
      final tienePermiso = await _audioRecorder.hasPermission();

      if (!tienePermiso) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere permiso de micrófono para grabar audio'),
          ),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(),
        path: path,
      );

      setState(() {
        _grabando = true;
        _audioPath = path;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grabación iniciada'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar grabación: $e'),
        ),
      );
    }
  }

  Future<void> _detenerGrabacion() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _grabando = false;
        if (path != null) {
          _audioPath = path;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grabación detenida correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al detener grabación: $e'),
        ),
      );
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el GPS del dispositivo para continuar'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado'),
          ),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de ubicación bloqueado permanentemente',
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación capturada correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }

  Future<void> _guardarObservacion() async {
    if (!_formKey.currentState!.validate()) return;

    final observacion = Observacion(
      titulo: _tituloController.text.trim(),
      fechaHora: _fechaHoraController.text.trim(),
      ubicacionTexto: _ubicacionTextoController.text.trim().isEmpty
          ? null
          : _ubicacionTextoController.text.trim(),
      duracionSeg: _duracionController.text.trim().isEmpty
          ? null
          : int.tryParse(_duracionController.text.trim()),
      categoria: _categoriaSeleccionada!,
      condicionesCielo: _condicionSeleccionada!,
      descripcion: _descripcionController.text.trim(),
      creadoEn: DateTime.now().toIso8601String(),
      lat: _lat,
      lng: _lng,
      fotoPath: _fotoPath,
      audioPath: _audioPath,
    );

    await DatabaseHelper.instance.insertObservacion(observacion);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Observación guardada correctamente'),
      ),
    );

    _limpiarFormulario();
  }

  void _limpiarFormulario() {
    _tituloController.clear();
    _fechaHoraController.clear();
    _ubicacionTextoController.clear();
    _duracionController.clear();
    _descripcionController.clear();

    setState(() {
      _categoriaSeleccionada = null;
      _condicionSeleccionada = null;
      _fotoPath = null;
      _audioPath = null;
      _lat = null;
      _lng = null;
      _grabando = false;
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _fechaHoraController.dispose();
    _ubicacionTextoController.dispose();
    _duracionController.dispose();
    _descripcionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
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

  Widget _buildFotoPreview() {
    if (_fotoPath == null) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 50, color: Colors.white70),
            SizedBox(height: 8),
            Text(
              'No se ha seleccionado foto',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(_fotoPath!),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildUbicacionCard() {
    String texto;
    if (_lat != null && _lng != null) {
      texto =
          'Lat: ${_lat!.toStringAsFixed(6)}\nLng: ${_lng!.toStringAsFixed(6)}';
    } else {
      texto = 'No se ha capturado ubicación GPS';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.my_location, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Ubicación GPS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            style: const TextStyle(color: AppColors.light),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard() {
    String texto;
    if (_grabando) {
      texto = 'Grabando nota de voz...';
    } else if (_audioPath != null && _audioPath!.isNotEmpty) {
      texto = 'Audio grabado correctamente';
    } else {
      texto = 'No se ha grabado ninguna nota de voz';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Nota de voz',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            style: TextStyle(
              color: _grabando ? Colors.redAccent : AppColors.light,
              fontWeight: _grabando ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _grabando ? null : _iniciarGrabacion,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Grabar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _grabando ? _detenerGrabacion : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Detener'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva observación'),
      ),
      body: SingleChildScrollView(
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
                  const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Registrar observación del cielo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.light,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _tituloController,
                    decoration: _inputDecoration(
                      'Título de la observación',
                      icon: Icons.title,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _fechaHoraController,
                    readOnly: true,
                    onTap: _seleccionarFechaHora,
                    decoration: _inputDecoration(
                      'Fecha y hora',
                      icon: Icons.calendar_today,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Seleccione fecha y hora';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _ubicacionTextoController,
                    decoration: _inputDecoration(
                      'Ubicación manual (texto opcional)',
                      icon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildUbicacionCard(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _obteniendoUbicacion
                          ? null
                          : _obtenerUbicacionActual,
                      icon: _obteniendoUbicacion
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _obteniendoUbicacion
                            ? 'Obteniendo ubicación...'
                            : 'Capturar ubicación actual',
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _duracionController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Duración estimada en segundos (opcional)',
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: _inputDecoration(
                      'Categoría',
                      icon: Icons.category,
                    ),
                    items: _categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoriaSeleccionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _condicionSeleccionada,
                    decoration: _inputDecoration(
                      'Condiciones del cielo',
                      icon: Icons.cloud,
                    ),
                    items: _condiciones.map((condicion) {
                      return DropdownMenuItem(
                        value: condicion,
                        child: Text(condicion),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _condicionSeleccionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione una condición';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 5,
                    decoration: _inputDecoration(
                      'Descripción detallada',
                      icon: Icons.description,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFotoPreview(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFoto,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Seleccionar foto'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAudioCard(),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarObservacion,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar observación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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