import 'package:flutter/material.dart';
import 'package:custom_node_editor/widgets/node_widget.dart';
import 'package:uuid/uuid.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({Key? key}) : super(key: key);

  @override
  _NodeEditorState createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  double _scale = 1.0; // Initial scale factor
  final Map<String, Offset> _nodes = {};
  final Uuid uuid = Uuid(); // UUID generator for unique IDs

  void _updateNodePosition(String nodeId, Offset newPosition) {
    setState(() {
      _nodes[nodeId] = newPosition;
    });
  }

  void _addNode(String nodeType, Offset position, Color color, BoxShape shape, bool isDiamond) {
    final uniqueId = '${nodeType}_${uuid.v4()}'; // Generate a unique ID for each node instance
    setState(() {
      _nodes[uniqueId] = position * _scale;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Editor'),
        actions: [
          Row(
            children: [
              Text("Node Size: ${(_scale * 100).round()}%"),
              Slider(
                value: _scale,
                min: 0.5,
                max: 2.0,
                onChanged: (newValue) {
                  setState(() {
                    _scale = newValue;
                  });
                },
              ),
            ],
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
                _buildDraggablePaletteButton("Start", Colors.green, BoxShape.circle, false),
                SizedBox(height: 10),
                _buildDraggablePaletteButton("Process", Colors.blue, BoxShape.rectangle, false),
                SizedBox(height: 10),
                _buildDraggablePaletteButton("Decision", Colors.orange, BoxShape.rectangle, true),
                SizedBox(height: 10),
                _buildDraggablePaletteButton("Stop", Colors.red, BoxShape.circle, false),
              ],
            ),
          ),
          // The canvas with grid and nodes
          Expanded(
            child: DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) {
                final nodeType = details.data['nodeId']; // Use node type instead of ID
                final Color color = details.data['color'];
                final BoxShape shape = details.data['shape'];
                final bool isDiamond = details.data['isDiamond'];

                // Calculate the drop position and adjust by the node's size
                final double nodeWidth = 100 * _scale;  // Assuming node width is 100 * scale
                final double nodeHeight = 100 * _scale; // Assuming node height is 100 * scale
                final dropPosition = details.offset - Offset(nodeWidth / 2, nodeHeight / 2);

                _addNode(nodeType, dropPosition, color, shape, isDiamond);
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  children: [
                    // Grid Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(gridSize: 20 * _scale),
                      ),
                    ),
                    // Nodes on the canvas
                    Positioned.fill(
                      child: Stack(
                        children: _nodes.entries.map((entry) {
                          final nodeType = entry.key.split('_')[0]; // Extract the node type from the unique ID
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
                            label: nodeType, // Use node type as the label
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePaletteButton(String nodeType, Color color, BoxShape shape, bool isDiamond) {
    return Draggable<Map<String, dynamic>>(
      data: {
        'nodeId': nodeType, // Pass the node type instead of a unique ID
        'color': color,
        'shape': shape,
        'isDiamond': isDiamond,
        'position': null,
      },
      feedback: Material(
        color: Colors.transparent,
        child: _buildNodePreview(nodeType, color, shape, isDiamond, scale: 1.0), // No scaling on palette
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildNodePreview(nodeType, color, shape, isDiamond, scale: 1.0), // No scaling on palette
      ),
      child: _buildNodePreview(nodeType, color, shape, isDiamond, scale: 1.0), // No scaling on palette
    );
  }

  Widget _buildNodePreview(String nodeType, Color color, BoxShape shape, bool isDiamond, {required double scale}) {
    return Container(
      width: 80 * scale, // Apply scaling only if required
      height: 80 * scale, // Apply scaling only if required
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle && !isDiamond ? BorderRadius.circular(10 * scale) : null,
      ),
      child: Center(
        child: Transform.rotate(
          angle: isDiamond ? 45 * 3.14159 / 180 : 0,
          child: Text(
            nodeType, // Display only the node type (e.g., "Start," "Process")
            style: TextStyle(color: Colors.white, fontSize: 12 * scale),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// GridPainter class to paint the grid background
class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
