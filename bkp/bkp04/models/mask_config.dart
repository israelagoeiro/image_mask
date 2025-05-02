class MaskConfig {
  // Identificador único
  final String id;
  
  // Coordenadas e dimensões no "espaço virtual"
  double left;
  double top;
  double width;
  double height;

  MaskConfig({
    String? id,
    this.left = 0,
    this.top = 0,
    this.width = 300,
    this.height = 500,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
  
  @override
  String toString() {
    return 'MaskConfig(id: $id, left: ${left.toStringAsFixed(1)}, top: ${top.toStringAsFixed(1)}, '
           'width: ${width.toStringAsFixed(1)}, height: ${height.toStringAsFixed(1)})';
  }
} 