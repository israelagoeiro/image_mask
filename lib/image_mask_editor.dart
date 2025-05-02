import 'package:flutter/material.dart';
import 'package:image_mask/image_mask.dart';
import 'package:image_mask/image_mask_list.dart';
import 'package:image_mask/image_mask_viewer.dart';
import 'dart:developer' as developer;

class ImageMaskEditor extends StatefulWidget {
  const ImageMaskEditor({super.key});

  @override
  State<ImageMaskEditor> createState() => _ImageMaskEditorState();
}

class _ImageMaskEditorState extends State<ImageMaskEditor> {
  final List<ImageMask> _maskItems = [
    ImageMask(
      left: 450,
      top: 224,
      width: 403,
      height: 448,
    ),
  ];

  String? _selectedMaskId;
  bool _isReordering = false; // Flag para controlar reordenação
  bool _isUpdatingSelection = false; // Flag para evitar loops de atualização

  @override
  void initState() {
    super.initState();
    if (_maskItems.isNotEmpty) {
      _selectedMaskId = _maskItems.first.id;
    }
  }

  void _updateMaskList(List<ImageMask> newMasks, String? selectedId) {
    // Se estiver no meio de uma reordenação, ignora atualizações externas
    if (_isReordering) return;

    // Registra a atualização para depuração
    developer.log('Recebendo atualização: ${newMasks.length} máscaras, selecionada: $selectedId', name: 'mask_update');

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

    // Evita loop de atualização quando apenas a seleção muda
    if (!_isUpdatingSelection && (needsUpdate || selectedId != _selectedMaskId)) {
      _isUpdatingSelection = true; // Marca que estamos atualizando para evitar loop

      setState(() {
        if (needsUpdate) {
          // Atualiza a lista de máscaras mantendo a referência aos objetos
          _maskItems.clear();
          _maskItems.addAll(newMasks);
        }

        if (selectedId != null && selectedId != _selectedMaskId) {
          _selectedMaskId = selectedId;
          developer.log('Atualizando seleção para: $selectedId', name: 'mask_update');
        }
      });

      // Reseta o flag após um curto período para permitir que a UI seja atualizada
      Future.delayed(Duration.zero, () {
        _isUpdatingSelection = false;
      });
    }
  }

  void _selectMask(String maskId) {
    if (_selectedMaskId == maskId || _isUpdatingSelection) return;

    _isUpdatingSelection = true; // Marca que estamos atualizando para evitar loop

    setState(() {
      _selectedMaskId = maskId;
    });

    // Reseta o flag após um curto período
    Future.delayed(Duration.zero, () {
      _isUpdatingSelection = false;
    });
  }

  void _reorderMasks(int oldIndex, int newIndex) {
    _isReordering = true; // Marca início da reordenação

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final ImageMask item = _maskItems.removeAt(oldIndex);
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
            initialMasks: _maskItems,
            initialSelectedMaskId: _selectedMaskId,
            onMaskListChanged: (masks, selectedId) {
              // Quando a seleção ou lista de máscaras muda na visualização principal,
              // notifica o componente pai para sincronizar com a lista lateral
              _updateMaskList(masks, selectedId);
            },
          ),
        ),

        // Painel lateral direito (ocupando 20% da largura)
        Expanded(
          flex: 1,
          child: ImageMaskList(
            maskItems: _maskItems,
            selectedMaskId: _selectedMaskId,
            onMaskSelected: (maskId) {
              // Quando um item na lista lateral é selecionado,
              // atualizamos a seleção no estado principal
              _selectMask(maskId);

              // Registra a seleção para depuração
              developer.log('Máscara selecionada da lista lateral: $maskId', name: 'mask_selection');
            },
            onReorder: _reorderMasks,
          ),
        ),
      ],
    );
  }
}