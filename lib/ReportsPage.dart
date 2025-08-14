import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_models.dart';
import 'SourceDetailsPage.dart';

class ExpenseSourceSummary {
  final String source;
  final double totalAmount;
  final List<ExpenseEntry> entries;

  ExpenseSourceSummary({
    required this.source,
    required this.totalAmount,
    required this.entries,
  });
}

class ReportsPage extends StatefulWidget {
  final List<IncomeEntry> incomeEntries;
  final List<ExpenseEntry> expenseEntries;

  const ReportsPage({
    super.key,
    required this.incomeEntries,
    required this.expenseEntries,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late DateTime _selectedDate;
  String _activeFilter = 'أسبوعي';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

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

  void _changeDate(bool isNext) {
    setState(() {
      if (_activeFilter == 'شهري') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + (isNext ? 1 : -1), 1);
      } else {
        _selectedDate = _selectedDate.add(Duration(days: isNext ? 7 : -7));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _buildReportView(),
      ),
    );
  }

  Widget _buildReportView() {
    List<ExpenseEntry> periodExpenses;
    String periodTitle;

    if (_activeFilter == 'شهري') {
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      periodExpenses = widget.expenseEntries.where((e) => e.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) && e.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();
      periodTitle = 'شهر ${_selectedDate.month}، ${_selectedDate.year}';
    } else {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      periodExpenses = widget.expenseEntries.where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && e.date.isBefore(endOfWeek.add(const Duration(days: 1)))).toList();
      periodTitle = 'أسبوع: ${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
    }
    
    Map<String, ExpenseSourceSummary> sourceMap = {};
    for (var expense in periodExpenses) {
      if (sourceMap.containsKey(expense.source)) {
        sourceMap[expense.source]!.entries.add(expense);
        sourceMap.update(expense.source, (value) => ExpenseSourceSummary(
          source: expense.source,
          totalAmount: value.totalAmount + expense.amount,
          entries: value.entries,
        ));
      } else {
        sourceMap[expense.source] = ExpenseSourceSummary(
          source: expense.source,
          totalAmount: expense.amount,
          entries: [expense],
        );
      }
    }

    final sortedSources = sourceMap.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'تقارير المصروفات',
            style: GoogleFonts.lemonada(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        _buildFilterButtons(),
        _buildDateNavigator(periodTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'المصادر الأكثر إنفاقاً:',
            style: GoogleFonts.lemonada(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: sortedSources.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد مصروفات في هذه الفترة.',
                    style: GoogleFonts.lemonada(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _buildExpenseSourceList(sortedSources),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip('أسبوعي'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterChip('شهري'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _activeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = label;
          });
        }
      },
      labelStyle: GoogleFonts.lemonada(color: isSelected ? Colors.white : Colors.black87),
      selectedColor: Colors.blue.shade700,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildDateNavigator(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _changeDate(false),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lemonada(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => _changeDate(true),
        ),
      ],
    );
  }

  Widget _buildExpenseSourceList(List<ExpenseSourceSummary> sources) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final sourceSummary = sources[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              sourceSummary.source,
              style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${_formatWithCommas(sourceSummary.totalAmount)} ر.ي',
              style: GoogleFonts.lemonada(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SourceDetailsPage(
                    sourceName: sourceSummary.source,
                    expenseEntries: sourceSummary.entries,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
