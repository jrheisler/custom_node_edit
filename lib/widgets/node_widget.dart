import 'package:flutter/material.dart';

typedef NodeMoveCallback = void Function(String nodeId, Offset newPosition);
typedef AnchorPositionCallback = void Function(String nodeId, Map<String, Offset> anchorPositions);

class NodeWidget extends StatefulWidget {
  final String nodeId;
  final Offset position;
  final Color color;
  final BoxShape shape;
  final bool isDiamond;
  final NodeMoveCallback onMove;
  final double scale;
  final String label;
  final Function(String, String, Offset) onAnchorDragStart;
  final Function(String, String, Offset) onAnchorDragUpdate;
  final Function(String, String, Offset) onAnchorDragEnd;
  final Function(String, Map<String, Offset>) onAnchorPositionUpdate; // Accept anchor positions

  const NodeWidget({
    Key? key,
    required this.nodeId,
    required this.position,
    required this.color,
    required this.shape,
    required this.isDiamond,
    required this.onMove,
    required this.scale,
    required this.label,
    required this.onAnchorDragStart,
    required this.onAnchorDragUpdate,
    required this.onAnchorDragEnd,
    required this.onAnchorPositionUpdate,
  }) : super(key: key);

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}


class _NodeWidgetState extends State<NodeWidget> {
  Offset _currentPosition = Offset.zero;
  final Map<String, Offset> _anchorPositions = {}; // Store anchor positions

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;

    // Update anchor positions initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnchorPositions();
    });
  }

  @override
  void dispose() {
    // Dispose any controllers, streams, or other resources
    super.dispose();
  }

  @override
  void didUpdateWidget(NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update anchor positions whenever the widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnchorPositions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _currentPosition = widget.position;
        },
        onPanUpdate: (details) {
          setState(() {
            _currentPosition += details.delta;
            widget.onMove(widget.nodeId, _currentPosition);
            _updateAnchorPositions(); // Update positions during move
          });
        },
        onPanEnd: (details) {
          setState(() {
            _currentPosition = _snapToGrid(_currentPosition);
            widget.onMove(widget.nodeId, _currentPosition);
            _updateAnchorPositions(); // Ensure positions are accurate after move
          });
        },
        child: Container(
          width: 120 * widget.scale,
          height: 120 * widget.scale,
          child: Stack(
            children: [
              // Node Container
              Positioned.fill(
                child: Transform.rotate(
                  angle: widget.isDiamond ? 45 * 3.14159 / 180 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: widget.shape,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: widget.shape == BoxShape.rectangle && !widget.isDiamond
                          ? BorderRadius.circular(10 * widget.scale)
                          : null,
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: widget.isDiamond ? -45 * 3.14159 / 180 : 0,
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * widget.scale,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Anchors
              if (widget.label == 'Start')
                _buildAnchor('out', Alignment.centerRight, Colors.white, Icons.output),
              if (widget.label == 'Stop')
                _buildAnchor('in', Alignment.centerLeft, Colors.white, Icons.input),
              if (widget.label == 'Process') ...[
                _buildAnchor('in', Alignment.centerLeft, Colors.white, Icons.input),
                _buildAnchor('out', Alignment.centerRight, Colors.white, Icons.output),
              ],
              if (widget.label == 'Decision') ...[
                _buildAnchor('in', Alignment.centerLeft, Colors.white, Icons.input),
                _buildAnchor('outTrue', Alignment.topRight, Colors.green, Icons.output),
                _buildAnchor('outFalse', Alignment.bottomRight, Colors.red, Icons.output),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnchor(String anchorId, Alignment alignment, Color color, IconData icon) {
    return Positioned(
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onPanStart: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final offset = renderBox.localToGlobal(details.localPosition);
            widget.onAnchorDragStart(widget.nodeId, anchorId, offset);
          },
          onPanUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final offset = renderBox.localToGlobal(details.localPosition);
            widget.onAnchorDragUpdate(widget.nodeId, anchorId, offset);
          },
          onPanEnd: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final offset = renderBox.localToGlobal(details.localPosition);
            widget.onAnchorDragEnd(widget.nodeId, anchorId, offset);
          },
          child: Icon(
            icon,
            color: color,
            size: 24 * widget.scale,
          ),
        ),
      ),
    );
  }
/*
  void _updateAnchorPositions() {
    final renderBox = context.findRenderObject() as RenderBox;

    setState(() {
      final topLeft = renderBox.localToGlobal(Offset.zero); // Top-left corner of the node
      final nodeWidth = renderBox.size.width;
      final nodeHeight = renderBox.size.height;

      // Input anchor on the left-center
      _anchorPositions['in'] = topLeft + Offset(0, nodeHeight / 2);

      // Output anchor on the right-center
      _anchorPositions['out'] = topLeft + Offset(0,nodeHeight/4);//nodeWidth, nodeHeight / 2);

      if (widget.label == 'Decision') {
        // "True" anchor on the right-top
        _anchorPositions['outTrue'] = topLeft + Offset(nodeWidth, nodeHeight / 4);

        // "False" anchor on the right-bottom
        _anchorPositions['outFalse'] = topLeft + Offset(nodeWidth, 3 * nodeHeight / 4);
      }

      // Notify NodeEditor of these anchor positions
      widget.onAnchorPositionUpdate(widget.nodeId, _anchorPositions);

      // Debugging output
      //print('Anchor Positions for ${widget.nodeId}: $_anchorPositions');
    });
  }

 */
  void _updateAnchorPositions() {
    final renderBox = context.findRenderObject() as RenderBox;

    setState(() {
      final topLeft = renderBox.localToGlobal(Offset.zero); // Top-left corner of the node
      final nodeWidth = renderBox.size.width;
      final nodeHeight = renderBox.size.height;

      _anchorPositions['in'] = topLeft + Offset(0, nodeHeight / 2);
      _anchorPositions['out'] = topLeft + Offset(0, nodeHeight / 7);

      if (widget.label == 'Decision') {
        _anchorPositions['outTrue'] = topLeft;// + Offset(nodeWidth, nodeHeight / 4);
        _anchorPositions['outFalse'] = topLeft;// + Offset(nodeWidth, 3 * nodeHeight / 4);
      }

      widget.onAnchorPositionUpdate(widget.nodeId, _anchorPositions);

      // Debugging output
      //print('Anchor Positions for ${widget.nodeId}: $_anchorPositions');
    });
  }



  Offset _snapToGrid(Offset position) {
    final double gridSize = 20.0;
    final double x = (position.dx / gridSize).round() * gridSize;
    final double y = (position.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }
}
