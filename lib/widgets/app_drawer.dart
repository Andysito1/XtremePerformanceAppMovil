import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/veh_model.dart';
import '../theme/app_colors.dart';

class _DrawerDestination {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerDestination(this.icon, this.label, this.route);
}

const List<_DrawerDestination> _destinations = [
  _DrawerDestination(
    Icons.directions_car_rounded,
    'Seguimiento del vehículo',
    '/seguimiento',
  ),
  _DrawerDestination(
    Icons.attach_money_rounded,
    'Estado financiero',
    '/estadoFinanciero',
  ),
  _DrawerDestination(
    Icons.history_rounded,
    'Historial del vehículo',
    '/historial',
  ),
  _DrawerDestination(
    Icons.notifications_rounded,
    'Notificaciones',
    '/notificaciones',
  ),
  _DrawerDestination(Icons.settings_rounded, 'Ajustes', '/ajustes'),
];

/// Menú lateral compartido por todas las pantallas de Cliente.
/// Centraliza el diseño (antes duplicado en cada pantalla) para mantener
/// la navegación y el estilo consistentes en un solo lugar.
class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final String usuarioNombre;
  final VehiculoModel? vehiculo;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.usuarioNombre = 'Cliente',
    this.vehiculo,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = usuarioNombre.trim().isNotEmpty
        ? usuarioNombre.trim()[0].toUpperCase()
        : 'C';

    return Drawer(
      backgroundColor: AppColors.dark,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.redGradient),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xtreme Performance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usuarioNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 8),
          ..._destinations.map(
            (d) => _drawerItem(
              context,
              icon: d.icon,
              text: d.label,
              route: d.route,
              selected: d.route == currentRoute,
            ),
          ),
          const Spacer(),
          if (vehiculo != null) _vehiculoChip(vehiculo!),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String route,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.go(route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? const Border(left: BorderSide(color: AppColors.red, width: 3))
              : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white70,
              size: 21,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehiculoChip(VehiculoModel vehiculo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkElevated, AppColors.darkSoft],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: vehiculo.fullImagenUrl.isNotEmpty
                  ? Image.network(
                      vehiculo.fullImagenUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(46),
                    )
                  : _placeholder(46),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Placa: ${vehiculo.placa}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.darkElevated,
      child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
    );
  }
}
