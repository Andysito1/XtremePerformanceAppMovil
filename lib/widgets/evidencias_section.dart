import 'package:flutter/material.dart';
import '../models/evidencia_model.dart';

/// Sección "Evidencias:" reutilizada en el detalle de cada etapa. Si no hay
/// evidencias, no renderiza nada (según lo solicitado: "si no hay evidencias
/// simplemente no aparecen").
///
/// [onDelete] es opcional: cuando se provee (solo en la pantalla del
/// mecánico), se muestra un botón para borrar cada evidencia individual. En
/// la vista del cliente se omite este parámetro y no aparece ninguna opción
/// de borrado.
class EvidenciasSection extends StatelessWidget {
  final List<EvidenciaModel> evidencias;
  final Future<void> Function(EvidenciaModel evidencia)? onDelete;

  const EvidenciasSection({
    super.key,
    required this.evidencias,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (evidencias.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidencias:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: evidencias
                .map((evidencia) => _buildThumb(context, evidencia))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context, EvidenciaModel evidencia) {
    final bool esVideo = evidencia.tipo == 'video';

    return GestureDetector(
      onTap: () => _openPreview(context, evidencia),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: esVideo
                ? Container(
                    width: 90,
                    height: 90,
                    color: Colors.black87,
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  )
                : Image.network(
                    evidencia.url,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
          ),
          if (onDelete != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => _confirmarBorrado(context, evidencia),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarBorrado(
    BuildContext context,
    EvidenciaModel evidencia,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text('¿Seguro que deseas eliminar esta evidencia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && onDelete != null) {
      await onDelete!(evidencia);
    }
  }

  void _openPreview(BuildContext context, EvidenciaModel evidencia) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: evidencia.tipo == 'video'
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, size: 48),
                    const SizedBox(height: 8),
                    const Text('Video adjunto'),
                    const SizedBox(height: 4),
                    SelectableText(
                      evidencia.url,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : InteractiveViewer(
                child: Image.network(
                  evidencia.url,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 60),
                ),
              ),
      ),
    );
  }
}
