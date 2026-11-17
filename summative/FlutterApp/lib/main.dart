
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RevenuePredictionApp());
}

class RevenuePredictionApp extends StatelessWidget {
  const RevenuePredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retail Revenue Predictor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167A5E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF167A5E),
              width: 2,
            ),
          ),
        ),
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _countryController =
      TextEditingController(text: 'Australia');

  final TextEditingController _historyController =
      TextEditingController();

  DateTime _selectedDate = DateTime(2011, 8, 15);

  bool _isLoading = false;
  String? _prediction;
  String? _errorMessage;

  static const String apiUrl =
      'https://linear-regression-model-smp6.onrender.com/predict';

  @override
  void dispose() {
    _countryController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    return '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
  }

  // Read 30 daily revenue values entered by the user.
  // The order must be oldest to newest.
  List<double>? _readRevenueValues() {
    final values = _historyController.text
        .split(RegExp(r'[\s,;]+'))
        .where((value) => value.trim().isNotEmpty)
        .map((value) => double.tryParse(value.trim()))
        .toList();

    if (values.length != 30 || values.any((value) => value == null)) {
      return null;
    }

    final result = values.cast<double>();

    if (result.any((value) => !value.isFinite || value < 0)) {
      return null;
    }

    return result;
  }

  String? _validateHistory(String? value) {
    final revenues = _readRevenueValues();

    if (value == null || value.trim().isEmpty) {
      return 'Enter the previous 30 daily revenue amounts.';
    }

    if (revenues == null) {
      return 'Enter exactly 30 valid, non-negative numbers.';
    }

    return null;
  }

  Future<void> _chooseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2009, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Choose the prediction date',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _prediction = null;
        _errorMessage = null;
      });
    }
  }

  double _average(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF167A5E), size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF52675E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF124D43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview() {
    final revenues = _readRevenueValues();

    if (revenues == null) {
      return const SizedBox.shrink();
    }

    final lag1 = revenues[29];
    final lag7 = revenues[23];
    final rolling7 = _average(revenues.sublist(23));
    final rolling30 = _average(revenues);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Calculated historical features',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            _featureTile('Revenue 1 day ago', '£${lag1.toStringAsFixed(2)}'),
            _featureTile('Revenue 7 days ago', '£${lag7.toStringAsFixed(2)}'),
            _featureTile('7-day average', '£${rolling7.toStringAsFixed(2)}'),
            _featureTile('30-day average', '£${rolling30.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Future<void> _predictRevenue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final revenues = _readRevenueValues()!;

    // Python weekday numbering: Monday = 0, Sunday = 6.
    final dayOfWeek = _selectedDate.weekday % 7;

    final lag1 = revenues[29];
    final lag7 = revenues[23];
    final rolling7 = _average(revenues.sublist(23));
    final rolling30 = _average(revenues);

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    try {
      final requestBody = {
        'Country': _countryController.text.trim(),
        'Year': _selectedDate.year,
        'Month': _selectedDate.month,
        'Day': _selectedDate.day,
        'DayOfWeek': dayOfWeek,
        'IsWeekend': dayOfWeek == 5 || dayOfWeek == 6,
        'Lag1Day': lag1,
        'Lag7Days': lag7,
        'Rolling7Days': rolling7,
        'Rolling30Days': rolling30,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 90));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final revenue =
            (responseData['predicted_daily_revenue'] as num).toDouble();

        if (!mounted) return;

        setState(() {
          _prediction = '£${revenue.toStringAsFixed(2)}';
        });
      } else {
        final details = responseData['detail'];

        String message = 'The prediction request failed.';

        if (details is List) {
          message = details
              .map((item) => item['msg']?.toString() ?? 'Invalid input')
              .join('\n');
        } else if (details is String) {
          message = details;
        }

        if (!mounted) return;

        setState(() {
          _errorMessage = message;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not connect to the prediction API. Check your internet connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenues = _readRevenueValues();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Retail Predictor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF124D43),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF124D43),
                        Color(0xFF23866A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.insights,
                        color: Colors.white,
                        size: 38,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Predict your daily revenue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Use historical sales information to estimate your next day’s revenue.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeading(
                          'Business information',
                          'Choose the country and prediction date.',
                          Icons.storefront,
                        ),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.public),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a country';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _chooseDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Text('Prediction date: $_formattedDate'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            foregroundColor: const Color(0xFF167A5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  elevation: 1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeading(
                          'Historical daily revenue',
                          'Enter the 30 days immediately before your prediction date.',
                          Icons.history,
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Enter 30 amounts from oldest to newest. '
                            'Put one amount on each line. Include 0 for days with no sales.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF76551C),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _historyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          minLines: 8,
                          maxLines: 12,
                          onChanged: (_) {
                            setState(() {
                              _prediction = null;
                              _errorMessage = null;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Previous 30 daily revenues (£)',
                            hintText:
                                'Example format:\n'
                                '850.00\n'
                                '920.50\n'
                                '0\n'
                                '1100.00\n'
                                '...',
                            alignLabelWithHint: true,
                          ),
                          validator: _validateHistory,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          revenues == null
                              ? 'Enter exactly 30 valid amounts.'
                              : '30 of 30 daily amounts entered.',
                          style: TextStyle(
                            color: revenues == null
                                ? Colors.grey.shade600
                                : const Color(0xFF167A5E),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        _buildFeaturePreview(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: _isLoading ? null : _predictRevenue,
                  icon: const Icon(Icons.auto_graph),
                  label: Text(
                    _isLoading ? 'Predicting revenue...' : 'Predict Revenue',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF167A5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Text(
                    'Contacting the prediction service...',
                    textAlign: TextAlign.center,
                  ),
                ],

                if (_prediction != null) ...[
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFFE5F4EC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF167A5E),
                            size: 42,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Predicted Daily Revenue',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _prediction!,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF124D43),
                            ),
                          ),
                          const Text(
                            'Currency: GBP',
                            style: TextStyle(color: Color(0xFF52675E)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Country: ${_countryController.text.trim()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Card(
                    color: const Color(0xFFFFE9E7),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Text(
                  'Powered by a Random Forest machine learning model',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
