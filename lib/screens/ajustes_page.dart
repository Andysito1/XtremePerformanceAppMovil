import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/ajustes_model.dart';
import '../models/usuario_model.dart';
import '../services/ajustes_service.dart';
import '../services/usuario_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dio_client.dart';
import '../services/notifications_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final AjustesService _ajustesService = AjustesService();
  final UsuarioService _usuarioService = UsuarioService();

  AjustesModel? _ajustesOriginales;
  UsuarioModel? _usuario;
  bool _cargando = true;

  // Variables para controlar los inputs de la UI
  bool _notificacionesActivas = true;
  bool _silenciarAlertas = false; // UI-only por ahora

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    // Cargamos configuración y usuario en paralelo
    await Future.wait([
      _cargarConfiguracionServidor(),
      _cargarUsuario(),
      _cargarConfiguracionLocal(),
    ]);
    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  // Carga las configuraciones desde el servidor (Tema, Notificaciones)
  Future<void> _cargarConfiguracionServidor() async {
    try {
      final ajustes = await _ajustesService.obtenerConfiguracion();
      if (ajustes != null) {
        _ajustesOriginales = ajustes;
        _notificacionesActivas = ajustes.notificacionesActivas;
      } else {
        // Valores por defecto si no hay configuración previa
        _notificacionesActivas = true;
      }
    } catch (e) {
      print("Error cargando configuración: $e");
    }
  }

  // Carga las configuraciones locales del dispositivo (Silenciar Alertas)
  Future<void> _cargarConfiguracionLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _silenciarAlertas = prefs.getBool('silenciar_alertas') ?? false,
      );
    }
  }

  Future<void> _cargarUsuario() async {
    try {
      final usuariosJson = await _usuarioService.usuarioInfo();
      if (usuariosJson.isNotEmpty && mounted) {
        setState(() {
          _usuario = UsuarioModel.fromJson(usuariosJson.first);
        });
      }
    } catch (e) {
      print("Error al cargar el usuario: $e");
    }
  }

  Future<void> _guardarConfiguracion() async {
    final nuevosAjustes = AjustesModel(
      id: _ajustesOriginales?.id,
      idCliente: _ajustesOriginales?.idCliente,
      tema: 'claro',
      notificacionesActivas: _notificacionesActivas,
    );

    final exito = await _ajustesService.guardarConfiguracion(nuevosAjustes);

    if (mounted) {
      if (!exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar la configuración")),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      // 1. Intentamos informar al backend (con un tiempo límite)
      await NotificationService().deleteToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint("Timeout al borrar token en backend"),
      );
    } catch (e) {
      debugPrint("Error notificando cierre de sesión: $e");
    } finally {
      // 2. LIMPIEZA TOTAL obligatoria
      DioClient.dio.options.headers.remove('Authorization');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // 3. Navegar al login reseteando el stack
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Xtreme Performance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: AppDrawer(
        currentRoute: '/ajustes',
        usuarioNombre: _usuario?.nombre ?? 'Cliente',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final inicial = (_usuario?.nombre.trim().isNotEmpty ?? false)
        ? _usuario!.nombre.trim()[0].toUpperCase()
        : 'U';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // 1. Banner de perfil (hero)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.darkGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.red,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _usuario?.nombre ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _usuario?.correo ?? 'No disponible',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN NOTIFICACIONES ---
        _buildSectionTitle('NOTIFICACIONES'),
        _buildCard(
          children: [
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_none,
                color: Colors.grey,
              ),
              title: const Text('Notificaciones'),
              subtitle: Text(
                'Recibir actualizaciones del servicio',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              value: _notificacionesActivas,
              onChanged: (value) {
                setState(() => _notificacionesActivas = value);
                _guardarConfiguracion(); // Guardado automático
              },
              activeColor: const Color(0xFFE53935),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_off_outlined,
                color: Colors.grey,
              ),
              title: const Text('Silenciar alertas'),
              subtitle: Text(
                'No molestar temporalmente',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              value: _silenciarAlertas,
              onChanged: (value) async {
                setState(() => _silenciarAlertas = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('silenciar_alertas', value);
              },
              activeColor: const Color(0xFFE53935),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // 4. Botón de Acción Principal (Cerrar Sesión)
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.redGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _cerrarSesion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              "Cerrar sesión",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF757575),
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16);
  }

}
