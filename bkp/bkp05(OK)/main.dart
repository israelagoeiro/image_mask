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
  
  @override
  void initState() {
    super.initState();
    if (_maskItems.isNotEmpty) {
      _selectedMaskId = _maskItems.first.id;
    }
  }
  
  void _updateMaskList(List<MaskConfig> newMasks, String? selectedId) {
    setState(() {
      _maskItems.clear();
      _maskItems.addAll(newMasks);
      _selectedMaskId = selectedId;
    });
  }
  
  void _reorderMasks(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final MaskConfig item = _maskItems.removeAt(oldIndex);
      _maskItems.insert(newIndex, item);
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
          child: Container(
            color: Colors.grey[850],
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
    final colorScheme = Theme.of(context).colorScheme;
    final oddItemColor = colorScheme.primary.withValues(alpha: 0.05);
    final evenItemColor = colorScheme.primary.withValues(alpha: 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Lista de Máscaras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              // Notifica o componente pai sobre a reordenação
              if (onReorder != null) {
                onReorder!(oldIndex, newIndex);
              }
              
              // Seleciona o item que foi movido
              final movedItem = maskItems[oldIndex < newIndex ? newIndex - 1 : newIndex];
              onMaskSelected(movedItem.id);
            },
            children: [
              for (int index = 0; index < maskItems.length; index++)
                ReorderableDragStartListener(
                  key: ValueKey(maskItems[index].id),
                  index: index,
                  child: GestureDetector(
                    onTap: () => onMaskSelected(maskItems[index].id),
                    child: Container(
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: maskItems[index].id == selectedMaskId
                            ? Colors.blue.withValues(alpha: 0.3)
                            : index.isOdd
                                ? oddItemColor
                                : evenItemColor,
                        borderRadius: BorderRadius.circular(4),
                        border: maskItems[index].id == selectedMaskId
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
