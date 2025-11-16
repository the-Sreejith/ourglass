import 'dart:math';
import 'package:flutter/material.dart';

class PixelHourglass extends StatelessWidget {
  const PixelHourglass({
    super.key,
    required this.topSandFraction,
    required this.bottomSandFraction,
    required this.totalGridCells,
    required this.orientation,
    required this.isFalling,
    this.sandColor,
    this.emptyColor,
  });

  final double topSandFraction;
  final double bottomSandFraction;
  final int totalGridCells;
  final int orientation;
  final bool isFalling;
  final Color? sandColor;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final int topFullCells = (topSandFraction * totalGridCells).round();
    final int bottomFullCells = (bottomSandFraction * totalGridCells).round();

    final bool isUpsideDown = orientation == -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PixelBulb(
          key: const ValueKey('top'),
          sandCellCount: topFullCells,
          totalCellCount: totalGridCells,
          isTop: isUpsideDown,
          isUpsideDown: isUpsideDown,
          isFalling: false,
          sandColor: sandColor,
          emptyColor: emptyColor,
        ),
        const SizedBox(height: 90),
        _PixelBulb(
          key: const ValueKey('bottom'),
          sandCellCount: bottomFullCells,
          totalCellCount: totalGridCells,
          isTop: !isUpsideDown,
          isUpsideDown: isUpsideDown,
          isFalling: isFalling,
          sandColor: sandColor,
          emptyColor: emptyColor,
        ),
      ],
    );
  }
}

class _PixelBulb extends StatefulWidget {
  const _PixelBulb({
    super.key,
    required this.sandCellCount,
    required this.totalCellCount,
    required this.isTop,
    required this.isUpsideDown,
    required this.isFalling,
    this.sandColor,
    this.emptyColor,
  });

  final int sandCellCount;
  final int totalCellCount;
  final bool isTop;
  final bool isUpsideDown;
  final bool isFalling;
  final Color? sandColor;
  final Color? emptyColor;

  static final Map<int, int> _fillOrderMap = _buildFillOrderMap();

  static Map<int, int> _buildFillOrderMap() {
    const int gridWidth = 8;
    const int totalCells = 64;
    List<int> sortedIndices = List.generate(totalCells, (i) => i);

    sortedIndices.sort((a, b) {
      final int rowA = a ~/ gridWidth;
      final int colA = a % gridWidth;
      final int levelA = rowA + colA;
      final int distA = (rowA - colA).abs();
      final int rowB = b ~/ gridWidth;
      final int colB = b % gridWidth;
      final int levelB = rowB + colB;
      final int distB = (rowB - colB).abs();
      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }
      if (distA != distB) {
        return distA.compareTo(distB);
      }
      return rowA.compareTo(rowB);
    });

    final Map<int, int> map = {};
    for (int i = 0; i < sortedIndices.length; i++) {
      map[sortedIndices[i]] = i;
    }
    return map;
  }

  @override
  State<_PixelBulb> createState() => _PixelBulbState();
}

class _PixelBulbState extends State<_PixelBulb>
    with SingleTickerProviderStateMixin {
  late AnimationController _fallController;
  late Animation<int> _fallingPixelIndex;

  static const List<int> _diagonalIndicesList = [63, 54, 45, 36, 27, 18, 9, 0];

  @override
  void initState() {
    super.initState();
    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fallingPixelIndex = IntTween(begin: 0, end: 7).animate(_fallController);
  }

  @override
  void dispose() {
    _fallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.isTop ? 5 * pi / 4 : pi / 4,
      child: SizedBox(
        width: 200,
        height: 200,
        child: AnimatedBuilder(
          animation: _fallingPixelIndex,
          builder: (context, child) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.totalCellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                final int fillPriority = _PixelBulb._fillOrderMap[index]!;

                bool isFull;

                if (widget.isUpsideDown) {
                  isFull = widget.isTop
                      ? fillPriority >=
                            (widget.totalCellCount - widget.sandCellCount)
                      : fillPriority < widget.sandCellCount;
                } else {
                  isFull = widget.isTop
                      ? fillPriority < widget.sandCellCount
                      : fillPriority >=
                            (widget.totalCellCount - widget.sandCellCount);
                }

                bool isFallingPixel = false;
                if (widget.isFalling) {
                  final int currentFallingStep = _fallingPixelIndex.value;
                  if (_diagonalIndicesList[currentFallingStep] == index) {
                    isFallingPixel = true;
                  }
                }

                final bool finalIsFull = isFull || isFallingPixel;

                return _Pixel(
                  isFull: finalIsFull,
                  sandColor: widget.sandColor,
                  emptyColor: widget.emptyColor,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Pixel extends StatelessWidget {
  const _Pixel({required this.isFull, this.sandColor, this.emptyColor});

  final bool isFull;
  final Color? sandColor;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isFull
            ? (sandColor ?? Colors.white)
            : (emptyColor ?? const Color(0xFF222222)),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
