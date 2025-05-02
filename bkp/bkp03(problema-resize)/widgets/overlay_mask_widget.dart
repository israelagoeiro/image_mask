import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../models/mask_config.dart';
import '../utils/anchor_point.dart';
import '../utils/size_manager.dart';
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

  // Lista de configurações de máscara
  late List<MaskConfig> _maskConfigs;
  
  // ID da máscara selecionada atualmente
  String? _selectedMaskId;

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

  // Aspect ratio da imagem
  static const double imageAspectRatio = imageWidth / imageHeight;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    
    // Inicializa a lista com máscaras iniciais em posições diferentes
    _maskConfigs = [
      MaskConfig(
        left: imageWidth * 0.25,
        top: imageHeight * 0.25,
        width: imageWidth * 0.25,
        height: imageHeight * 0.25,
      ),
      MaskConfig(
        left: imageWidth * 0.5,
        top: imageHeight * 0.35,
        width: imageWidth * 0.3,
        height: imageHeight * 0.5,
      ),
      MaskConfig(
        left: imageWidth * 0.75,
        top: imageHeight * 0.15,
        width: imageWidth * 0.2,
        height: imageHeight * 0.3,
      ),
    ];
    
    // Seleciona a primeira máscara por padrão
    _selectedMaskId = _maskConfigs.first.id;
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
  
  // Retorna a máscara atualmente selecionada
  MaskConfig? get _selectedMask {
    if (_selectedMaskId == null) return null;
    try {
      return _maskConfigs.firstWhere((mask) => mask.id == _selectedMaskId);
    } catch (e) {
      return null;
    }
  }
  
  // Obtém o índice da máscara selecionada (para exibição)
  int get _selectedMaskIndex {
    if (_selectedMaskId == null) return -1;
    return _maskConfigs.indexWhere((mask) => mask.id == _selectedMaskId);
  }
  
  // Mantém a proporção quando redimensiona com shift
  double get _aspectRatio {
    final selected = _selectedMask;
    if (selected == null) return 1.0;
    return selected.width / selected.height;
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

                  // Renderiza todas as máscaras, com a selecionada por último (para ficar por cima)
                  ..._renderMaskItems(scaleFactor),
                  
                  // Informação das máscaras
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Máscaras: ${_maskConfigs.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          if (_selectedMaskIndex >= 0)
                            Text(
                              'Selecionada: ${_selectedMaskIndex + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Lista de seleção rápida de máscaras
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Selecionar máscara:',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              for (int i = 0; i < _maskConfigs.length; i++)
                                GestureDetector(
                                  onTap: () => _selectMask(_maskConfigs[i].id),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedMaskIndex == i 
                                          ? Colors.blue.withOpacity(0.7)
                                          : Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: _selectedMaskIndex == i
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Botões de ação
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Dica: Clique em uma máscara para selecioná-la\n'
                          'Use Shift para manter proporção\n'
                          'Use Alt para redimensionar a partir do centro',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton(
                              heroTag: "add_mask",
                              mini: true,
                              tooltip: 'Adicionar máscara',
                              child: const Icon(Icons.add),
                              onPressed: _addNewMask,
                            ),
                            if (_selectedMaskId != null && _maskConfigs.length > 1)
                              const SizedBox(width: 8),
                            if (_selectedMaskId != null && _maskConfigs.length > 1)
                              FloatingActionButton(
                                heroTag: "remove_mask",
                                mini: true,
                                tooltip: 'Remover máscara selecionada',
                                child: const Icon(Icons.delete),
                                onPressed: _removeSelectedMask,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Renderiza todos os itens de máscara, com o selecionado por último
  List<Widget> _renderMaskItems(double scaleFactor) {
    // Ordena os itens para que o selecionado seja renderizado por último
    final sortedMasks = List<MaskConfig>.from(_maskConfigs);
    if (_selectedMaskId != null) {
      sortedMasks.sort((a, b) {
        if (a.id == _selectedMaskId) return 1;
        if (b.id == _selectedMaskId) return -1;
        return 0;
      });
    }
    
    return sortedMasks.map((mask) {
      final isSelected = mask.id == _selectedMaskId;
      
      return OverlayMaskItem(
        key: ObjectKey(mask), // Usando ObjectKey em vez de ValueKey para garantir unicidade
        maskConfig: mask,
        scaleFactor: scaleFactor,
        imageAsset: _sharedImageAsset,
        initialMousePosition: isSelected ? _initialMousePosition : null,
        currentMousePosition: isSelected ? _currentMousePosition : null,
        isDragging: isSelected && _isDragging,
        isSelected: isSelected,
        onUpdatePosition: (details, sf) => _updatePosition(details, sf, mask.id),
        onResetMousePosition: (details) => _resetMousePosition(details),
        onUpdateSize: (details, {left = false, right = false, top = false, bottom = false, required anchorPoint, required scaleFactor}) => 
            _updateSize(details, left: left, right: right, top: top, bottom: bottom, anchorPoint: anchorPoint, scaleFactor: scaleFactor, maskId: mask.id),
        buildDialogMetric: _buildDialogMetric,
        onSelect: () => _selectMask(mask.id),
      );
    }).toList();
  }
  
  // Seleciona uma máscara pelo ID
  void _selectMask(String maskId) {
    if (maskId != _selectedMaskId) {
      setState(() {
        _selectedMaskId = maskId;
        _initialMousePosition = null;
        _currentMousePosition = null;
        _isDragging = false;
      });
    }
  }
  
  // Adiciona uma nova máscara
  void _addNewMask() {
    final newMask = MaskConfig(
      left: imageWidth * 0.4, // Posição ligeiramente deslocada
      top: imageHeight * 0.3,
      width: imageWidth * 0.25,
      height: imageHeight * 0.4,
    );
    
    setState(() {
      _maskConfigs.add(newMask);
      _selectedMaskId = newMask.id; // Seleciona automaticamente
    });
  }
  
  // Remove a máscara selecionada
  void _removeSelectedMask() {
    if (_selectedMaskId == null || _maskConfigs.length <= 1) return;
    
    setState(() {
      _maskConfigs.removeWhere((mask) => mask.id == _selectedMaskId);
      _selectedMaskId = _maskConfigs.first.id; // Seleciona a primeira
      _initialMousePosition = null;
      _currentMousePosition = null;
      _isDragging = false;
    });
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

  void _updatePosition(DragUpdateDetails details, double scaleFactor, String maskId) {
    // Ignora se não for a máscara selecionada
    if (maskId != _selectedMaskId) return;
    
    final maskIndex = _maskConfigs.indexWhere((m) => m.id == maskId);
    if (maskIndex == -1) return;
    
    setState(() {
      _initialMousePosition ??= details.globalPosition;
      _currentMousePosition = details.globalPosition;

      // Convertemos o delta para o espaço de coordenadas virtuais
      final deltaX = details.delta.dx / scaleFactor;
      final deltaY = details.delta.dy / scaleFactor;

      _maskConfigs[maskIndex].left += deltaX;
      _maskConfigs[maskIndex].top += deltaY;

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
        required String maskId,
      }) {
    // Ignora se não for a máscara selecionada
    if (maskId != _selectedMaskId) return;
    
    final maskIndex = _maskConfigs.indexWhere((m) => m.id == maskId);
    if (maskIndex == -1) return;
    
    // Converte os deltas para o espaço virtual
    final deltaX = details.delta.dx / scaleFactor;
    final deltaY = details.delta.dy / scaleFactor;

    // Cria uma cópia da configuração atual para manipulação
    final newConfig = _maskConfigs[maskIndex].clone();

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
        _maskConfigs[maskIndex] = newConfig;
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
    final selected = _selectedMask;
    if (selected == null) return Container();
    
    if (_isDragging) {
      return Text(
        '↔️: ${deltaX.toStringAsFixed(0)} px\n↕️: ${deltaY.toStringAsFixed(0)} px',
        style: const TextStyle(color: Colors.white, fontSize: 9.5, height: 1.2),
      );
    } else {
      return Text(
        'W : ${selected.width.toStringAsFixed(0)} px\n H : ${selected.height.toStringAsFixed(0)} px',
        style: const TextStyle(color: Colors.white, fontSize: 9.5, height: 1.2),
      );
    }
  }
} 