import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'IncomePage.dart';
import 'ExpensesPage.dart';
import 'SavingsGoalsPage.dart'; // New Page
import 'ReportsPage.dart';
import 'data_models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'SettingsPage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _ConversionDialog extends StatefulWidget {
  final _MainScreenState mainScreenState;

  const _ConversionDialog({required this.mainScreenState});

  @override
  _ConversionDialogState createState() => _ConversionDialogState();
}

class _ConversionDialogState extends State<_ConversionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fromAmountController;
  late TextEditingController _exchangeRateController;
  late TextEditingController _toAmountController;

  String? _fromCurrency;
  String? _toCurrency;

  @override
  void initState() {
    super.initState();
    _fromAmountController = TextEditingController();
    _exchangeRateController = TextEditingController();
    _toAmountController = TextEditingController();

    _fromCurrency = widget.mainScreenState._currencySymbols.values.isNotEmpty
        ? widget.mainScreenState._currencySymbols.values.first
        : null;
    _toCurrency = widget.mainScreenState._currencySymbols.values.length > 1
        ? widget.mainScreenState._currencySymbols.values.toList()[1]
        : null;

    _fromAmountController.addListener(_calculateToAmount);
    _exchangeRateController.addListener(_calculateToAmount);
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_calculateToAmount);
    _exchangeRateController.removeListener(_calculateToAmount);
    _fromAmountController.dispose();
    _exchangeRateController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  void _calculateToAmount() {
    final mainState = widget.mainScreenState;
    final double? fromAmount = double.tryParse(_fromAmountController.text);
    final double? exchangeRate = double.tryParse(_exchangeRateController.text);

    if (fromAmount != null && exchangeRate != null && _fromCurrency != null && _toCurrency != null) {
      final fromRank = mainState._currencyRanks[_fromCurrency!] ?? 0;
      final toRank = mainState._currencyRanks[_toCurrency!] ?? 0;
      double toAmount = 0;

      if (fromRank < toRank) {
        toAmount = fromAmount / exchangeRate;
      } else {
        toAmount = fromAmount * exchangeRate;
      }
      _toAmountController.text = mainState._formatWithCommas(toAmount);
    } else {
      _toAmountController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainState = widget.mainScreenState;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'تحويل عملة',
          style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fromAmountController,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المحول',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح أكبر من صفر';
                    
                    final balance = mainState._currentBalances[_fromCurrency] ?? 0.0;
                    if (amount > balance) {
                      return 'الرصيد غير كافِ: ${mainState._formatWithCommas(balance)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _fromCurrency,
                  decoration: InputDecoration(
                    labelText: 'من عملة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.arrow_upward),
                  ),
                  items: mainState._currencySymbols.values.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.lemonada()));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _fromCurrency = newValue;
                      _calculateToAmount();
                      _formKey.currentState?.validate();
                    });
                  },
                  validator: (value) => value == null ? 'الرجاء اختيار العملة' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _exchangeRateController,
                  decoration: InputDecoration(
                    labelText: 'سعر الصرف',
                    helperText: 'مثال: 1 دولار = 550 ريال يمني',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.swap_horiz),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال سعر الصرف';
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) return 'سعر الصرف يجب أن يكون أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _toCurrency,
                  decoration: InputDecoration(
                    labelText: 'إلى عملة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.arrow_downward),
                  ),
                  items: mainState._currencySymbols.values.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.lemonada()));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _toCurrency = newValue;
                      _calculateToAmount();
                      _formKey.currentState?.validate();
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'الرجاء اختيار العملة';
                    if (value == _fromCurrency) return 'لا يمكن التحويل لنفس العملة';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toAmountController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المستلم',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('إلغاء', style: GoogleFonts.lemonada(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final confirmed = await mainState._showConfirmationDialog(
                  context: context,
                  title: 'تأكيد التحويل',
                  content: 'هل أنت متأكد من إتمام عملية التحويل هذه؟',
                );
                if (confirmed == true) {
                  final double fromAmount = double.parse(_fromAmountController.text);
                  final double toAmount = double.parse(_toAmountController.text.replaceAll(',', ''));

                  final expenseEntry = ExpenseEntry(
                    id: 'conv_exp_${DateTime.now().millisecondsSinceEpoch}',
                    amount: fromAmount,
                    source: 'تحويل إلى $_toCurrency',
                    reason: 'تحويل عملة',
                    date: DateTime.now(),
                    currency: _fromCurrency!,
                  );
                  mainState._addExpense(expenseEntry);

                  final incomeEntry = IncomeEntry(
                    id: 'conv_inc_${DateTime.now().millisecondsSinceEpoch}',
                    amount: toAmount,
                    source: 'تحويل من $_fromCurrency',
                    reason: 'تحويل عملة',
                    date: DateTime.now(),
                    currency: _toCurrency!,
                  );
                  mainState._addIncome(incomeEntry);
                  
                  if(mounted) Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('تحويل', style: GoogleFonts.lemonada(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final Map<String, String> _currencySymbols = {'YER': 'ر.ي', 'SAR': 'ر.س', 'USD': '\$'};
  final Map<String, String> _currencyFullNames = {
    'YER': 'الريال اليمني',
    'SAR': 'الريال السعودي',
    'USD': 'الدولار الأمريكي'
  };
  final Map<String, int> _currencyRanks = {'ر.ي': 1, 'ر.س': 2, '\$': 3};

  List<IncomeEntry> _incomeEntries = [];
  List<ExpenseEntry> _expenseEntries = [];
  List<SavingsGoal> _savingsGoals = []; 
  Map<String, double> _currentBalances = {'ر.ي': 0.0, 'ر.س': 0.0, '\$': 0.0};


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications().then((_) {
      _loadData().then((_) {
        _scheduleDailyNotification();
      });
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleDailyNotification() async {
    final String timeZoneName = tz.local.name;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation(timeZoneName));
    
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 22);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'هل نسيت شيئاً؟',
        'هل صرفت شيئاً اليوم؟ سجله الآن في Maly!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'daily_notification_channel_id',
              'Daily Notifications',
              channelDescription: 'Daily reminder to log expenses',
              importance: Importance.max,
              priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final balancesString = prefs.getString('currentBalances');
      if (balancesString != null) {
        final decodedBalances = jsonDecode(balancesString) as Map<String, dynamic>;
        setState(() {
          _currentBalances = decodedBalances.map((key, value) => MapEntry(key, (value as num).toDouble()));
        });
      }

      final incomeEntriesString = prefs.getString('incomeEntries');
      if (incomeEntriesString != null) {
        final List<dynamic> jsonList = jsonDecode(incomeEntriesString);
        setState(() {
          _incomeEntries = jsonList.map((json) => IncomeEntry.fromJson(json)).toList();
        });
      }

      final expenseEntriesString = prefs.getString('expenseEntries');
      if (expenseEntriesString != null) {
        final List<dynamic> jsonList = jsonDecode(expenseEntriesString);
        setState(() {
          _expenseEntries = jsonList.map((json) => ExpenseEntry.fromJson(json)).toList();
        });
      }

      final savingsGoalsString = prefs.getString('savingsGoals');
      if (savingsGoalsString != null) {
        final List<dynamic> jsonList = jsonDecode(savingsGoalsString);
        setState(() {
          _savingsGoals = jsonList.map((json) => SavingsGoal.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentBalances', jsonEncode(_currentBalances));
      await prefs.setString('incomeEntries', jsonEncode(_incomeEntries.map((e) => e.toJson()).toList()));
      await prefs.setString('expenseEntries', jsonEncode(_expenseEntries.map((e) => e.toJson()).toList()));
      await prefs.setString('savingsGoals', jsonEncode(_savingsGoals.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _clearIncomeData(bool adjustBalance) async {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: 'تأكيد مسح سجل الدخل',
      content: 'هل أنت متأكد من رغبتك في مسح جميع سجلات الدخل؟ ${adjustBalance ? 'سيتم خصم المبالغ من رصيدك.' : 'لن يتأثر الرصيد الحالي.'}',
    );
    if (confirmed == true) {
      setState(() {
        if (adjustBalance) {
          for (var entry in _incomeEntries) {
            _currentBalances.update(entry.currency, (value) => value - entry.amount, ifAbsent: () => -entry.amount);
          }
        }
        _incomeEntries.clear();
      });
      await _saveData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح سجلات الدخل بنجاح.', style: GoogleFonts.lemonada()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearExpenseData(bool adjustBalance) async {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: 'تأكيد مسح سجل المصروفات',
      content: 'هل أنت متأكد من رغبتك في مسح جميع سجلات المصروفات؟ ${adjustBalance ? 'سيتم إرجاع المبالغ إلى رصيدك.' : 'لن يتأثر الرصيد الحالي.'}',
    );
    if (confirmed == true) {
      setState(() {
        if (adjustBalance) {
           for (var entry in _expenseEntries) {
            _currentBalances.update(entry.currency, (value) => value + entry.amount, ifAbsent: () => entry.amount);
          }
        }
        _expenseEntries.clear();
      });
      await _saveData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح سجلات المصروفات بنجاح.', style: GoogleFonts.lemonada()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: 'تأكيد مسح كل البيانات',
      content: 'هل أنت متأكد من رغبتك في مسح جميع السجلات والأرصدة والأهداف؟ لا يمكن التراجع عن هذا الإجراء.',
    );
    if (confirmed == true) {
      setState(() {
        _incomeEntries.clear();
        _expenseEntries.clear();
        _savingsGoals.clear();
        _currentBalances = {'ر.ي': 0.0, 'ر.س': 0.0, '\$': 0.0};
      });
      await _saveData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح جميع البيانات بنجاح.', style: GoogleFonts.lemonada()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  void _addIncome(IncomeEntry entry) {
    setState(() {
      _incomeEntries.insert(0, entry);
      _currentBalances.update(entry.currency, (value) => value + entry.amount, ifAbsent: () => entry.amount);
    });
    _saveData();
  }
  
  void _deleteIncome(String id) {
    final entryIndex = _incomeEntries.indexWhere((e) => e.id == id);
    if (entryIndex == -1) return;

    final entry = _incomeEntries[entryIndex];
    setState(() {
      _currentBalances.update(entry.currency, (value) => value - entry.amount);
      _incomeEntries.removeAt(entryIndex);
    });
    _saveData();
  }
  
  void _addExpense(ExpenseEntry entry) {
    setState(() {
      _expenseEntries.insert(0, entry);
      _currentBalances.update(entry.currency, (value) => value - entry.amount, ifAbsent: () => -entry.amount);
    });
    _saveData();
  }

  void _deleteExpense(String id) {
    final entryIndex = _expenseEntries.indexWhere((e) => e.id == id);
    if (entryIndex == -1) return;

    final entry = _expenseEntries[entryIndex];
    setState(() {
      _currentBalances.update(entry.currency, (value) => value + entry.amount);
      _expenseEntries.removeAt(entryIndex);
    });
    _saveData();
  }
  
  void _addSavingsGoal(SavingsGoal goal) {
    setState(() {
      _savingsGoals.insert(0, goal);
    });
    _saveData();
  }

  void _deleteSavingsGoal(String id) {
    final goalIndex = _savingsGoals.indexWhere((g) => g.id == id);
    if (goalIndex == -1) return;

    final goal = _savingsGoals[goalIndex];
    
    if (goal.currentAmount > 0) {
       final incomeEntry = IncomeEntry(
        id: 'goal_refund_${DateTime.now().millisecondsSinceEpoch}',
        amount: goal.currentAmount,
        source: 'إلغاء الهدف: ${goal.name}',
        reason: 'إرجاع المبلغ المدخر للرصيد',
        date: DateTime.now(),
        currency: goal.currency,
      );
      _addIncome(incomeEntry);
    }
   
    setState(() {
      _savingsGoals.removeWhere((g) => g.id == id);
    });
    _saveData();
  }
  
  void _addFundsToGoal(String id, double amount) {
    final goalIndex = _savingsGoals.indexWhere((g) => g.id == id);
    if (goalIndex == -1) return;

    final goal = _savingsGoals[goalIndex];

    final expenseEntry = ExpenseEntry(
      id: 'goal_exp_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      source: 'هدف: ${goal.name}',
      reason: 'إضافة أموال للهدف',
      date: DateTime.now(),
      currency: goal.currency,
    );
    _addExpense(expenseEntry);

    setState(() {
      _savingsGoals[goalIndex] = SavingsGoal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount + amount,
        currency: goal.currency,
        creationDate: goal.creationDate,
      );
    });
    _saveData();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إضافة عملية جديدة',
                    style: GoogleFonts.lemonada(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildModalButton(
                        context,
                        'دخل',
                        Icons.add,
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _showAddIncomeDialog();
                        },
                      ),
                      _buildModalButton(
                        context,
                        'مصروف',
                        Icons.remove,
                        Colors.red,
                        () {
                          Navigator.pop(context);
                          _showAddExpenseDialog();
                        },
                      ),
                       _buildModalButton(
                        context,
                        'هدف مالي',
                        Icons.savings,
                        Colors.blue,
                        () {
                          Navigator.pop(context);
                          _onItemTapped(2);
                        },
                      ),
                       _buildModalButton(
                        context,
                        'تحويل',
                        Icons.swap_horiz,
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _showAddConversionDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.lemonada(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showAddIncomeDialog() {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _sourceController = TextEditingController();
    final _reasonController = TextEditingController();

    String? _selectedCurrency = 'ر.ي';

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'إضافة دخل جديد',
              style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.monetization_on),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال المبلغ';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'الرجاء إدخال مبلغ صحيح أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sourceController,
                      decoration: InputDecoration(
                        labelText: 'المصدر',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.business_center),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال المصدر';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: 'السبب (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.currency_exchange),
                      ),
                      items: _currencySymbols.values.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.lemonada()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _selectedCurrency = newValue;
                        }
                      },
                      validator: (value) => value == null ? 'الرجاء اختيار العملة' : null,
                    ),
                  ],
                ),
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
                    final confirmed = await _showConfirmationDialog(
                      context: context,
                      title: 'تأكيد إضافة دخل',
                      content: 'هل أنت متأكد من إضافة هذا الدخل؟',
                    );
                    if (confirmed == true) {
                      final newEntry = IncomeEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        amount: double.parse(_amountController.text),
                        source: _sourceController.text,
                        reason: _reasonController.text,
                        date: DateTime.now(),
                        currency: _selectedCurrency!,
                      );
                      _addIncome(newEntry);
                      Navigator.of(context).pop();
                      _onItemTapped(0);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('إضافة', style: GoogleFonts.lemonada(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _sourceController = TextEditingController();
    final _reasonController = TextEditingController();

    String? _selectedCurrency = 'ر.ي';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  'إضافة مصروف جديد',
                  style: GoogleFonts.lemonada(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'المبلغ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.monetization_on),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال المبلغ';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'الرجاء إدخال مبلغ صحيح أكبر من صفر';
                            }
                            final balance = _currentBalances[_selectedCurrency] ?? 0.0;
                            if (amount > balance) {
                              return 'الرصيد غير كافِ. الحالي: ${_formatWithCommas(balance)}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sourceController,
                          decoration: InputDecoration(
                            labelText: 'المصدر',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.store),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال المصدر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            labelText: 'السبب (اختياري)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: 'العملة',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.currency_exchange),
                          ),
                          items: _currencySymbols.values.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: GoogleFonts.lemonada()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateDialog(() {
                                _selectedCurrency = newValue;
                              });
                              _formKey.currentState?.validate();
                            }
                          },
                          validator: (value) => value == null ? 'الرجاء اختيار العملة' : null,
                        ),
                      ],
                    ),
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
                        final confirmed = await _showConfirmationDialog(
                          context: context,
                          title: 'تأكيد إضافة مصروف',
                          content: 'هل أنت متأكد من إضافة هذا المصروف؟',
                        );
                        if (confirmed == true) {
                          final newEntry = ExpenseEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            amount: double.parse(_amountController.text),
                            source: _sourceController.text,
                            reason: _reasonController.text,
                            date: DateTime.now(),
                            currency: _selectedCurrency!,
                          );
                          _addExpense(newEntry);
                          Navigator.of(context).pop();
                          _onItemTapped(1);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('إضافة', style: GoogleFonts.lemonada(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddConversionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _ConversionDialog(mainScreenState: this);
      },
    );
  }

  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title, style: GoogleFonts.lemonada(fontWeight: FontWeight.bold)),
            content: Text(content, style: GoogleFonts.lemonada()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('إلغاء', style: GoogleFonts.lemonada(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('تأكيد', style: GoogleFonts.lemonada(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageBody() {
    // This is a list of functions that return the page widgets.
    // This avoids creating all pages at once.
    final List<Widget Function()> pageBuilders = [
      () => IncomePage(
            incomeEntries: _incomeEntries,
            onDelete: _deleteIncome,
            showConfirmationDialog: _showConfirmationDialog,
          ),
      () => ExpensesPage(
            expenseEntries: _expenseEntries,
            onDelete: _deleteExpense,
            showConfirmationDialog: _showConfirmationDialog,
          ),
      () => SavingsGoalsPage(
            savingsGoals: _savingsGoals,
            currencySymbols: _currencySymbols.values.toList(),
            currentBalances: _currentBalances,
            onAddGoal: _addSavingsGoal,
            onDeleteGoal: (id) async {
              final confirmed = await _showConfirmationDialog(
                context: context,
                title: 'تأكيد حذف الهدف',
                content: 'هل أنت متأكد من حذف هذا الهدف؟ سيتم إرجاع المبلغ المدخر إلى رصيدك.',
              );
              if (confirmed == true) {
                _deleteSavingsGoal(id);
              }
            },
            onAddFunds: (id, amount) {
              _addFundsToGoal(id, amount);
            },
            showConfirmationDialog: _showConfirmationDialog,
            formatWithCommas: _formatWithCommas,
          ),
      () => ReportsPage(incomeEntries: _incomeEntries, expenseEntries: _expenseEntries),
    ];

    return pageBuilders[_selectedIndex]();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> balances = _currentBalances;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildBalanceHeader(balances),
            Expanded(
              child: _buildPageBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: Icons.attach_money, label: 'دخل', index: 0),
              _buildNavItem(icon: Icons.money_off, label: 'صرفيات', index: 1),
              const SizedBox(width: 48),
              _buildNavItem(icon: Icons.savings, label: 'أهداف', index: 2),
              _buildNavItem(icon: Icons.library_books, label: 'تقارير', index: 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionModal,
        backgroundColor: Colors.blue[600],
        heroTag: "main_fab",
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBalanceHeader(Map<String, double> balances) {
    List<Widget> balanceWidgets = [];
    balances.forEach((currency, amount) {
      balanceWidgets.add(_buildBalanceCard(currency, amount));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.grey[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          onClearAllData: _clearAllData,
                          onClearIncomeData: _clearIncomeData,
                          onClearExpenseData: _clearExpenseData,
                          showConfirmationDialog: _showConfirmationDialog,
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  'الأرصدة الحالية',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.lemonada(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: balanceWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String currencySymbol, double amount) {
    String currencyCode = _currencySymbols.entries.firstWhere((entry) => entry.value == currencySymbol, orElse: () => const MapEntry('', '')).key;
    String fullName = _currencyFullNames[currencyCode] ?? currencySymbol;

    String formattedBalance = _formatWithCommas(amount);
    final cardWidth = MediaQuery.of(context).size.width * 0.75;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(left: 12.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: amount >= 0 ? [Colors.blue.shade800, Colors.blue.shade400] : [Colors.red.shade800, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: amount >= 0 ? Colors.blue.withAlpha(76) : Colors.red.withAlpha(76),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'الرصيد بعملة $fullName',
            style: GoogleFonts.lemonada(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formattedBalance,
              style: GoogleFonts.lemonada(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Expanded( 
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue[600] : Colors.grey[400],
                size: 28,
              ),
              const SizedBox(height: 4),
               FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.lemonada(
                    color: isSelected ? Colors.blue[600] : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
