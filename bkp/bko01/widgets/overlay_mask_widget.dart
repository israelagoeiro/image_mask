import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../models/mask_config.dart';
import '../utils/anchor_point.dart';
import '../utils/size_manager.dart';
import 'mask_clipper.dart';
import 'mask_painter.dart';
import 'overlay_mask_item.dart';

class OverlayMaskPosition extends StatefulWidget {
  const OverlayMaskPosition({super.key});

  @override
  State<OverlayMaskPosition> createState() => _OverlayMaskPosition();
}

class _OverlayMaskPosition extends State<OverlayMaskPosition> {
  // Dimensões padrão da imagem (1344x896)
  static const double imageWidth = 1344.0;
  static const double imageHeight = 896.0;

  // Configuração da máscara (em coordenadas virtuais)
  final MaskConfig _maskConfig = MaskConfig(
    left: imageWidth * 0.35, // 35% da largura
    top: imageHeight * 0.25,  // 25% da altura
    width: imageWidth * 0.3,  // 30% da largura
    height: imageHeight * 0.5, // 50% da altura
  );

  // Estado da interação
  Offset? _initialMousePosition;
  Offset? _currentMousePosition;
  bool _isDragging = false;
  bool _isShiftPressed = false;
  bool _isAltPressed = false;

  // Referência da imagem compartilhada
  final AssetImage _sharedImageAsset = const AssetImage('assets/images/pg01.png');
  final GlobalKey _imageKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  // Mantém a proporção quando redimensiona com shift
  double get _aspectRatio => _maskConfig.width / _maskConfig.height;

  // Aspect ratio da imagem
  static const double imageAspectRatio = imageWidth / imageHeight;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_sharedImageAsset, context);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular o tamanho do container com base no espaço disponível,
        // mantendo a proporção original da imagem
        double containerWidth;
        double containerHeight;

        // Se a largura disponível for o fator limitante
        if (constraints.maxWidth / constraints.maxHeight < imageAspectRatio) {
          containerWidth = constraints.maxWidth;
          containerHeight = containerWidth / imageAspectRatio;
        } else {
          // Se a altura disponível for o fator limitante
          containerHeight = constraints.maxHeight;
          containerWidth = containerHeight * imageAspectRatio;
        }

        // Calculamos o fator de escala com base no tamanho do container
        final scaleFactor = containerWidth / imageWidth;

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Center(
            child: SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image escurecida
                  Image(
                    key: _imageKey,
                    image: _sharedImageAsset,
                    fit: BoxFit.contain,
                    color: Colors.black.withValues(alpha: 0.8),
                    colorBlendMode: BlendMode.multiply,
                  ),

                  // Overlay mask item que contém todos os elementos da máscara
                  OverlayMaskItem(
                    maskConfig: _maskConfig,
                    scaleFactor: scaleFactor,
                    imageAsset: _sharedImageAsset,
                    initialMousePosition: _initialMousePosition,
                    currentMousePosition: _currentMousePosition,
                    isDragging: _isDragging,
                    onUpdatePosition: _updatePosition,
                    onResetMousePosition: _resetMousePosition,
                    onUpdateSize: _updateSize,
                    buildDialogMetric: _buildDialogMetric,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        setState(() => _isAltPressed = true);
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        setState(() => _isShiftPressed = true);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        setState(() => _isAltPressed = false);
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        setState(() => _isShiftPressed = false);
      }
    }
  }

  void _updatePosition(DragUpdateDetails details, double scaleFactor) {
    setState(() {
      _initialMousePosition ??= details.globalPosition;
      _currentMousePosition = details.globalPosition;

      // Convertemos o delta para o espaço de coordenadas virtuais
      final deltaX = details.delta.dx / scaleFactor;
      final deltaY = details.delta.dy / scaleFactor;

      _maskConfig.left += deltaX;
      _maskConfig.top += deltaY;

      _isDragging = true;
    });
  }

  void _updateSize(
      DragUpdateDetails details, {
        bool left = false,
        bool right = false,
        bool top = false,
        bool bottom = false,
        required AnchorPoint anchorPoint,
        required double scaleFactor,
      }) {
    // Converte os deltas para o espaço virtual
    final deltaX = details.delta.dx / scaleFactor;
    final deltaY = details.delta.dy / scaleFactor;

    // Cria uma cópia da configuração atual para manipulação
    final newConfig = _maskConfig.clone();

    setState(() {
      _initialMousePosition ??= details.globalPosition;
      _currentMousePosition = details.globalPosition;

      if (_isAltPressed && _isShiftPressed) {
        SizeManager.updateSizeCenterProportional(newConfig, deltaX, deltaY, left, right, top, bottom, _aspectRatio);
      } else if (_isAltPressed) {
        SizeManager.updateSizeCenterDistortion(newConfig, deltaX, deltaY, left, right, top, bottom);
      } else if (_isShiftPressed) {
        SizeManager.updateSizeProportional(newConfig, deltaX, deltaY, anchorPoint, _aspectRatio);
      } else {
        SizeManager.updateSizeDistortion(newConfig, deltaX, deltaY, left, right, top, bottom);
      }

      // Aplica as alterações se todas as dimensões forem positivas
      if (newConfig.width > 0 && newConfig.height > 0) {
        _maskConfig.left = newConfig.left;
        _maskConfig.top = newConfig.top;
        _maskConfig.width = newConfig.width;
        _maskConfig.height = newConfig.height;
      }
    });
  }

  void _resetMousePosition(DragEndDetails details) {
    setState(() {
      _initialMousePosition = null;
      _currentMousePosition = null;
      _isDragging = false;
    });
  }

  Widget _buildDialogMetric(double deltaX, double deltaY) {
    if (_isDragging) {
      return Text(
        '↔️: ${deltaX.toStringAsFixed(0)} px\n↕️: ${deltaY.toStringAsFixed(0)} px',
        style: const TextStyle(color: Colors.white, fontSize: 9.5, height: 1.2),
      );
    } else {
      return Text(
        'W : ${_maskConfig.width.toStringAsFixed(0)} px\n H : ${_maskConfig.height.toStringAsFixed(0)} px',
        style: const TextStyle(color: Colors.white, fontSize: 9.5, height: 1.2),
      );
    }
  }
} 