import 'dart:math';
import 'dart:developer' as developer;
import '../models/mask_config.dart';
import '../utils/anchor_point.dart';

class SizeManager {
  // Atualiza o tamanho sem preservar proporção
  static void updateSizeDistortion(
      MaskConfig config,
      double deltaX,
      double deltaY,
      bool left,
      bool right,
      bool top,
      bool bottom
      ) {
    // Registre os valores iniciais para debug
    final initialConfig = config.clone();
    
    // Dimensões mínimas
    const double minWidth = 10.0;
    const double minHeight = 10.0;
    
    try {
      if (right) {
        // Redimensionamento pelo lado direito
        double newWidth = config.width + deltaX;
        if (newWidth >= minWidth) {
          config.width = newWidth;
        }
      }
      
      if (left) {
        // Redimensionamento pelo lado esquerdo
        double newWidth = config.width - deltaX;
        if (newWidth >= minWidth) {
          config.left += deltaX;
          config.width = newWidth;
        }
      }
      
      if (bottom) {
        // Redimensionamento pelo lado inferior
        double newHeight = config.height + deltaY;
        if (newHeight >= minHeight) {
          config.height = newHeight;
        }
      }
      
      if (top) {
        // Redimensionamento pelo lado superior
        double newHeight = config.height - deltaY;
        if (newHeight >= minHeight) {
          config.top += deltaY;
          config.height = newHeight;
        }
      }
      
      // Log do resultado
      developer.log(
        'SizeDistortion: deltaX=$deltaX, deltaY=$deltaY, left=$left, right=$right, top=$top, bottom=$bottom\n'
        'Before: $initialConfig\nAfter: $config',
        name: 'size_manager'
      );
    } catch (e) {
      developer.log('Error in updateSizeDistortion: $e', name: 'size_manager', error: e);
    }
  }

  // Atualiza o tamanho a partir do centro sem preservar proporção
  static void updateSizeCenterDistortion(
      MaskConfig config,
      double deltaX,
      double deltaY,
      bool left,
      bool right,
      bool top,
      bool bottom
      ) {
    // Dimensões mínimas
    const double minWidth = 10.0;
    const double minHeight = 10.0;
    
    try {
      if ((top && left) || (top && !left && !right) || (top && right)) {
        double newHeight = config.height - 2 * deltaY;
        if (newHeight >= minHeight) {
          config.top += deltaY;
          config.height = newHeight;
        }
      }
      
      if ((bottom && left) || (bottom && !left && !right) || (bottom && right)) {
        double newHeight = config.height + 2 * deltaY;
        if (newHeight >= minHeight) {
          config.height = newHeight;
          config.top -= deltaY;
        }
      }
      
      if ((left && top) || (left && !top && !bottom) || (left && bottom)) {
        double newWidth = config.width - 2 * deltaX;
        if (newWidth >= minWidth) {
          config.left += deltaX;
          config.width = newWidth;
        }
      }
      
      if ((right && top) || (right && !top && !bottom) || (right && bottom)) {
        double newWidth = config.width + 2 * deltaX;
        if (newWidth >= minWidth) {
          config.width = newWidth;
          config.left -= deltaX;
        }
      }
    } catch (e) {
      developer.log('Error in updateSizeCenterDistortion: $e', name: 'size_manager', error: e);
    }
  }

