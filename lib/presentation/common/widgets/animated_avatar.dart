import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedAvatar extends StatefulWidget {
  final String text;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showShadow;

  const AnimatedAvatar({
    Key? key,
    required this.text,
    this.radius = 30.0,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.imageUrl,
    this.onTap,
    this.showBorder = true,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() {
            _isPressed = true;
          });
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() {
            _isPressed = false;
          });
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) {
          setState(() {
            _isPressed = false;
          });
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildAvatar(),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        backgroundImage: widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
        child: widget.imageUrl == null
            ? Text(
                widget.text.isNotEmpty ? widget.text[0].toUpperCase() : '?',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: widget.radius * 0.7,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
} 