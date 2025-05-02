class MaskConfig {
  // Coordenadas e dimensões no "espaço virtual"
  double left;
  double top;
  double width;
  double height;

  MaskConfig({
    this.left = 0,
    this.top = 0,
    this.width = 300,
    this.height = 500,
  });

  // Usado para clonar o objeto
  MaskConfig clone() {
    return MaskConfig(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
} 