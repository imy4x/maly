import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  final Future<void> Function() onClearAllData;
  final Future<void> Function(bool) onClearIncomeData;
  final Future<void> Function(bool) onClearExpenseData;
  final Future<bool?> Function({
    required BuildContext context,
    required String title,
    required String content,
  }) showConfirmationDialog;


  const SettingsPage({
    super.key,
    required this.onClearAllData,
    required this.onClearIncomeData,
    required this.onClearExpenseData,
    required this.showConfirmationDialog,
  });

  void _showClearOptions(BuildContext context, {required bool isIncome}) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'اختر نوع المسح',
              style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('مسح السجلات فقط', style: GoogleFonts.lemonada()),
                  subtitle: Text('سيتم حذف السجلات مع الإبقاء على الرصيد الحالي', style: GoogleFonts.lemonada(fontSize: 12)),
                  onTap: () {
                     Navigator.of(context).pop();
                     if (isIncome) {
                       onClearIncomeData(false);
                     } else {
                       onClearExpenseData(false);
                     }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text('مسح السجلات والمبالغ', style: GoogleFonts.lemonada()),
                  subtitle: Text('سيتم حذف السجلات وعكس تأثيرها على الرصيد', style: GoogleFonts.lemonada(fontSize: 12)),
                   onTap: () {
                     Navigator.of(context).pop();
                     if (isIncome) {
                       onClearIncomeData(true);
                     } else {
                       onClearExpenseData(true);
                     }
                  },
                ),
              ],
            ),
            actions: [
               TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: GoogleFonts.lemonada(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الإعدادات', style: GoogleFonts.lemonada(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.file_download_off, color: Colors.green.shade700),
                title: Text(
                  'مسح سجل الدخل',
                  style: GoogleFonts.lemonada(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showClearOptions(context, isIncome: true),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.file_upload_off, color: Colors.orange.shade800),
                title: Text(
                  'مسح سجل المصروفات',
                  style: GoogleFonts.lemonada(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showClearOptions(context, isIncome: false),
              ),
            ),
            const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.red[50],
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                title: Text(
                  'مسح كل البيانات',
                  style: GoogleFonts.lemonada(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'حذف جميع السجلات والأرصدة بشكل نهائي',
                  style: GoogleFonts.lemonada(),
                ),
                onTap: () async {
                  await onClearAllData();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
