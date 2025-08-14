import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_models.dart';

class SourceDetailsPage extends StatelessWidget {
  final String sourceName;
  final List<ExpenseEntry> expenseEntries;

  const SourceDetailsPage({
    super.key,
    required this.sourceName,
    required this.expenseEntries,
  });

  String _formatWithCommas(double number) {
    String numberString = number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2);
    List<String> parts = numberString.split('.');
    RegExp regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger = parts[0].replaceAllMapped(regex, (Match m) => '${m[1]},');
    if (parts.length > 1) {
      return '$formattedInteger.${parts[1]}';
    }
    return formattedInteger;
  }

  @override
  Widget build(BuildContext context) {
    // فرز السجلات حسب التاريخ (الأحدث أولاً)
    final sortedEntries = List<ExpenseEntry>.from(expenseEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'سجل: $sourceName',
            style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_downward, color: Colors.red.shade800),
                ),
                title: Text(
                  entry.reason.isNotEmpty ? entry.reason : 'لا يوجد سبب',
                  style: GoogleFonts.lemonada(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: GoogleFonts.lemonada(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  '${_formatWithCommas(entry.amount)} ${entry.currency}',
                  style: GoogleFonts.lemonada(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
