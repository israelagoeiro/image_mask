import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:developer' as developer;

import 'image_mask.dart';
import 'utils/anchor_point.dart';
import 'utils/size_manager.dart';
import 'image_mask_clipper.dart';
import 'image_mask_painter.dart';
import 'image_mask_item.dart';

class ImageMaskViewer extends StatefulWidget {
  final List<ImageMask>? initialMasks;
  final String? initialSelectedMaskId;
  final Function(List<ImageMask>, String?)? onMaskListChanged;

  const ImageMaskViewer({
    super.key, 
    this.initialMasks,
    this.initialSelectedMaskId,
    this.onMaskListChanged,
  });

  @override
  State<ImageMaskViewer> createState() => _ImageMaskViewer();
}

class _ImageMaskViewer extends State<ImageMaskViewer> {
  // Dimensões padrão da imagem (1344x896)
  static const double imageWidth = 1344.0;
  static const double imageHeight = 896.0;

  // Lista de configurações de máscara
  late List<ImageMask> _maskConfigs;
  
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
    
    // Inicializa a lista com máscaras fornecidas ou uma máscara padrão
    if (widget.initialMasks != null && widget.initialMasks!.isNotEmpty) {
      _maskConfigs = List<ImageMask>.from(widget.initialMasks!);
    } else {
      _maskConfigs = [
        ImageMask(
          left: imageWidth * 0.35, // 35% da largura
          top: imageHeight * 0.25,  // 25% da altura
          width: imageWidth * 0.3,  // 30% da largura
          height: imageHeight * 0.5, // 50% da altura
        ),
      ];
    }
    
