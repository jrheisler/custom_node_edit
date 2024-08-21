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
        onPanUpdate: (details) {
          setState(() {
            _currentPosition += details.delta;
          });
          widget.onMove(widget.nodeId, _currentPosition);
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
              child: Text(
                widget.nodeId,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
