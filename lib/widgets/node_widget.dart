import 'package:flutter/material.dart';

typedef NodeMoveCallback = void Function(String nodeId, Offset newPosition);

class NodeWidget extends StatefulWidget {
  final String nodeId;
  final Offset position;
  final Color color;
  final BoxShape shape;
  final bool isDiamond;
  final NodeMoveCallback onMove;

  const NodeWidget({
    Key? key,
    required this.nodeId,
    required this.position,
    required this.color,
    required this.shape,
    required this.isDiamond,
    required this.onMove,
  }) : super(key: key);

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  Offset _currentPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          // Initialize drag starting point
          _currentPosition = widget.position;
        },
        onPanUpdate: (details) {
          setState(() {
            // Directly update position based on drag
            _currentPosition += details.delta;

            // Update the node's position on the canvas
            widget.onMove(widget.nodeId, _currentPosition);
          });
        },
        onPanEnd: (details) {
          setState(() {
            // Snap to the nearest grid point when drag ends
            _currentPosition = _snapToGrid(_currentPosition);

            // Final position update
            widget.onMove(widget.nodeId, _currentPosition);
          });
        },
        child: Transform.rotate(
          angle: widget.isDiamond ? 45 * 3.14159 / 180 : 0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.color,
              shape: widget.shape,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: widget.shape == BoxShape.rectangle && !widget.isDiamond
                  ? BorderRadius.circular(10)
                  : null,
            ),
            child: Center(
              child: Transform.rotate(
                angle: widget.isDiamond ? -45 * 3.14159 / 180 : 0,
                child: Text(
                  widget.nodeId,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _snapToGrid(Offset position) {
    final double gridSize = 20.0;
    final double x = (position.dx / gridSize).round() * gridSize;
    final double y = (position.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }
}
