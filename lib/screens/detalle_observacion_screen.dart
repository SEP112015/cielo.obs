import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/observacion.dart';
import '../utils/app_colors.dart';

class DetalleObservacionScreen extends StatefulWidget {
  final int observacionId;

  const DetalleObservacionScreen({
    super.key,
    required this.observacionId,
  });

  @override
  State<DetalleObservacionScreen> createState() =>
      _DetalleObservacionScreenState();
}

class _DetalleObservacionScreenState extends State<DetalleObservacionScreen> {
  Observacion? _observacion;
  bool _cargando = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _cargarObservacion();
  }

  Future<void> _cargarObservacion() async {
    final data = await DatabaseHelper.instance
        .getObservacionById(widget.observacionId);

    setState(() {
      _observacion = data;
      _cargando = false;
    });
  }

  String _formatearFecha(String fechaHora) {
    try {
      final fecha = DateTime.parse(fechaHora);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return fechaHora;
    }
  }

  Widget _buildCampo(String titulo, String valor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(color: AppColors.light),
          ),
        ],
      ),
    );
  }

  String _ubicacionGpsTexto() {
    if (_observacion?.lat != null && _observacion?.lng != null) {
      return 'Latitud: ${_observacion!.lat!.toStringAsFixed(6)}\nLongitud: ${_observacion!.lng!.toStringAsFixed(6)}';
    }
    return 'No se capturó ubicación GPS';
  }

  Future<void> _reproducirAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir audio: $e'),
        ),
      );
    }
  }

  Future<void> _eliminarObservacion() async {
    if (_observacion == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar observación'),
          content: const Text(
            '¿Seguro que deseas eliminar esta observación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await DatabaseHelper.instance.deleteObservacion(_observacion!.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Observación eliminada')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de observación'),
        actions: [
          IconButton(
            onPressed: _eliminarObservacion,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _observacion == null
              ? const Center(child: Text('No se encontró la observación'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 60,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _observacion!.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.light,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_observacion!.fotoPath != null &&
                              _observacion!.fotoPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_observacion!.fotoPath!),
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          if (_observacion!.audioPath != null &&
                              _observacion!.audioPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _reproducirAudio(_observacion!.audioPath!),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Reproducir nota de voz'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),

                          _buildCampo(
                            'Fecha y hora',
                            _formatearFecha(_observacion!.fechaHora),
                          ),
                          _buildCampo('Categoría', _observacion!.categoria),
                          _buildCampo(
                            'Condiciones del cielo',
                            _observacion!.condicionesCielo,
                          ),
                          _buildCampo(
                            'Ubicación manual',
                            _observacion!.ubicacionTexto ?? 'No especificada',
                          ),
                          _buildCampo('Ubicación GPS', _ubicacionGpsTexto()),
                          _buildCampo(
                            'Duración estimada',
                            _observacion!.duracionSeg != null
                                ? '${_observacion!.duracionSeg} segundos'
                                : 'No especificada',
                          ),
                          _buildCampo('Descripción', _observacion!.descripcion),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}