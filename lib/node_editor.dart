import 'package:flutter/material.dart';
import 'package:custom_node_editor/widgets/node_widget.dart';
import 'package:uuid/uuid.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({Key? key}) : super(key: key);

  @override
  _NodeEditorState createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  final Map<String, Offset> _nodes = {};
  final Map<String, Map<String, String>> _connections = {}; // Store connections by node and anchor
  final Map<String, Map<String, Offset>> _nodeAnchors = {}; // Store anchor positions
  final Uuid uuid = Uuid(); // UUID generator for unique IDs
  Offset? connectionStart;
  Offset? currentConnectionPosition;
  String? startNode;
  String? startAnchor;

  double _scale = 1.0;
  Offset _panOffset = Offset.zero; // Track the pan offset

  @override
  void dispose() {
    super.dispose();
  }

  void _storeAnchorPositions(String nodeId, Map<String, Offset> anchorPositions) {
    setState(() {
      _nodeAnchors[nodeId] = anchorPositions;

      // Debugging - Print the updated anchor positions
      //anchorPositions.forEach((anchorId, position) {
      //  print('Node: $nodeId, Anchor: $anchorId, Position: $position');
      //});
    });
  }

  void _updateNodePosition(String nodeId, Offset newPosition) {
    setState(() {
      _nodes[nodeId] = newPosition;
      _storeAnchorPositions(nodeId, _nodes);

      // Debugging: Log the node's new position
      //print('DEBUG: Node $nodeId position updated to $newPosition');
    });
  }


  void _addNode(String nodeType, Offset globalPosition, Color color, BoxShape shape, bool isDiamond) {
    final uniqueId = '${nodeType}_${uuid.v4()}'; // Generate a unique ID for each node instance

    // Adjust the global position by manually applying the pan and scale
    final Offset adjustedPosition = (globalPosition + _panOffset) / _scale;

    setState(() {
      _nodes[uniqueId] = adjustedPosition;
      _storeAnchorPositions(uniqueId, _nodes);
      // Assuming the NodeWidget will report its anchor positions after it is added.
    });
  }


  void _onScaleUpdate(double newScale) {
    setState(() {
      _scale = newScale;
    });
  }

  void _onPanUpdate(Offset newOffset) {
    setState(() {
      _panOffset = newOffset;
    });
  }

  void _onAnchorDragStart(String nodeId, String anchorId, Offset startPosition) {
    setState(() {
      startNode = nodeId;
      startAnchor = anchorId;
      connectionStart = startPosition;
      currentConnectionPosition = startPosition;

      //print('DEBUG: Drag started from $startNode (Anchor: $startAnchor) at position: $startPosition');
    });
  }

  void _onAnchorDragUpdate(String nodeId, String anchorId, Offset position) {
    setState(() {
      currentConnectionPosition = position;
    });
  }
