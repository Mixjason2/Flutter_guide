import 'package:flutter/material.dart';

class PaginationControl extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const PaginationControl({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: currentPage > 1 ? onPrev : null,
          child: const Text('Prev'),
        ),
        Text('$currentPage / $totalPages'),
        TextButton(
          onPressed: currentPage < totalPages ? onNext : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}
