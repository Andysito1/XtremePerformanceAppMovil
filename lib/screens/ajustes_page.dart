import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/ajustes_model.dart';
import '../models/usuario_model.dart';
import '../services/ajustes_service.dart';
import '../services/usuario_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dio_client.dart';

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
  bool _isLightTheme = true;

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
        _isLightTheme = ajustes.tema.toLowerCase() == 'claro';
      } else {
        // Valores por defecto si no hay configuración previa
        _notificacionesActivas = true;
        _isLightTheme = true;
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
      tema: _isLightTheme ? 'claro' : 'oscuro',
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

  void _showChangePasswordModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: const Text(
          "Esta funcionalidad aún no está disponible.\n\nContacta con el taller para solicitar un cambio de contraseña.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    // Eliminar el token de la instancia global de Dio para limpiar la sesión en memoria
    DioClient.dio.options.headers.remove('Authorization');

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4A8F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Xtreme Performance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined, color: Colors.white),
            onPressed: () {}, // Visual only
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // 1. Cabecera
        const Text(
          'Ajustes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Configuración de la aplicación',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),

        // --- SECCIÓN CUENTA ---
        _buildSectionTitle('CUENTA'),
        _buildCard(
          children: [
            // 3. Perfil de Usuario
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _usuario?.nombre ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildDivider(),
            // Correo (Visualización)
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.grey),
              title: const Text('Correo electrónico'),
              subtitle: Text(
                _usuario?.correo ?? 'No disponible',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            _buildDivider(),
            // Cambiar contraseña
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.grey),
              title: const Text('Cambiar contraseña'),
              subtitle: Text(
                'Actualiza tu clave de acceso',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24,
              ),
              onTap: _showChangePasswordModal,
            ),
          ],
        ),
        const SizedBox(height: 20),

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
        const SizedBox(height: 20),

        // --- SECCIÓN APARIENCIA ---
        _buildSectionTitle('APARIENCIA'),
        _buildCard(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.palette_outlined, color: Colors.grey),
              title: const Text('Modo claro'),
              subtitle: Text(
                'Alternar entre tema claro y oscuro',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              value: _isLightTheme,
              onChanged: (value) {
                setState(() => _isLightTheme = value);
                _guardarConfiguracion(); // Guardado automático
              },
              activeColor: const Color(0xFFE53935),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // 4. Botón de Acción Principal (Cerrar Sesión)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _cerrarSesion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
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

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1F3C88),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFE53935),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xtreme Performance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _usuario?.nombre ?? "Cliente",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.directions_car,
              text: "Seguimiento del vehículo",
              route: "/seguimiento",
            ),
            _drawerItem(
              context,
              icon: Icons.attach_money,
              text: "Estado financiero",
              route: "/estadoFinanciero",
            ),
            _drawerItem(
              context,
              icon: Icons.history,
              text: "Historial del vehículo",
              route: "/historial",
            ),
            _drawerItem(
              context,
              icon: Icons.notifications,
              text: "Notificaciones",
              route: "/notificaciones",
            ),
            _drawerItem(
              context,
              icon: Icons.settings,
              text: "Ajustes",
              route: "/ajustes",
              selected: true,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Versión 1.0.0",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// drawer item helper
Widget _drawerItem(
  BuildContext context, {
  required IconData icon,
  required String text,
  required String route,
  bool selected = false,
}) {
  return InkWell(
    onTap: () {
      Navigator.pop(context);
      // Solo navega si no está en la ruta actual
      if (!selected) {
        context.go(route);
      }
    },
    child: Container(
      color: selected ? const Color(0xFF2C5BEA) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    ),
  );
}
