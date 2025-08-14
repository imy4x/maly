import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_models.dart';

class SavingsGoalsPage extends StatefulWidget {
  final List<SavingsGoal> savingsGoals;
  final List<String> currencySymbols;
  final Map<String, double> currentBalances;
  final Function(SavingsGoal) onAddGoal;
  final Function(String) onDeleteGoal;
  final Function(String, double) onAddFunds;
    final Future<bool?> Function({
    required BuildContext context,
    required String title,
    required String content,
  }) showConfirmationDialog;
  final String Function(double) formatWithCommas;


  const SavingsGoalsPage({
    super.key,
    required this.savingsGoals,
    required this.currencySymbols,
    required this.currentBalances,
    required this.onAddGoal,
    required this.onDeleteGoal,
    required this.onAddFunds,
    required this.showConfirmationDialog,
    required this.formatWithCommas,
  });

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {

  void _showAddGoalDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _amountController = TextEditingController();
    String? _selectedCurrency = widget.currencySymbols.isNotEmpty ? widget.currencySymbols.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إضافة هدف جديد', style: GoogleFonts.lemonada(fontWeight: FontWeight.bold)),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الهدف',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'الرجاء إدخال اسم الهدف' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'المبلغ المستهدف',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'العملة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_exchange_outlined),
                    ),
                    items: widget.currencySymbols.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.lemonada()));
                    }).toList(),
                    onChanged: (String? newValue) => _selectedCurrency = newValue,
                    validator: (value) => value == null ? 'الرجاء اختيار العملة' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: GoogleFonts.lemonada(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newGoal = SavingsGoal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      targetAmount: double.parse(_amountController.text),
                      currency: _selectedCurrency!,
                      creationDate: DateTime.now(),
                    );
                    widget.onAddGoal(newGoal);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('إضافة', style: GoogleFonts.lemonada(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddFundsDialog(SavingsGoal goal) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إضافة أموال إلى: ${goal.name}', style: GoogleFonts.lemonada(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: goal.currency,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح';
                  
                  final balance = widget.currentBalances[goal.currency] ?? 0.0;
                  if (amount > balance) {
                    return 'الرصيد غير كافِ: ${widget.formatWithCommas(balance)}';
                  }

                  if(goal.currentAmount + amount > goal.targetAmount) {
                    return 'المبلغ يتجاوز الهدف!';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: GoogleFonts.lemonada(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                     final confirmed = await widget.showConfirmationDialog(
                        context: context,
                        title: 'تأكيد إضافة أموال',
                        content: 'سيتم خصم المبلغ من رصيدك وإضافته للهدف. هل تريد المتابعة؟',
                    );
                    if (confirmed == true) {
                        widget.onAddFunds(goal.id, double.parse(_amountController.text));
                        Navigator.of(context).pop();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('إضافة', style: GoogleFonts.lemonada(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main content of the page, without a Scaffold wrapper
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Title and Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'الأهداف المالية',
                  style: GoogleFonts.lemonada(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('هدف جديد', style: GoogleFonts.lemonada(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Goals List
            Expanded(
              child: widget.savingsGoals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد أهداف حالياً.',
                            style: GoogleFonts.lemonada(fontSize: 18, color: Colors.grey[600]),
                          ),
                          Text(
                            'أضف هدفك الأول للادخار!',
                            style: GoogleFonts.lemonada(fontSize: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.savingsGoals.length,
                      itemBuilder: (context, index) {
                        final goal = widget.savingsGoals[index];
                        final progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
                        final isCompleted = progress >= 1.0;
                        final remainingAmount = goal.targetAmount - goal.currentAmount;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias, // To prevent splash effects from leaking
                          color: isCompleted ? Colors.green.shade50 : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goal.name,
                                        style: GoogleFonts.lemonada(fontWeight: FontWeight.bold, fontSize: 18, color: isCompleted ? Colors.green.shade800 : Colors.black87),
                                      ),
                                    ),
                                    if (!isCompleted)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                        onPressed: () => widget.onDeleteGoal(goal.id),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تاريخ الإنشاء: ${goal.creationDate.day}/${goal.creationDate.month}/${goal.creationDate.year}',
                                  style: GoogleFonts.lemonada(color: Colors.grey[500], fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 12,
                                        borderRadius: BorderRadius.circular(6),
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.blue.shade700),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.lemonada(fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade800 : Colors.blue.shade800, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoChip('المدخر', widget.formatWithCommas(goal.currentAmount), goal.currency, Colors.blue),
                                    _buildInfoChip('المتبقي', widget.formatWithCommas(remainingAmount > 0 ? remainingAmount : 0), goal.currency, Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: _buildInfoChip('الهدف الكلي', widget.formatWithCommas(goal.targetAmount), goal.currency, Colors.grey),
                                ),
                                
                                const Divider(height: 24),
                                
                                Center(
                                  child: isCompleted
                                      ? Text(
                                          '🎉 مكتمل!',
                                          style: GoogleFonts.lemonada(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                        )
                                      : ElevatedButton.icon(
                                          icon: const Icon(Icons.add_card_outlined),
                                          label: Text('إضافة أموال', style: GoogleFonts.lemonada()),
                                          onPressed: () => _showAddFundsDialog(goal),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.green.shade600,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                ),
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
    );
  }

  Widget _buildInfoChip(String label, String amount, String currency, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: GoogleFonts.lemonada(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '$amount $currency',
          style: GoogleFonts.lemonada(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 14),
        ),
      ],
    );
  }
}
