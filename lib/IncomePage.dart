import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_models.dart';

// The IncomePage widget, where users can view income entries
class IncomePage extends StatelessWidget {
  final List<IncomeEntry> incomeEntries;
  final Function(String) onDelete;
  final Future<bool?> Function({
    required BuildContext context,
    required String title,
    required String content,
  }) showConfirmationDialog;

  const IncomePage({
    super.key,
    required this.incomeEntries,
    required this.onDelete,
    required this.showConfirmationDialog,
  });

  // A helper method to format numbers with thousands separators
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل الدخل',
                style: GoogleFonts.lemonada(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: incomeEntries.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد عمليات دخل لعرضها.',
                          style: GoogleFonts.lemonada(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                  itemCount: incomeEntries.length,
                  itemBuilder: (context, index) {
                    final entry = incomeEntries[index];
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
                            color: Colors.green.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.arrow_upward, color: Colors.green.shade800),
                        ),
                        title: Text(
                          entry.source,
                          style: GoogleFonts.lemonada(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          entry.reason,
                          style: GoogleFonts.lemonada(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatWithCommas(entry.amount)} ${entry.currency}',
                                  style: GoogleFonts.lemonada(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                  style: GoogleFonts.lemonada(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showConfirmationDialog(
                                  context: context,
                                  title: 'تأكيد الحذف',
                                  content: 'هل أنت متأكد من حذف هذا السجل؟ سيتم عكس تأثيره على رصيدك.',
                                );
                                if (confirmed == true) {
                                  onDelete(entry.id);
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
