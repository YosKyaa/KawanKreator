import 'package:flutter/material.dart';

class TodaysPlanCard extends StatelessWidget {
  const TodaysPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rencana Hari Ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Belum ada rencana. Tambahkan rencana pertama Anda!'),
          ],
        ),
      ),
    );
  }
}
