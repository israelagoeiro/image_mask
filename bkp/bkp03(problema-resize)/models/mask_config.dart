class MaskConfig {
  // Identificador único
  final String id;
  
  // Coordenadas e dimensões no "espaço virtual"
  double left;
  double top;
  double width;
  double height;

  // Contador estático para garantir IDs únicos mesmo quando criados no mesmo milissegundo
  static int _counter = 0;

  MaskConfig({
    String? id,
    this.left = 0,
    this.top = 0,
    this.width = 300,
    this.height = 500,
  }) : id = id ?? _generateUniqueId();

  // Método para gerar ID único
  static String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = "$timestamp-${_counter++}";
    return uniqueId;
  }

  // Usado para clonar o objeto
  MaskConfig clone() {
    return MaskConfig(
      id: id,
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
} 