import 'package:flutter/material.dart';
import 'widgets/node_widget.dart'; // Adjusted import for NodeWidget

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  _NodeEditorState createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  Map<String, Map<String, dynamic>> nodes = {};
  int nodeCount = 0; // Keep track of the number of nodes

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final List<String> availableNodes = ['Start', 'Process', 'Decision', 'Stop']; // List of available nodes

  void _addNode(String type, Offset position, Color color, BoxShape shape, bool isDiamond) {
    setState(() {
      nodeCount++;
      String nodeId = 'Node $nodeCount';
      nodes[nodeId] = {
        'type': type,
        'position': position,
        'color': color,
        'shape': shape,
        'isDiamond': isDiamond,
      };
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Node Editor'),
      ),
      body: Row(
        children: [
          _buildPalette(isDarkMode), // Add palette on the left side
          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true, // Show the vertical scrollbar thumb
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true, // Show the horizontal scrollbar thumb
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Container(
                        width: 2000, // Large width for the canvas
                        height: 2000, // Large height for the canvas
                        child: DragTarget<Map<String, dynamic>>(
                          onAccept: (data) {
                            // Get the position where the node is dropped
                            final RenderBox renderBox = context.findRenderObject() as RenderBox;
                            final dropPosition = renderBox.globalToLocal(data['dragPosition']);

                            _addNode(
                              data['type'],
                              dropPosition,
                              data['color'],
                              data['shape'],
                              data['isDiamond'],
                            );
                          },
                          builder: (context, candidateData, rejectedData) => Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(), // Grid background
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        if (nodes.isNotEmpty) {
                                          String lastNodeId = nodes.keys.last;
                                          nodes[lastNodeId]!['position'] = (nodes[lastNodeId]!['position'] as Offset) + details.delta;
                                        }
                                      });
                                    },
                                    child: Stack(
                                      children: nodes.entries.map((entry) {
                                        return NodeWidget(
                                          nodeId: entry.key,
                                          position: entry.value['position'],
                                          color: entry.value['color'],
                                          shape: entry.value['shape'],
                                          isDiamond: entry.value['isDiamond'],
                                          onMove: (id, position) {
                                            setState(() {
                                              nodes[id]!['position'] = position;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette(bool isDarkMode) {
    return Container(
      width: 100,
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: availableNodes.map((type) {
          return _buildPaletteItem(type, colorForType(type), shapeForType(type));
        }).toList(),
      ),
    );
  }

  Widget _buildPaletteItem(String type, Color color, BoxShape shape) {
    Offset dragPosition = Offset.zero;

    return Draggable<Map<String, dynamic>>(
      data: {
        'type': type,
        'color': color,
        'shape': shape,
        'isDiamond': type == 'Decision',
        'dragPosition': dragPosition,
      },
      feedback: _buildShape(type, color, shape),
      childWhenDragging: _buildShape(type, color, shape), // Keep the item visible during dragging
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildShape(type, color, shape),
      ),
      onDragUpdate: (details) {
        // Update the drag position dynamically
        dragPosition = details.globalPosition;
      },
    );
  }

  Color colorForType(String type) {
    switch (type) {
      case 'Start':
        return Colors.green;
      case 'Process':
        return Colors.grey;
      case 'Decision':
        return Colors.blue;
      case 'Stop':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  BoxShape shapeForType(String type) {
    switch (type) {
      case 'Start':
      case 'Stop':
        return BoxShape.circle;
      case 'Process':
        return BoxShape.rectangle;
      case 'Decision':
        return BoxShape.rectangle;
      default:
        return BoxShape.rectangle;
    }
  }

  Widget _buildShape(String type, Color color, BoxShape shape) {
    if (type == 'Decision') {
      return Transform.rotate(
        angle: 45 * 3.14159 / 180, // Rotate for diamond shape
        child: Container(
          width: 50,
          height: 50,
          color: color,
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: shape,
        ),
      );
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 20.0;
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
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
