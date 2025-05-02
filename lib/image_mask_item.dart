import 'package:flutter/material.dart';
import 'image_mask.dart';
import 'utils/anchor_point.dart';
import 'image_mask_clipper.dart';
import 'image_mask_painter.dart';

class ImageMaskItem extends StatelessWidget {
  final ImageMask maskConfig;
  final double scaleFactor;
  final AssetImage imageAsset;
  final Offset? initialMousePosition;
  final Offset? currentMousePosition;
  final bool isDragging;
  final bool isSelected;
  final int? index;
  final Function(DragUpdateDetails, double) onUpdatePosition;
  final Function(DragEndDetails) onResetMousePosition;
  final Function(
    DragUpdateDetails, {
    bool left,
    bool right,
    bool top,
    bool bottom,
    required AnchorPoint anchorPoint,
    required double scaleFactor,
  })
  onUpdateSize;
  final Widget Function(double deltaX, double deltaY) buildDialogMetric;
  final ValueChanged<ImageMask> onSelectX;

  const ImageMaskItem({
    Key? key,
    required this.maskConfig,
    required this.scaleFactor,
    required this.imageAsset,
    this.initialMousePosition,
    this.currentMousePosition,
    required this.isDragging,
    required this.isSelected,
    this.index,
    required this.onUpdatePosition,
    required this.onResetMousePosition,
    required this.onUpdateSize,
    required this.buildDialogMetric,
    required this.onSelectX,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cálculo dos deltas para o tooltip
    double deltaX = 0;
    double deltaY = 0;
    if (initialMousePosition != null && currentMousePosition != null) {
      deltaX = (currentMousePosition!.dx - initialMousePosition!.dx) / scaleFactor;
      deltaY = (currentMousePosition!.dy - initialMousePosition!.dy) / scaleFactor;
    }

    // Envolve todo o Stack em um GestureDetector para garantir o evento de clique
    return Stack(
      children: [
        // Área de máscara que mostra a imagem original
        ClipPath(
          clipper: ImageMaskClipper(
            left: maskConfig.left * scaleFactor,
            top: maskConfig.top * scaleFactor,
            width: maskConfig.width * scaleFactor,
            height: maskConfig.height * scaleFactor,
          ),
          child: Image(image: imageAsset, fit: BoxFit.contain),
        ),

        // Identificador numérico
        if (index != null)
          Positioned(
            left: (maskConfig.left + maskConfig.width) * scaleFactor - 26 * scaleFactor,
            top: maskConfig.top * scaleFactor,
            child: Container(
              width: 26 * scaleFactor,
              height: 26 * scaleFactor,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8 * scaleFactor))),
              child: Center(
                child: Text(
                  '${index! + 1}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor),
                ),
              ),
            ),
          ),

        // Retângulo e handles de controle (adiciona detector de gestos também aqui)
        CustomPaint(
          painter: ImageMaskPainter(
            left: maskConfig.left * scaleFactor,
            top: maskConfig.top * scaleFactor,
            width: maskConfig.width * scaleFactor,
            height: maskConfig.height * scaleFactor,
            handleSize: 8 * scaleFactor,
            isSelected: isSelected,
          ),
          child: SizedBox.shrink(),
        ),

        // Área de arraste - sempre presente para permitir a seleção
        Positioned(
          left: maskConfig.left * scaleFactor,
          top: maskConfig.top * scaleFactor,
          child: GestureDetector(
            onTap: !isSelected ? () {
              // Chama a função de seleção quando o usuário clica na máscara
              onSelectX(maskConfig);
            }: null,
            // Garante que o gesto seja detectado mesmo em áreas transparentes
            onPanUpdate: isSelected ? (details) => onUpdatePosition(details, scaleFactor) : null,
            // Só permite mover se estiver selecionado
            onPanEnd: isSelected ? onResetMousePosition : null,
            child: Container(width: maskConfig.width * scaleFactor, height: maskConfig.height * scaleFactor, color: Colors.transparent),
          ),
        ),

        // Handles de redimensionamento - só visíveis quando selecionado
        if (isSelected) ..._buildResizeHandles(),

        // Indicador de tamanho ou delta de arraste - só visível quando selecionado e arrastando
        if (isSelected && currentMousePosition != null)
          Positioned(
            //left: currentMousePosition!.dx + 20,
            //top: currentMousePosition!.dy - 40,
            left: maskConfig.left * scaleFactor + maskConfig.width + 10 * scaleFactor,
            top: maskConfig.top * scaleFactor + 10 * scaleFactor,
            child: Container(
              decoration: BoxDecoration(color: Colors.black54.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: buildDialogMetric(deltaX, deltaY),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildResizeHandles() {
    // Tamanho do handle de redimensionamento
    final handleSize = 9.0 * scaleFactor;
    final halfHandleSize = handleSize / 2;

    // Posições escaladas
    final left = maskConfig.left * scaleFactor;
    final top = maskConfig.top * scaleFactor;
    final width = maskConfig.width * scaleFactor;
    final height = maskConfig.height * scaleFactor;

    return [
      // Canto superior esquerdo
      _buildHandle(
        left - halfHandleSize,
        top - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, left: true, top: true, anchorPoint: AnchorPoint.leftTop, scaleFactor: scaleFactor),
      ),

      // Canto superior direito
      _buildHandle(
        left + width - halfHandleSize,
        top - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, right: true, top: true, anchorPoint: AnchorPoint.rightTop, scaleFactor: scaleFactor),
      ),

      // Canto inferior esquerdo
      _buildHandle(
        left - halfHandleSize,
        top + height - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, left: true, bottom: true, anchorPoint: AnchorPoint.leftBottom, scaleFactor: scaleFactor),
      ),

      // Canto inferior direito
      _buildHandle(
        left + width - halfHandleSize,
        top + height - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, right: true, bottom: true, anchorPoint: AnchorPoint.rightBottom, scaleFactor: scaleFactor),
      ),

      // Centro superior
      _buildHandle(
        left + (width / 2) - halfHandleSize,
        top - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, top: true, anchorPoint: AnchorPoint.centerTop, scaleFactor: scaleFactor),
      ),

      // Centro inferior
      _buildHandle(
        left + (width / 2) - halfHandleSize,
        top + height - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, bottom: true, anchorPoint: AnchorPoint.centerBottom, scaleFactor: scaleFactor),
      ),

      // Esquerda centro
      _buildHandle(
        left - halfHandleSize,
        top + (height / 2) - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, left: true, anchorPoint: AnchorPoint.leftCenter, scaleFactor: scaleFactor),
      ),

      // Direita centro
      _buildHandle(
        left + width - halfHandleSize,
        top + (height / 2) - halfHandleSize,
        handleSize,
        (details) => onUpdateSize(details, right: true, anchorPoint: AnchorPoint.rightCenter, scaleFactor: scaleFactor),
      ),
    ];
  }

  Widget _buildHandle(double left, double top, double size, void Function(DragUpdateDetails) onPanUpdate) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        onPanEnd: onResetMousePosition,
        child: Container(width: size, height: size, color: Colors.transparent),
      ),
    );
  }
}
