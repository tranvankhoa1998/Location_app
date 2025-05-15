import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool showBorder;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const GradientCard({
    Key? key,
    required this.child,
    this.gradientColors = const [Color(0xFF2196F3), Color(0xFF1565C0)],
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.elevation = 4.0,
    this.showBorder = false,
    this.borderColor,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: showBorder
            ? BorderSide(
                color: borderColor ?? Colors.white.withOpacity(0.2),
                width: 1.0,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
} 