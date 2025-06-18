import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class PaymentReconciliationScreen extends StatefulWidget {
  const PaymentReconciliationScreen({Key? key}) : super(key: key);

  @override
  State<PaymentReconciliationScreen> createState() => _PaymentReconciliationScreenState();
}

class _PaymentReconciliationScreenState extends State<PaymentReconciliationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PaymentSummary? _paymentSummary;
  List<Transaction> _transactions = [];
  List<ReconciliationReport> _reports = [];
  List<PaymentDispute> _disputes = [];
  bool _isLoading = true;
  String _selectedPeriod = '30d';
  String _statusFilter = 'all';
  String _paymentMethodFilter = 'all';

  final List<String> _periods = ['7d', '30d', '90d', '1y'];
  final List<String> _periodLabels = ['7 Days', '30 Days', '90 Days', '1 Year'];
  final List<String> _statusFilters = ['all', 'completed', 'pending', 'failed', 'disputed'];
  final List<String> _paymentMethods = ['all', 'mpesa', 'card', 'cash'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.adminPaymentsSummary(period: _selectedPeriod)),
        ApiService.get(ApiEndpoints.adminPaymentsTransactions(
          status: _statusFilter, 
          method: _paymentMethodFilter
        )),
        ApiService.get(ApiEndpoints.adminPaymentsReconciliationReports),
        ApiService.get(ApiEndpoints.adminPaymentsDisputes),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final summaryData = json.decode(responses[0].body);
        final transactionsData = json.decode(responses[1].body);
        final reportsData = json.decode(responses[2].body);
        final disputesData = json.decode(responses[3].body);
        
        setState(() {
          _paymentSummary = PaymentSummary.fromJson(summaryData['summary']);
          _transactions = (transactionsData['transactions'] as List)
              .map((t) => Transaction.fromJson(t))
              .toList();
          _reports = (reportsData['reports'] as List)
              .map((r) => ReconciliationReport.fromJson(r))
              .toList();
          _disputes = (disputesData['disputes'] as List)
              .map((d) => PaymentDispute.fromJson(d))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load payment data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runReconciliation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Reconciliation'),
        content: const Text('This will reconcile all pending transactions with M-Pesa records. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeReconciliation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Run', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeReconciliation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.post(
        ApiEndpoints.adminPaymentsReconcile,
        {
          'period': _selectedPeriod,
          'method': _paymentMethodFilter,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reconciliation completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPaymentData();
        }
      } else {
        throw Exception('Failed to run reconciliation');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running reconciliation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Payment Reconciliation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadPaymentData();
            },
            itemBuilder: (context) => _periods.map((period) {
              final index = _periods.indexOf(period);
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    if (_selectedPeriod == period)
                      const Icon(Icons.check, color: Colors.green),
                    if (_selectedPeriod == period)
                      const SizedBox(width: 8),
                    Text(_periodLabels[index]),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadPaymentData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Transactions', icon: Icon(Icons.payment)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
            Tab(text: 'Disputes', icon: Icon(Icons.report_problem)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTransactionsTab(),
                _buildReportsTab(),
                _buildDisputesTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadPaymentData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentSummary(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildPaymentMethodBreakdown(),
            const SizedBox(height: 16),
            _buildTransactionChart(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    if (_paymentSummary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF2E7D32).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Payment Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _paymentSummary!.reconciliationStatus == 'up_to_date' 
                        ? Colors.green 
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _paymentSummary!.reconciliationStatus == 'up_to_date' 
                        ? 'RECONCILED' 
                        : 'NEEDS RECONCILIATION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Volume',
                    'KSh ${NumberFormat('#,###').format(_paymentSummary!.totalVolume)}',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Transactions',
                    NumberFormat('#,###').format(_paymentSummary!.totalTransactions),
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Success Rate',
                    '${_paymentSummary!.successRate.toStringAsFixed(1)}%',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Disputed',
                    'KSh ${NumberFormat('#,###').format(_paymentSummary!.disputedAmount)}',
                    Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runReconciliation,
                    icon: const Icon(Icons.sync),
                    label: const Text('Run Reconciliation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(),
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown() {
    if (_paymentSummary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _paymentSummary!.mpesaPercentage,
                      title: 'M-Pesa\n${_paymentSummary!.mpesaPercentage.toStringAsFixed(1)}%',
                      color: const Color(0xFF00D632),
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    PieChartSectionData(
                      value: _paymentSummary!.cardPercentage,
                      title: 'Cards\n${_paymentSummary!.cardPercentage.toStringAsFixed(1)}%',
                      color: Colors.blue,
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    PieChartSectionData(
                      value: _paymentSummary!.cashPercentage,
                      title: 'Cash\n${_paymentSummary!.cashPercentage.toStringAsFixed(1)}%',
                      color: Colors.orange,
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionChart() {
    if (_paymentSummary?.chartData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Volume Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _paymentSummary!.chartLabels.length) {
                            return Text(_paymentSummary!.chartLabels[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _paymentSummary!.chartData
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF2E7D32),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadPaymentData(),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Transactions (${_transactions.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_statusFilter.toUpperCase()),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  itemBuilder: (context) => _statusFilters.map((status) {
                    return PopupMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onSelected: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    _loadPaymentData();
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_paymentMethodFilter.toUpperCase()),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  itemBuilder: (context) => _paymentMethods.map((method) {
                    return PopupMenuItem(
                      value: method,
                      child: Text(method.toUpperCase()),
                    );
                  }).toList(),
                  onSelected: (value) {
                    setState(() {
                      _paymentMethodFilter = value!;
                    });
                    _loadPaymentData();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    Color statusColor;
    IconData statusIcon;
    
    switch (transaction.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'disputed':
        statusColor = Colors.purple;
        statusIcon = Icons.report_problem;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${transaction.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Txn: ${transaction.transactionId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTransactionDetail(
                    'Amount',
                    'KSh ${NumberFormat('#,###').format(transaction.amount)}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildTransactionDetail(
                    'Method',
                    transaction.paymentMethod.toUpperCase(),
                    _getPaymentMethodIcon(transaction.paymentMethod),
                    _getPaymentMethodColor(transaction.paymentMethod),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTransactionDetail(
                    'Date',
                    DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt),
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTransactionDetail(
                    'Customer',
                    transaction.customerName,
                    Icons.person,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (transaction.mpesaReceiptNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'M-Pesa Receipt: ${transaction.mpesaReceiptNumber}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (transaction.status.toLowerCase() == 'failed' && transaction.failureReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failure Reason: ${transaction.failureReason}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'mpesa':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'mpesa':
        return const Color(0xFF00D632);
      case 'card':
        return Colors.blue;
      case 'cash':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadPaymentData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(ReconciliationReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reconciliation Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(report.reportDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildReportMetric(
                    'Matched',
                    report.matchedTransactions.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildReportMetric(
                    'Unmatched',
                    report.unmatchedTransactions.toString(),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildReportMetric(
                    'Discrepancies',
                    report.discrepancies.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Amount Reconciled: KSh ${NumberFormat('#,###').format(report.reconciledAmount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (report.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${report.notes}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputesTab() {
    return RefreshIndicator(
      onRefresh: () => _loadPaymentData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _disputes.length,
        itemBuilder: (context, index) {
          final dispute = _disputes[index];
          return _buildDisputeCard(dispute);
        },
      ),
    );
  }

  Widget _buildDisputeCard(PaymentDispute dispute) {
    Color statusColor;
    switch (dispute.status.toLowerCase()) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'escalated':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.report_problem, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispute #${dispute.disputeId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Order: ${dispute.orderId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dispute.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Type: ${dispute.disputeType}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Amount: KSh ${NumberFormat('#,###').format(dispute.amount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dispute.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Created: ${DateFormat('MMM dd, yyyy').format(dispute.createdAt)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) {
              final activities = [
                'Reconciliation completed - 150 transactions matched',
                'New dispute raised for Order #12345',
                'M-Pesa payment KSh 2,500 confirmed'
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activities[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting payment reconciliation report...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class PaymentSummary {
  final double totalVolume;
  final int totalTransactions;
  final double successRate;
  final double disputedAmount;
  final String reconciliationStatus;
  final double mpesaPercentage;
  final double cardPercentage;
  final double cashPercentage;
  final List<double> chartData;
  final List<String> chartLabels;

  PaymentSummary({
    required this.totalVolume,
    required this.totalTransactions,
    required this.successRate,
    required this.disputedAmount,
    required this.reconciliationStatus,
    required this.mpesaPercentage,
    required this.cardPercentage,
    required this.cashPercentage,
    required this.chartData,
    required this.chartLabels,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      successRate: (json['successRate'] ?? 0).toDouble(),
      disputedAmount: (json['disputedAmount'] ?? 0).toDouble(),
      reconciliationStatus: json['reconciliationStatus'] ?? '',
      mpesaPercentage: (json['mpesaPercentage'] ?? 0).toDouble(),
      cardPercentage: (json['cardPercentage'] ?? 0).toDouble(),
      cashPercentage: (json['cashPercentage'] ?? 0).toDouble(),
      chartData: List<double>.from(json['chartData'] ?? []),
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
    );
  }
}

class Transaction {
  final String transactionId;
  final String orderId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String customerName;
  final DateTime createdAt;
  final String mpesaReceiptNumber;
  final String failureReason;

  Transaction({
    required this.transactionId,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.customerName,
    required this.createdAt,
    required this.mpesaReceiptNumber,
    required this.failureReason,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      customerName: json['customerName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      mpesaReceiptNumber: json['mpesaReceiptNumber'] ?? '',
      failureReason: json['failureReason'] ?? '',
    );
  }
}

class ReconciliationReport {
  final String reportId;
  final DateTime reportDate;
  final int matchedTransactions;
  final int unmatchedTransactions;
  final int discrepancies;
  final double reconciledAmount;
  final String notes;

  ReconciliationReport({
    required this.reportId,
    required this.reportDate,
    required this.matchedTransactions,
    required this.unmatchedTransactions,
    required this.discrepancies,
    required this.reconciledAmount,
    required this.notes,
  });

  factory ReconciliationReport.fromJson(Map<String, dynamic> json) {
    return ReconciliationReport(
      reportId: json['reportId'] ?? '',
      reportDate: DateTime.parse(json['reportDate'] ?? DateTime.now().toIso8601String()),
      matchedTransactions: json['matchedTransactions'] ?? 0,
      unmatchedTransactions: json['unmatchedTransactions'] ?? 0,
      discrepancies: json['discrepancies'] ?? 0,
      reconciledAmount: (json['reconciledAmount'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
    );
  }
}

class PaymentDispute {
  final String disputeId;
  final String orderId;
  final String disputeType;
  final double amount;
  final String description;
  final String status;
  final DateTime createdAt;

  PaymentDispute({
    required this.disputeId,
    required this.orderId,
    required this.disputeType,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory PaymentDispute.fromJson(Map<String, dynamic> json) {
    return PaymentDispute(
      disputeId: json['disputeId'] ?? '',
      orderId: json['orderId'] ?? '',
      disputeType: json['disputeType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 