    // Seleciona a máscara inicial especificada ou a primeira da lista
    if (widget.initialSelectedMaskId != null) {
      _selectedMaskId = widget.initialSelectedMaskId;
    } else {
      _selectedMaskId = _maskConfigs.isNotEmpty ? _maskConfigs.first.id : null;
    }
  }

  @override
  void didUpdateWidget(ImageMaskViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Atualiza o estado em um único setState para evitar renderizações múltiplas
    if ((widget.initialMasks != null && widget.initialMasks!.isNotEmpty) ||
        widget.initialSelectedMaskId != null) {
      
      setState(() {
        // Atualiza a lista de máscaras se necessário
        if (widget.initialMasks != null && widget.initialMasks!.isNotEmpty) {
          _maskConfigs = List<ImageMask>.from(widget.initialMasks!);
        }
        
        // Atualiza a máscara selecionada se necessário
        if (widget.initialSelectedMaskId != null) {
          _selectedMaskId = widget.initialSelectedMaskId;
        }
      });
    }
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
  
  // Notifica o componente pai sobre mudanças na lista de máscaras
  void _notifyMaskListChanged() {
    if (widget.onMaskListChanged != null) {
      widget.onMaskListChanged!(_maskConfigs, _selectedMaskId);
    }
  }
  
  // Retorna a máscara atualmente selecionada
  ImageMask? get _selectedMask {
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
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Stack(
                    children: [
                      // Background image escurecida
                      GestureDetector(
                        onTap: () {
                          // Limpa a seleção ao clicar fora
                          setState(() {
                            _selectedMaskId = null;
                            _initialMousePosition = null;
                            _currentMousePosition = null;
                            _isDragging = false;
                          });
                        },
                        child: Image(
                          key: _imageKey,
                          image: _sharedImageAsset,
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.fill,
                          color: Colors.black.withValues(alpha: 0.6),
                          colorBlendMode: BlendMode.multiply,
                        ),
                      ),

                      // Renderiza todas as máscaras, com a selecionada por último (para ficar por cima)
                      ..._renderMaskItems(1.0), // Usamos escala 1.0 pois o FittedBox cuida do redimensionamento
                      
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
                      
                      // Botões de ação
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Dica: Clique em uma máscara para selecioná-la\n'
                              'Use Shift para manter proporção\n'
                              'Use Alt para redimensionar a partir do centro',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
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
                                  onPressed: _addNewMask,
                                  child: const Icon(Icons.add),
                                ),
                                if (_selectedMaskId != null && _maskConfigs.length > 1)
                                  const SizedBox(width: 8),
                                if (_selectedMaskId != null && _maskConfigs.length > 1)
                                  FloatingActionButton(
                                    heroTag: "remove_mask",
                                    mini: true,
                                    tooltip: 'Remover máscara selecionada',
                                    onPressed: _removeSelectedMask,
                                    child: const Icon(Icons.delete),
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
            ),
          ),
        );
      },
    );
  }
  
  // Renderiza todos os itens de máscara, com o selecionado por último
  List<Widget> _renderMaskItems(double scaleFactor) {
    // Duplica a lista para não afetar a original
    final List<ImageMask> renderMasks = List<ImageMask>.from(_maskConfigs);
    
    // Ordena os itens para que o selecionado seja renderizado por último (fique por cima)
    if (_selectedMaskId != null) {
      renderMasks.sort((a, b) {
        if (a.id == _selectedMaskId) return 1;
        if (b.id == _selectedMaskId) return -1;
        return 0;
      });
    }
    
    // Cria um mapa para armazenar o índice original de cada máscara
    final Map<String, int> originalIndexMap = {};
    for (int i = 0; i < _maskConfigs.length; i++) {
      originalIndexMap[_maskConfigs[i].id] = i;
    }
    
    return renderMasks.map((mask) {
      final isSelected = mask.id == _selectedMaskId;
      final originalIndex = originalIndexMap[mask.id]!; // Usa o ! para garantir que o índice existe
      
      return ImageMaskItem(
        key: ValueKey("mask_${mask.id}"), // Adiciona uma key para ajudar Flutter a identificar o widget
        maskConfig: mask,
        scaleFactor: scaleFactor,
        imageAsset: _sharedImageAsset,
        initialMousePosition: isSelected ? _initialMousePosition : null,
        currentMousePosition: isSelected ? _currentMousePosition : null,
        isDragging: isSelected && _isDragging,
        isSelected: isSelected,
        index: originalIndex, // Passamos o índice original da máscara
        onUpdatePosition: (details, sf) => _updatePosition(details, sf, mask.id),
        onResetMousePosition: (details) => _resetMousePosition(details),
        onUpdateSize: (details, {left = false, right = false, top = false, bottom = false, required anchorPoint, required scaleFactor}) =>
            _updateSize(details, left: left, right: right, top: top, bottom: bottom, anchorPoint: anchorPoint, scaleFactor: scaleFactor, maskId: mask.id),
        buildDialogMetric: _buildDialogMetric,
        onSelectX: (maskConfig) => _selectMask(maskConfig.id),
      );
    }).toList();
  }
  
  // Seleciona uma máscara pelo ID
  void _selectMask(String maskId) {
    print("_selectMask Tentando selecionar máscara: $maskId"); // Print para depuração
    
    if (_selectedMaskId == maskId) return; // Evita atualizações desnecessárias
    
    setState(() {
      _selectedMaskId = maskId;
      _initialMousePosition = null;
      _currentMousePosition = null;
      _isDragging = false;
    });
    
    // Registra a seleção para depuração
    developer.log('Máscara selecionada na visualização principal: $maskId', name: 'mask_selection');
    
    // Notifica o componente pai sobre a mudança na seleção da máscara
    // para que a lista lateral também seja atualizada
    _notifyMaskListChanged();
  }
  
  // Adiciona uma nova máscara
  void _addNewMask() {
    final newMask = ImageMask(
      left: imageWidth * 0.4, // Posição ligeiramente deslocada
      top: imageHeight * 0.3,
      width: imageWidth * 0.25,
      height: imageHeight * 0.4,
    );
    
    setState(() {
      _maskConfigs.add(newMask);
      _selectedMaskId = newMask.id; // Seleciona automaticamente
    });
    
    _notifyMaskListChanged();
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
    
    _notifyMaskListChanged();
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
    
    _notifyMaskListChanged();
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

    // Log para debug
    developer.log(
      'Resize: delta=($deltaX, $deltaY), left=$left, right=$right, top=$top, bottom=$bottom, '
      'anchor=$anchorPoint, mask=${_maskConfigs[maskIndex]}',
      name: 'resize_debug'
    );

    setState(() {
      _initialMousePosition ??= details.globalPosition;
      _currentMousePosition = details.globalPosition;
      
      // Registramos o estado antes da mudança
      final maskBefore = _maskConfigs[maskIndex].clone();
      
      // Aplicamos as alterações diretamente no objeto
      if (_isAltPressed && _isShiftPressed) {
        // Centro com proporção
        SizeManager.updateSizeCenterProportional(_maskConfigs[maskIndex], deltaX, deltaY, left, right, top, bottom, _aspectRatio);
      } else if (_isAltPressed) {
        // Centro sem proporção
        SizeManager.updateSizeCenterDistortion(_maskConfigs[maskIndex], deltaX, deltaY, left, right, top, bottom);
      } else if (_isShiftPressed) {
        // Com proporção a partir do ponto de âncora
        SizeManager.updateSizeProportional(_maskConfigs[maskIndex], deltaX, deltaY, anchorPoint, _aspectRatio);
      } else {
        // Sem manter proporção
        SizeManager.updateSizeDistortion(_maskConfigs[maskIndex], deltaX, deltaY, left, right, top, bottom);
      }
      
      // Log para ver as alterações
      developer.log(
        'Result: Before=$maskBefore, After=${_maskConfigs[maskIndex]}',
        name: 'resize_debug'
      );
    });
    
    _notifyMaskListChanged();
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