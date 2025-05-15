import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

class AnimatedTaskCard extends StatefulWidget {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final TaskPriority priority;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;

  const AnimatedTaskCard({
    Key? key,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.onTap,
    this.onDelete,
    this.onComplete,
  }) : super(key: key);

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Swipe control
  double _dragExtent = 0;
  bool _isDragging = false;
  static const double _swipeThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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

  Color _getPriorityColor() {
    switch (widget.priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
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
        if (widget.onTap != null && _isPressed) {
          setState(() {
            _isPressed = false;
          });
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() {
            _isPressed = false;
          });
          _controller.reverse();
        }
      },
      onHorizontalDragStart: (_) {
        setState(() {
          _isDragging = true;
          _dragExtent = 0;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragExtent += details.delta.dx;
            // Limit drag extent
            _dragExtent = _dragExtent.clamp(-100.0, 100.0);
          });
        }
      },
      onHorizontalDragEnd: (_) {
        if (_isDragging) {
          if (_dragExtent <= -_swipeThreshold && widget.onDelete != null) {
            // Swiped left - delete
            widget.onDelete!();
          } else if (_dragExtent >= _swipeThreshold && widget.onComplete != null) {
            // Swiped right - complete
            widget.onComplete!();
          }
          
          // Reset position with animation
          setState(() {
            _isDragging = false;
            _dragExtent = 0;
          });
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildTaskCard(),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(_dragExtent, 0, 0),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCompleted ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.isCompleted ? Colors.grey.shade300 : _getPriorityColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Priority indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: widget.isCompleted ? Colors.grey : _getPriorityColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isCompleted ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: widget.isCompleted ? Colors.green.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: widget.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.green)
                        : const SizedBox(width: 16, height: 16),
                  ),
                ),
                
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: widget.isCompleted ? TextDecoration.lineThrough : null,
                          color: widget.isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (widget.description != null && widget.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isCompleted ? Colors.grey : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (widget.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: widget.isCompleted ? Colors.grey : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isCompleted ? Colors.grey : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Action icons
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: Colors.grey,
                  onPressed: widget.onTap,
                ),
              ],
            ),
          ),
          
          // Swipe indicators
          if (_isDragging)
            Positioned(
              right: _dragExtent < 0 ? 16 : null,
              left: _dragExtent > 0 ? 16 : null,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  _dragExtent < 0 ? Icons.delete : Icons.check_circle,
                  color: _dragExtent < 0 ? Colors.red : Colors.green,
                  size: 24 * ((_dragExtent.abs() / _swipeThreshold).clamp(0.5, 1.0)),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 