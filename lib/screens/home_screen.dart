import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../utils/app_colors.dart';
import 'agregar_observacion_screen.dart';
import 'lista_observaciones_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _mostrarDialogoBorrarTodo(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar todo'),
          content: const Text(
            'Esta acción eliminará todas las observaciones y el perfil guardado en el dispositivo. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar todo'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await DatabaseHelper.instance.borrarTodo();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos los datos fueron eliminados correctamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cielo Obs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.nightlight_round, size: 90, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'Observador del Cielo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.light,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Registra fenómenos visibles en el cielo de forma rápida y sin conexión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.light),
            ),
            const SizedBox(height: 30),
            _buildButton(
              context,
              'Nueva observación',
              Icons.add_circle_outline,
              const AgregarObservacionScreen(),
            ),
            const SizedBox(height: 15),
            _buildButton(
              context,
              'Ver observaciones',
              Icons.list_alt,
              const ListaObservacionesScreen(),
            ),
            const SizedBox(height: 15),
            _buildButton(
              context,
              'Perfil / Acerca de',
              Icons.person,
              const PerfilScreen(),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _mostrarDialogoBorrarTodo(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Borrar Todo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }
}