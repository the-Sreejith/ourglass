import 'dart:math';
import 'package:flutter/material.dart';

class PixelHourglass extends StatelessWidget {
  const PixelHourglass({
    super.key,
    required this.topSandFraction,
    required this.bottomSandFraction,
    required this.totalGridCells,
    required this.orientation,
  });

  final double topSandFraction;
  final double bottomSandFraction;
  final int totalGridCells;
  final int orientation;

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
        ),

        const SizedBox(height: 90),

        _PixelBulb(
          key: const ValueKey('bottom'),
          sandCellCount: bottomFullCells,
          totalCellCount: totalGridCells,
          isTop: !isUpsideDown,
          isUpsideDown: isUpsideDown,
        ),
      ],
    );
  }
}

class _PixelBulb extends StatelessWidget {
  const _PixelBulb({
    super.key,
    required this.sandCellCount,
    required this.totalCellCount,
    required this.isTop,
    required this.isUpsideDown,
  });

  final int sandCellCount;
  final int totalCellCount;
  final bool isTop;
  final bool isUpsideDown;

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
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: isTop ? 5 * pi / 4 : pi / 4,
      child: SizedBox(
        width: 200,
        height: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            final int fillPriority = _fillOrderMap[index]!;

            bool isFull;

            if (isUpsideDown) {
              isFull = isTop
                  ? fillPriority >=
                        (totalCellCount -
                            sandCellCount) 
                  : fillPriority < sandCellCount;
            } else {
              isFull = isTop
                  ? fillPriority <
                        sandCellCount 
                  : fillPriority >= (totalCellCount - sandCellCount);
            }
            return _Pixel(isFull: isFull);
          },
        ),
      ),
    );
  }
}

class _Pixel extends StatelessWidget {
  const _Pixel({required this.isFull});

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isFull ? Colors.white : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