  // Atualiza o tamanho preservando proporção
  static void updateSizeProportional(
      MaskConfig config,
      double deltaX,
      double deltaY,
      AnchorPoint anchorPoint,
      double aspectRatio
      ) {
    switch (anchorPoint) {
      case AnchorPoint.leftTop:
        if (deltaX.abs() > deltaY.abs()) {
          double newWidth = config.width - deltaX;
          double newHeight = newWidth / aspectRatio;
          if (newWidth > 0 && newHeight > 0) {
            config.left += deltaX;
            config.top += config.height - newHeight;
            config.width = newWidth;
            config.height = newHeight;
          }
        } else {
          double newHeight = config.height - deltaY;
          double newWidth = newHeight * aspectRatio;
          if (newWidth > 0 && newHeight > 0) {
            config.left += config.width - newWidth;
            config.top += deltaY;
            config.width = newWidth;
            config.height = newHeight;
          }
        }
        break;
      case AnchorPoint.leftCenter:
        double newWidth = config.width - deltaX;
        double newHeight = newWidth / aspectRatio;
        if (newWidth > 0) {
          config.left += deltaX;
          config.top += (config.height - newHeight) / 2;
          config.width = newWidth;
          config.height = newHeight;
        }
        break;
      case AnchorPoint.leftBottom:
        if (deltaX.abs() > deltaY.abs()) {
          double newWidth = config.width - deltaX;
          double newHeight = newWidth / aspectRatio;
          if (newWidth > 0) {
            config.left += deltaX;
            config.width = newWidth;
            config.height = newHeight;
          }
        } else {
          double newHeight = config.height + deltaY;
          double newWidth = newHeight * aspectRatio;
          if (newWidth > 0) {
            config.left += config.width - newWidth;
            config.width = newWidth;
            config.height = newHeight;
          }
        }
        break;
      case AnchorPoint.centerTop:
        double newHeight = config.height - deltaY;
        double newWidth = newHeight * aspectRatio;
        if (newHeight > 0) {
          config.top += deltaY;
          config.left += (config.width - newWidth) / 2;
          config.width = newWidth;
          config.height = newHeight;
        }
        break;
      case AnchorPoint.centerBottom:
        double newHeight = config.height + deltaY;
        double newWidth = newHeight * aspectRatio;
        if (newHeight > 0) {
          config.left += (config.width - newWidth) / 2;
          config.width = newWidth;
          config.height = newHeight;
        }
        break;
      case AnchorPoint.rightTop:
        if (deltaX.abs() > deltaY.abs()) {
          double newWidth = config.width + deltaX;
          double newHeight = newWidth / aspectRatio;
          if (newWidth > 0 && newHeight > 0) {
            config.top += config.height - newHeight;
            config.width = newWidth;
            config.height = newHeight;
          }
        } else {
          double newHeight = config.height - deltaY;
          double newWidth = newHeight * aspectRatio;
          if (newHeight > 0 && newWidth > 0) {
            config.top += deltaY;
            config.width = newWidth;
            config.height = newHeight;
          }
        }
        break;
      case AnchorPoint.rightCenter:
        double newWidth = config.width + deltaX;
        double newHeight = newWidth / aspectRatio;
        if (newWidth > 0) {
          config.top += (config.height - newHeight) / 2;
          config.width = newWidth;
          config.height = newHeight;
        }
        break;
      case AnchorPoint.rightBottom:
        if (deltaX.abs() > deltaY.abs()) {
          double newWidth = config.width + deltaX;
          double newHeight = newWidth / aspectRatio;
          if (newWidth > 0) {
            config.width = newWidth;
            config.height = newHeight;
          }
        } else {
          double newHeight = config.height + deltaY;
          double newWidth = newHeight * aspectRatio;
          if (newHeight > 0) {
            config.width = newWidth;
            config.height = newHeight;
          }
        }
        break;
      case AnchorPoint.centerCenter:
      // Não implementado
        break;
    }
  }

  // Atualiza o tamanho a partir do centro preservando proporção
  static void updateSizeCenterProportional(
      MaskConfig config,
      double deltaX,
      double deltaY,
      bool left,
      bool right,
      bool top,
      bool bottom,
      double aspectRatio
      ) {
    // Determina o delta dominante (X ou Y)
    if (deltaX.abs() > deltaY.abs()) {
      double newWidth, newHeight;

      if (right || left) {
        newWidth = config.width + (right ? 2 * deltaX : -2 * deltaX);
        newHeight = newWidth / aspectRatio;
      } else {
        return; // Sem efeito se não tiver left/right
      }

      if (newWidth > 0 && newHeight > 0) {
        config.left -= (newWidth - config.width) / 2;
        config.top -= (newHeight - config.height) / 2;
        config.width = newWidth;
        config.height = newHeight;
      }
    } else {
      double newHeight, newWidth;

      if (top || bottom) {
        newHeight = config.height + (bottom ? 2 * deltaY : -2 * deltaY);
        newWidth = newHeight * aspectRatio;
      } else {
        return; // Sem efeito se não tiver top/bottom
      }

      if (newHeight > 0 && newWidth > 0) {
        config.left -= (newWidth - config.width) / 2;
        config.top -= (newHeight - config.height) / 2;
        config.width = newWidth;
        config.height = newHeight;
      }
    }
  }
} 