import 'package:flutter/material.dart';

/// Flutter code sample for [ReorderableListView].

void main() => runApp(const ReorderableApp());

class ReorderableApp extends StatelessWidget {
  const ReorderableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(appBar: AppBar(title: const Text('ReorderableListView Sample')), body: const ReorderableExample()));
  }
}

class ReorderableExample extends StatefulWidget {
  const ReorderableExample({super.key});

  @override
  State<ReorderableExample> createState() => _ReorderableListViewExampleState();
}

class _ReorderableListViewExampleState extends State<ReorderableExample> {
  final List<int> _items = List<int>.generate(50, (int index) => index);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final oddItemColor = colorScheme.primary.withOpacity(0.05);
    final evenItemColor = colorScheme.primary.withOpacity(0.15);

    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      buildDefaultDragHandles: false, // 1️⃣ remove ícone padrão
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
      children: [
        for (int index = 0; index < _items.length; index++)
          ReorderableDragStartListener(
            // 2️⃣ toda a linha vira “pegador”
            key: ValueKey(index), // cada filho precisa de key única
            index: index,
            /*child: ListTile(
              tileColor: _items[index].isOdd ? oddItemColor : evenItemColor,
              title: Text('Item ${_items[index]}'),
            ),*/
            child: Container(height: 60, color: Colors.red, margin: const EdgeInsets.only(bottom: 2), child: Text(index.toString())),
          ),
      ],
    );
  }
}
