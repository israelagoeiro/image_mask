import 'package:flutter/material.dart';
import 'package:image_mask/image_mask.dart';

class ImageMaskList extends StatelessWidget {
  final List<ImageMask> maskItems;
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
                      onTap: ()=>onMaskSelected(maskItems[index].id),
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