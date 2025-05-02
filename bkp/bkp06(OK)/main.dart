import 'package:flutter/material.dart';
import 'widgets/overlay_mask_widget.dart';
import 'models/mask_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MaskEditorScreen(),
      ),
    );
  }
}

class MaskEditorScreen extends StatefulWidget {
  const MaskEditorScreen({super.key});

  @override
  State<MaskEditorScreen> createState() => _MaskEditorScreenState();
}

class _MaskEditorScreenState extends State<MaskEditorScreen> {
  final List<MaskConfig> _maskItems = [
    MaskConfig(
      left: 450,
      top: 224,
      width: 403,
      height: 448,
    ),
  ];
  
  String? _selectedMaskId;
  bool _isReordering = false; // Flag para controlar reordenação
  
  @override
  void initState() {
    super.initState();
    if (_maskItems.isNotEmpty) {
      _selectedMaskId = _maskItems.first.id;
    }
  }
  
  void _updateMaskList(List<MaskConfig> newMasks, String? selectedId) {
    // Se estiver no meio de uma reordenação, ignora atualizações externas
    if (_isReordering) return;
    
    // Verificação para evitar atualizações desnecessárias
    bool needsUpdate = false;
    
    // Verifica se a quantidade de máscaras mudou
    if (newMasks.length != _maskItems.length) {
      needsUpdate = true;
    } else {
      // Verifica se algum ID mudou ou se a ordem mudou
      for (int i = 0; i < newMasks.length; i++) {
        if (i >= _maskItems.length || newMasks[i].id != _maskItems[i].id) {
          needsUpdate = true;
          break;
        }
      }
    }
    
    // Se precisar atualizar, aplica as alterações
    if (needsUpdate || selectedId != _selectedMaskId) {
      setState(() {
        // Atualiza a lista de máscaras mantendo a referência aos objetos
        _maskItems.clear();
        _maskItems.addAll(newMasks);
        _selectedMaskId = selectedId;
      });
    }
  }
  
  void _reorderMasks(int oldIndex, int newIndex) {
    _isReordering = true; // Marca início da reordenação
    
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final MaskConfig item = _maskItems.removeAt(oldIndex);
      _maskItems.insert(newIndex, item);
      
      // Seleciona o item movido
      _selectedMaskId = item.id;
    });
    
    // Usamos o Future.delayed para garantir que o flag seja resetado
    // após a conclusão da atualização da UI
    Future.delayed(Duration.zero, () {
      _isReordering = false; // Marca fim da reordenação
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Área principal de edição (ocupando 80% da largura)
        Expanded(
          flex: 4,
          child: ImageMaskViewer(
            maskItems: _maskItems,
            selectedMaskId: _selectedMaskId,
            onMaskListChanged: _updateMaskList,
          ),
        ),
        
        // Painel lateral direito (ocupando 20% da largura)
        Expanded(
          flex: 1,
          child: ImageMaskList(
            maskItems: _maskItems,
            selectedMaskId: _selectedMaskId,
            onMaskSelected: (maskId) {
              setState(() {
                _selectedMaskId = maskId;
              });
            },
            onReorder: _reorderMasks,
          ),
        ),
      ],
    );
  }
}

class ImageMaskViewer extends StatelessWidget {
  final List<MaskConfig> maskItems;
  final String? selectedMaskId;
  final Function(List<MaskConfig>, String?) onMaskListChanged;

  const ImageMaskViewer({
    super.key, 
    required this.maskItems,
    required this.selectedMaskId,
    required this.onMaskListChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OverlayMaskPosition(
      initialMasks: maskItems,
      initialSelectedMaskId: selectedMaskId,
      onMaskListChanged: onMaskListChanged,
    );
  }
}

class ImageMaskList extends StatelessWidget {
  final List<MaskConfig> maskItems;
  final String? selectedMaskId;
  final Function(String) onMaskSelected;
  final Function(int, int)? onReorder;

  const ImageMaskList({
    super.key,
    required this.maskItems,
    required this.selectedMaskId,
    required this.onMaskSelected,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    // Chave global para o ReorderableListView
    final GlobalKey listKey = GlobalKey();
    
    return Container(
      color: const Color(0xFF333333), // Fundo escuro para o painel lateral
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Lista de Máscaras',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView(
              key: listKey, // Usa uma chave global para manter a estabilidade durante reordenações
              padding: const EdgeInsets.symmetric(horizontal: 8),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                // Notifica o componente pai sobre a reordenação
                if (onReorder != null) {
                  onReorder!(oldIndex, newIndex);
                }
              },
              children: [
                for (int index = 0; index < maskItems.length; index++)
                  ReorderableDragStartListener(
                    key: ValueKey(maskItems[index].id),
                    index: index,
                    child: GestureDetector(
                      onTap: () => onMaskSelected(maskItems[index].id),
                      child: Stack(
                        clipBehavior: Clip.none, // Permite que os elementos filhos ultrapassem os limites do Stack
                        children: [
                          Container(
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: maskItems[index].id == selectedMaskId
                                  ? const Color(0xFF1E88E5).withValues(alpha: 0.3) // Azul selecionado
                                  : const Color(0xFF424242), // Cinza escuro para itens não selecionados
                              borderRadius: BorderRadius.circular(4),
                              border: maskItems[index].id == selectedMaskId
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12, top: 8, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Máscara ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: maskItems[index].id == selectedMaskId
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    '${maskItems[index].width.toInt()}x${maskItems[index].height.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Identificador numérico no canto superior direito
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
