import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/observacion.dart';
import '../utils/app_colors.dart';
import 'detalle_observacion_screen.dart';

class ListaObservacionesScreen extends StatefulWidget {
  const ListaObservacionesScreen({super.key});

  @override
  State<ListaObservacionesScreen> createState() =>
      _ListaObservacionesScreenState();
}

class _ListaObservacionesScreenState extends State<ListaObservacionesScreen> {
  late Future<List<Observacion>> _observacionesFuture;

  final TextEditingController _lugarController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  String? _categoriaSeleccionada;

  final List<String> _categorias = [
    'Todas',
    'Fenómeno atmosférico',
    'Astronomía',
    'Aves',
    'Aeronave/Objeto artificial',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _cargarObservaciones();
  }

  void _cargarObservaciones() {
    _observacionesFuture = DatabaseHelper.instance.getObservaciones();
  }

  Future<void> _aplicarFiltros() async {
    setState(() {
      _observacionesFuture = DatabaseHelper.instance.getObservacionesFiltradas(
        categoria: (_categoriaSeleccionada == null ||
                _categoriaSeleccionada == 'Todas')
            ? null
            : _categoriaSeleccionada,
        lugar: _lugarController.text.trim().isEmpty
            ? null
            : _lugarController.text.trim(),
        fecha: _fechaController.text.trim().isEmpty
            ? null
            : _fechaController.text.trim(),
      );
    });
  }

  Future<void> _limpiarFiltros() async {
    _lugarController.clear();
    _fechaController.clear();

    setState(() {
      _categoriaSeleccionada = 'Todas';
      _cargarObservaciones();
    });
  }

  Future<void> _seleccionarFecha() async {
    final DateTime ahora = DateTime.now();

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    setState(() {
      _fechaController.text = DateFormat('yyyy-MM-dd').format(fecha);
    });
  }

  Future<void> _refrescar() async {
    await _aplicarFiltros();
  }

  String _formatearFecha(String fechaHora) {
    try {
      final fecha = DateTime.parse(fechaHora);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return fechaHora;
    }
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

  @override
  void dispose() {
    _lugarController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de observaciones'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_alt, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.light,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada ?? 'Todas',
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
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _lugarController,
                      decoration: _inputDecoration(
                        'Lugar',
                        icon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _fechaController,
                      readOnly: true,
                      onTap: _seleccionarFecha,
                      decoration: _inputDecoration(
                        'Fecha',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _aplicarFiltros,
                            icon: const Icon(Icons.search),
                            label: const Text('Aplicar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Observacion>>(
              future: _observacionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Ocurrió un error al cargar las observaciones'),
                  );
                }

                final observaciones = snapshot.data ?? [];

                if (observaciones.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay observaciones registradas con esos filtros',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: observaciones.length,
                    itemBuilder: (context, index) {
                      final obs = observaciones[index];

                      return Card(
                        color: AppColors.card,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: Icon(Icons.star, color: Colors.white),
                          ),
                          title: Text(
                            obs.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.light,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${obs.categoria}\n${obs.ubicacionTexto ?? "Sin ubicación"}\n${_formatearFecha(obs.fechaHora)}',
                              style: const TextStyle(color: AppColors.light),
                            ),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleObservacionScreen(
                                  observacionId: obs.id!,
                                ),
                              ),
                            ).then((_) => _aplicarFiltros());
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}