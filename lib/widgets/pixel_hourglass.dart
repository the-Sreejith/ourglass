import 'dart:math';
import 'package:flutter/material.dart';

class PixelHourglass extends StatelessWidget {
  const PixelHourglass({
    super.key,
    required this.topSandFraction,
    required this.bottomSandFraction,
    required this.totalGridCells,
  });

  final double topSandFraction;
  final double bottomSandFraction;
  final int totalGridCells;

  @override
  Widget build(BuildContext context) {
    final int topFullCells = (topSandFraction * totalGridCells).round();
    final int bottomFullCells = (bottomSandFraction * totalGridCells).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // This is the TOP bulb
        _PixelBulb(
          key: const ValueKey('top'),
          sandCellCount: topFullCells,
          totalCellCount: totalGridCells,
          isBottomBulb: false, // It's the top bulb
        ),

        const SizedBox(height: 90),

        // This is the BOTTOM bulb
        _PixelBulb(
          key: const ValueKey('bottom'),
          sandCellCount: bottomFullCells,
          totalCellCount: totalGridCells,
          isBottomBulb: true, // It's the bottom bulb
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
    required this.isBottomBulb, // Changed from 'isTop' for clarity
  });

  final int sandCellCount;
  final int totalCellCount;
  final bool isBottomBulb;

  // This map is now static and built once.
  static final Map<int, int> _fillOrderMap = _buildFillOrderMap();

  // ⭐️ MODIFIED: This function now sorts cells from the
  // bottom-center vertex (index 63) outwards.
  static Map<int, int> _buildFillOrderMap() {
    const int gridWidth = 8;
    const int totalCells = 64;
    const int gridEnd = gridWidth - 1; // 7

    List<int> sortedIndices = List.generate(totalCells, (i) => i);
    
    // Sort by distance from the bottom-right corner (index 63)
    // which becomes the bottom vertex of the diamond.
    sortedIndices.sort((a, b) {
      int rowA = a ~/ gridWidth;
      int colA = a % gridWidth;
      // "Level" is the Manhattan distance from the (7, 7) corner
      int levelA = (gridEnd - rowA) + (gridEnd - colA);

      int rowB = b ~/ gridWidth;
      int colB = b % gridWidth;
      int levelB = (gridEnd - rowB) + (gridEnd - colB);

      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      } else {
        // Tie-breaker: fill bottom-most rows of a level first
        return (gridEnd - rowA).compareTo(gridEnd - rowB);
      }
    });

    final Map<int, int> map = {};
    for (int i = 0; i < sortedIndices.length; i++) {
      // { index: fill_priority }
      // index 63 will have priority 0
      // index 0 will have priority 63
      map[sortedIndices[i]] = i;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
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
            final bool isPixelFull;

            // ⭐️ MODIFIED: The fill logic now depends on
            // whether this is the top or bottom bulb.
            if (isBottomBulb) {
              // This is the BOTTOM bulb.
              // It fills from priority 0 (bottom) up.
              // If count=10, priorities 0-9 are full.
              isPixelFull = fillPriority < sandCellCount;
            } else {
              // This is the TOP bulb.
              // It empties from priority 0 (bottom) up.
              // The *remaining* sand (sandCellCount) is at the
              // highest priorities (the top).
              // If count=10, priorities 54-63 are full.
              isPixelFull = fillPriority >= (totalCellCount - sandCellCount);
            }

            return _Pixel(isFull: isPixelFull);
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