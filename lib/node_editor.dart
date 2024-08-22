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
  final Uuid uuid = Uuid(); // UUID generator for unique IDs

  double _scale = 1.0;
  Offset _panOffset = Offset.zero; // Track the pan offset

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

  void _onPanUpdate(Offset newOffset) {
    setState(() {
      _panOffset = newOffset;
    });
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
                        children: _nodes.entries.map((entry) {
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
                          );
                        }).toList(),
                      );
                    },
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
