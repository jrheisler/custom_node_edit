import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:custom_node_editor/widgets/node_widget.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

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
  Timer? _throttleTimer;

  void _onPanUpdate(Offset newOffset) {
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(Duration(milliseconds: 16), () {
      setState(() {
        _panOffset = newOffset;
      });
    });
  }



  @override
  void dispose() {
    // Dispose any controllers, streams, or other resources
    super.dispose();
  }

  String exportToJson() {
    final data = {
      'nodes': _nodes.map((key, value) => MapEntry(key, {'position': {'dx': value.dx, 'dy': value.dy}})),
      'connections': _connections,
    };

    return jsonEncode(data);
  }

  void importFromJson(String jsonString) {
    final data = jsonDecode(jsonString);

    setState(() {
      _nodes.clear();
      _connections.clear();

      data['nodes'].forEach((key, value) {
        _nodes[key] = Offset(value['position']['dx'], value['position']['dy']);
      });

      _connections.addAll(Map<String, Map<String, String>>.from(data['connections']));
    });
  }


  void _updateNodePosition(String nodeId, Offset newPosition) {
    setState(() {
      _nodes[nodeId] = newPosition;
    });
  }

  void _addNode(String nodeType, Offset globalPosition, Color color, BoxShape shape, bool isDiamond) {
    final uniqueId = '${nodeType}_${uuid.v4()}'; // Generate a unique ID for each node instance

    // Adjust the global position by manually applying the pan and scale
    final Offset adjustedPosition = (globalPosition + _panOffset) / _scale;

    setState(() {
      _nodes[uniqueId] = adjustedPosition;
    });
  }

  void _onScaleUpdate(double newScale) {
    setState(() {
      _scale = newScale;
    });
  }



  void _onAnchorDragStart(String nodeId, String anchorId, Offset startPosition) {
    setState(() {
      // Set the start node and anchor only once at the beginning of the drag
      startNode = nodeId;
      startAnchor = anchorId;
      connectionStart = startPosition;
      currentConnectionPosition = startPosition;

      // Debugging
      print('Drag started from $startNode (Anchor: $startAnchor) at position: $startPosition');
    });
  }

  void _onAnchorDragUpdate(String nodeId, String anchorId, Offset position) {
    setState(() {
      currentConnectionPosition = position;

      // Debugging
      print('Dragging to Position: $currentConnectionPosition');
    });
  }

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
          final endAnchorPos = endPosition; // Use the passed in endPosition

          if (startAnchorPos != null) {
            // Create the connection
            _connections[startNode!] ??= {};
            _connections[startNode!]![startAnchor!] = endNode;

            // Set the connection positions
            connectionStart = startAnchorPos;
            currentConnectionPosition = endAnchorPos;

            // Debugging: Output the connection information
            print('Connection made from $startNode (Anchor: $startAnchor) to $endNode (Anchor: $anchorId)');
            print('Start Anchor Position: $connectionStart');
            print('End Anchor Position: $currentConnectionPosition');
          } else {
            print('Could not find start anchor position for the node.');
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
    // Iterate over all nodes to find which one contains the position
    for (var entry in _nodes.entries) {
      final nodePosition = entry.value;
      final nodeSize = Size(120 * _scale, 120 * _scale); // Assuming all nodes are 120x120 scaled
      final nodeRect = Rect.fromLTWH(nodePosition.dx, nodePosition.dy, nodeSize.width, nodeSize.height);

      if (nodeRect.contains(position)) {
        return entry.key; // Return the node ID
      }
    }
    return null; // No node found at this position
  }

  void _storeAnchorPositions(String nodeId, Map<String, Offset> anchorPositions) {
    setState(() {
      _nodeAnchors[nodeId] = anchorPositions;

      // Debugging
      //anchorPositions.forEach((anchorId, position) {
      //  print('Anchor: $anchorId, Position: $position');
      //});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _resetNodes,
        tooltip: 'Reset Nodes',
        child: Icon(Icons.refresh),
      ),
      appBar: AppBar(
        title: const Text('Node Editor'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveToLocalStorage,
            tooltip: 'Save to Local Storage',
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: loadFromLocalStorage,
            tooltip: 'Load from Local Storage',
          ),
          IconButton(
            icon: Icon(Icons.import_export),
            onPressed: () {
              final jsonString = exportToJson();
              print(jsonString); // Or use any method to export the JSON string
            },
            tooltip: 'Export to JSON',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              const jsonString = '{"nodes":{}, "connections":{}}'; // Replace with your JSON string
              importFromJson(jsonString);
            },
            tooltip: 'Import from JSON',
          ),
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
            color: Colors.grey.shade900, // Dark mode palette background
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
          // The panning and zooming canvas
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.0,
              constrained: false,
              onInteractionUpdate: (details) {
                _panOffset = details.focalPoint;
                _scale = details.scale;
                _onPanUpdate(details.localFocalPoint); // Update the pan offset
              },
              child: Container(
                width: 3000, // Set a very large width
                height: 3000, // Set a very large height
                color: Colors.grey.shade800, // Dark mode background
                child: Stack(
                  clipBehavior: Clip.none, // Ensure the content isn't clipped
                  children: [
                    // Grid Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(gridSize: 20),
                      ),
                    ),
                    // Nodes on the canvas
                    Positioned.fill(
                      child: DragTarget<Map<String, dynamic>>(
                        onAcceptWithDetails: (details) {
                          final nodeType = details.data['nodeId'];
                          final Color color = details.data['color'];
                          final BoxShape shape = details.data['shape'];
                          final bool isDiamond = details.data['isDiamond'];

                          // Correctly adjust the drop position using the transformation matrix
                          _addNode(nodeType, details.offset, color, shape, isDiamond);
                        },
                          builder: (context, candidateData, rejectedData) {
                            return Stack(
                              children: [
                                // Existing connections
                                ..._buildConnectionWidgets(),

                                // Nodes
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
                                    scale: _scale, // Apply the current scale
                                    label: nodeType,
                                    onAnchorDragStart: _onAnchorDragStart, // Handle anchor drag start
                                    onAnchorDragUpdate: _onAnchorDragUpdate, // Handle anchor drag update
                                    onAnchorDragEnd: _onAnchorDragEnd, // Handle anchor drag end
                                    onAnchorPositionUpdate: _storeAnchorPositions, // Handle anchor position updates
                                    onLongPress: _removeConnections, // Pass the removal method here
                                  );
                                }).toList(),
                              ],
                            );
                          }
                      ),
                    ),
                    // Active connection being drawn
                    if (connectionStart != null && currentConnectionPosition != null)
                      CustomPaint(
                        painter: ConnectionPainter(
                          start: connectionStart!,
                          end: currentConnectionPosition!, // Current mouse position
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
  void saveToLocalStorage() {
    final jsonString = exportToJson();
    window.localStorage['node_editor_data'] = jsonString;
  }

  void loadFromLocalStorage() {
    final jsonString = window.localStorage['node_editor_data'];
    if (jsonString != null) {
      importFromJson(jsonString);
    }
  }

  void _resetNodes() {
    setState(() {
      _nodes.clear();
      _connections.clear();
      _nodeAnchors.clear();
    });
  }
  void _removeConnections(String nodeId) {
    setState(() {
      // Remove all connections that originate from this node
      _connections.remove(nodeId);

      // Remove all connections that point to this node
      _connections.forEach((startNode, anchorMap) {
        anchorMap.removeWhere((anchorId, endNodeId) => endNodeId == nodeId);
      });
    });
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

  List<Widget> _buildConnectionWidgets() {
    List<Widget> connectionWidgets = [];

    for (final entry in _connections.entries) {
      final startNodeId = entry.key;
      final anchorMap = entry.value;

      for (final connection in anchorMap.entries) {
        final startAnchorId = connection.key;
        final endNodeId = connection.value;

        // Safely access the start and end anchor positions
        final startAnchorPos = _nodeAnchors[startNodeId]?[startAnchorId];
        final endAnchorPos = _nodeAnchors[endNodeId]?[startAnchorId];

        // Only add a CustomPaint widget if both positions are non-null
        if (startAnchorPos != null && endAnchorPos != null) {
          connectionWidgets.add(
            CustomPaint(
              painter: ConnectionPainter(
                start: startAnchorPos,
                end: endAnchorPos,
              ),
            ),
          );
        } else {
          print('Warning: Could not find anchor positions for connection from $startNodeId (anchor: $startAnchorId) to $endNodeId (anchor: $startAnchorId)');
        }
      }
    }

    return connectionWidgets;
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

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}