/*
  void _onAnchorDragEnd(String nodeId, String anchorId, Offset endPosition) {
    setState(() {
      if (startNode != null && startAnchor != null) {
        final String? endNode = _findNodeAtPosition(endPosition);

        if (endNode != null && startNode != endNode) {
          final startAnchorPos = _nodeAnchors[startNode!]?[startAnchor!];
          final endAnchorPos = _nodeAnchors[endNode]?[anchorId];

          if (startAnchorPos != null && endAnchorPos != null) {
            _connections[startNode!] ??= {};
            _connections[startNode!]![startAnchor!] = endNode;

            connectionStart = startAnchorPos;
            currentConnectionPosition = endAnchorPos;

            print('DEBUG: Connection made from $startNode (Anchor: $startAnchor) to $endNode (Anchor: $anchorId)');
            print('DEBUG: Start Anchor Position: $startAnchorPos');
            print('DEBUG: End Anchor Position: $endAnchorPos');
          } else {
            print('DEBUG: Could not find start or end anchor position.');
          }
        } else if (endNode == null) {
          print('DEBUG: No node found at end position.');
        } else {
          print('DEBUG: Attempted to connect node to itself.');
        }
      } else {
        print('DEBUG: Start node or anchor is null.');
      }

      connectionStart = null;
      currentConnectionPosition = null;
      startNode = null;
      startAnchor = null;
    });
  }
*/
  void _onAnchorDragEnd(String nodeId, String anchorId, Offset endPosition) {
    setState(() {
      // Debugging: Output the start information
      print('Start Node: $startNode, Start Anchor: $startAnchor');
      print('End Position: $endPosition');

      if (startNode != null && startAnchor != null) {
        // Find the node at the end position
        final String? endNode = _findNodeAtPosition(endPosition);

        if (endNode != null && startNode != endNode) {
          final startAnchorPos = _nodeAnchors[startNode!]?[startAnchor!];
          final endAnchorPos = _nodeAnchors[endNode]?[anchorId]; // Corrected end anchor position lookup

          if (startAnchorPos != null && endAnchorPos != null) {
            _connections[startNode!] ??= {};
            _connections[startNode!]![startAnchor!] = endNode;

            connectionStart = startAnchorPos;
            currentConnectionPosition = endAnchorPos;

            // Debugging: Output the connection information
            print('Connection made from $startNode (Anchor: $startAnchor) to $endNode (Anchor: $anchorId)');
            print('Start Anchor Position: $connectionStart');
            print('End Anchor Position: $currentConnectionPosition');
          } else {
            print('Could not find valid anchor positions.');
          }
        } else if (endNode == null) {
          print('No node found at the end position.');
        } else {
          print('Attempted to connect node to itself.');
        }
      } else {
        print('Start node or anchor is null.');
      }

      // Reset the dragging state
      connectionStart = null;
      currentConnectionPosition = null;
      startNode = null;
      startAnchor = null;
    });
  }
  String? _findNodeAtPosition(Offset position) {
    for (var entry in _nodes.entries) {
      final nodePosition = entry.value;
      final nodeSize = Size(120 * _scale, 120 * _scale); // Assuming all nodes are 120x120 scaled
      final nodeRect = Rect.fromLTWH(nodePosition.dx, nodePosition.dy, nodeSize.width, nodeSize.height);

      if (nodeRect.contains(position)) {
        return entry.key;
      }
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Editor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Node Size:'),
                Slider(
                  value: _scale,
                  onChanged: _onScaleUpdate,
                  min: 0.5,
                  max: 2.0,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Palette on the left
          Container(
            width: 100,
            color: Colors.grey.shade900,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                _buildDraggablePaletteButton(
                    "Start", Colors.green, BoxShape.circle, false),
                SizedBox(height: 10),
                _buildDraggablePaletteButton(
                    "Process", Colors.blue, BoxShape.rectangle, false),
                SizedBox(height: 10),
                _buildDraggablePaletteButton(
                    "Decision", Colors.orange, BoxShape.rectangle, true),
                SizedBox(height: 10),
                _buildDraggablePaletteButton(
                    "Stop", Colors.red, BoxShape.circle, false),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.0,
              constrained: false,
              onInteractionUpdate: (details) {
                _panOffset = details.focalPoint;
                _scale = details.scale;
                _onPanUpdate(details.localFocalPoint);
              },
              child: Container(
                width: 3000,
                height: 3000,
                color: Colors.grey.shade800,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(gridSize: 20),
                      ),
                    ),
                    Positioned.fill(
                      child: DragTarget<Map<String, dynamic>>(
                        onAcceptWithDetails: (details) {
                          final nodeType = details.data['nodeId'];
                          final Color color = details.data['color'];
                          final BoxShape shape = details.data['shape'];
                          final bool isDiamond = details.data['isDiamond'];

                          _addNode(nodeType, details.offset, color, shape, isDiamond);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Stack(
                            children: [
                              for (final entry in _connections.entries)
                                for (final connection in entry.value.entries)
                                  CustomPaint(
                                    painter: ConnectionPainter(
                                      start: _nodeAnchors[entry.key]![connection.key]!,
                                      end: _nodeAnchors[connection.value]![connection.key]!,
                                    ),
                                  ),
                              ..._nodes.entries.map((entry) {
                                final nodeType = entry.key.split('_')[0];
                                final shape = nodeType == "Decision"
                                    ? BoxShape.rectangle
                                    : (nodeType == "Process" ? BoxShape.rectangle : BoxShape.circle);
                                final color = nodeType == "Start"
                                    ? Colors.green
                                    : nodeType == "Process"
                                    ? Colors.blue
                                    : nodeType == "Decision"
                                    ? Colors.orange
                                    : Colors.red;

                                return NodeWidget(
                                  nodeId: entry.key,
                                  position: entry.value,
                                  color: color,
                                  shape: shape,
                                  isDiamond: nodeType == "Decision",
                                  onMove: _updateNodePosition,
                                  scale: _scale,
                                  label: nodeType,
                                  onAnchorDragStart: _onAnchorDragStart,
                                  onAnchorDragUpdate: _onAnchorDragUpdate,
                                  onAnchorDragEnd: _onAnchorDragEnd,
                                  onAnchorPositionUpdate: _storeAnchorPositions,
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                    if (connectionStart != null && currentConnectionPosition != null)
                      CustomPaint(
                        painter: ConnectionPainter(
                          start: connectionStart!,
                          end: currentConnectionPosition!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePaletteButton(
      String nodeType, Color color, BoxShape shape, bool isDiamond) {
    return Draggable<Map<String, dynamic>>(
      data: {
        'nodeId': nodeType,
        'color': color,
        'shape': shape,
        'isDiamond': isDiamond,
      },
      feedback: Material(
        color: Colors.transparent,
        child: _buildNodePreview(nodeType, color, shape, isDiamond),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildNodePreview(nodeType, color, shape, isDiamond),
      ),
      child: _buildNodePreview(nodeType, color, shape, isDiamond),
    );
  }

  Widget _buildNodePreview(
      String nodeType, Color color, BoxShape shape, bool isDiamond) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle && !isDiamond
            ? BorderRadius.circular(10)
            : null,
      ),
      child: Center(
        child: Transform.rotate(
          angle: isDiamond ? 45 * 3.14159 / 180 : 0,
          child: Text(
            nodeType,
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ConnectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  ConnectionPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    // Debugging: Log the positions used for drawing the connection
    //print('DEBUG: Drawing connection from $start to $end');

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
