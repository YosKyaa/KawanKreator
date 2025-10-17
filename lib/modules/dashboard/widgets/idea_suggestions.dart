import 'package:flutter/material.dart';

class IdeaSuggestions extends StatelessWidget {
  const IdeaSuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Ide Konten',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('\u2022 Tips cepat produksi konten'),
            Text('\u2022 Template caption singkat'),
            Text('\u2022 Challenge mingguan'),
          ],
        ),
      ),
    );
  }
}
