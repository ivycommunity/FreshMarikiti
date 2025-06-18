import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/vendor_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class EcoReportScreen extends StatefulWidget {
  const EcoReportScreen({Key? key}) : super(key: key);

  @override
  State<EcoReportScreen> createState() => _EcoReportScreenState();
}

class _EcoReportScreenState extends State<EcoReportScreen>
    with TickerProviderStateMixin {
  EcoData? _ecoData;
  List<EcoReward> _availableRewards = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEcoData();
    _loadRewards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEcoData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorEcoReport);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ecoData = EcoData.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load eco data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading eco data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorEcoRewards);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rewardsJson = data['rewards'] ?? [];
        
        setState(() {
          _availableRewards = rewardsJson.map((json) => EcoReward.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently handle rewards loading error
    }
  }

  Future<void> _redeemReward(String rewardId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.post(
        ApiEndpoints.vendorEcoRewardRedeem(rewardId),
        {},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reward redeemed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEcoData();
          _loadRewards();
        }
      } else {
        throw Exception('Failed to redeem reward');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error redeeming reward: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRedeemDialog(EcoReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reward.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.eco, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${reward.pointsCost} Eco Points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your current balance: ${_ecoData?.currentEcoPoints ?? 0} points',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (_ecoData?.currentEcoPoints ?? 0) >= reward.pointsCost
                ? () {
                    Navigator.pop(context);
                    _redeemReward(reward.id);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Eco Impact Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadEcoData();
              _loadRewards();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Impact'),
            Tab(text: 'Points'),
            Tab(text: 'Rewards'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ecoData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadEcoData();
                    await _loadRewards();
                  },
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildImpactTab(),
                      _buildPointsTab(),
                      _buildRewardsTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load eco data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _loadEcoData();
              _loadRewards();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eco Score Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Eco Score',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_ecoData!.ecoScore}/100',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularProgressIndicator(
                        value: _ecoData!.ecoScore / 100,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEcoScoreMessage(_ecoData!.ecoScore),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Impact Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildImpactCard(
                'Waste Reduced',
                '${_ecoData!.wasteReduced.toStringAsFixed(1)} kg',
                Icons.delete_outline,
                Colors.orange,
                'This month',
              ),
              _buildImpactCard(
                'CO₂ Saved',
                '${_ecoData!.carbonSaved.toStringAsFixed(1)} kg',
                Icons.cloud_outlined,
                Colors.blue,
                'Carbon footprint',
              ),
              _buildImpactCard(
                'Water Saved',
                '${_ecoData!.waterSaved.toStringAsFixed(0)} L',
                Icons.water_drop_outlined,
                Colors.cyan,
                'Conservation',
              ),
              _buildImpactCard(
                'Energy Saved',
                '${_ecoData!.energySaved.toStringAsFixed(1)} kWh',
                Icons.bolt_outlined,
                Colors.amber,
                'Efficiency',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sustainability Practices
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sustainability Practices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._ecoData!.sustainabilityPractices.map((practice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: practice.isActive ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            practice.isActive ? Icons.check : Icons.close,
                            color: practice.isActive ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                practice.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                practice.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (practice.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${practice.pointsEarned} pts',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Progress
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._ecoData!.monthlyProgress.map((progress) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(progress.month),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${progress.ecoPoints} points',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress.ecoPoints / (_ecoData!.monthlyProgress.map((p) => p.ecoPoints).reduce((a, b) => a > b ? a : b)),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.wasteReduced.toStringAsFixed(1)} kg waste reduced',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Points Balance
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_ecoData!.currentEcoPoints}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Eco Points',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Points Summary
          Row(
            children: [
              Expanded(
                child: _buildPointsSummaryCard(
                  'Earned This Month',
                  '${_ecoData!.pointsEarnedThisMonth}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsSummaryCard(
                  'Total Earned',
                  '${_ecoData!.totalPointsEarned}',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPointsSummaryCard(
                  'Redeemed',
                  '${_ecoData!.pointsRedeemed}',
                  Icons.redeem,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsSummaryCard(
                  'Next Milestone',
                  '${_ecoData!.nextMilestone}',
                  Icons.flag,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Points History
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Points Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._ecoData!.pointsHistory.take(10).map((transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: transaction.type == 'earned' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            transaction.type == 'earned' ? Icons.add : Icons.remove,
                            color: transaction.type == 'earned' ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${transaction.type == 'earned' ? '+' : '-'}${transaction.points}',
                          style: TextStyle(
                            color: transaction.type == 'earned' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Points
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available for Redemption',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${_ecoData!.currentEcoPoints} Eco Points',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Available Rewards
          const Text(
            'Available Rewards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_availableRewards.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rewards available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep earning eco points to unlock rewards!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableRewards.map((reward) => Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: reward.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            reward.icon,
                            color: reward.color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reward.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.eco, color: Colors.green, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${reward.pointsCost} points',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: (_ecoData!.currentEcoPoints >= reward.pointsCost)
                              ? () => _showRedeemDialog(reward)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            (_ecoData!.currentEcoPoints >= reward.pointsCost)
                                ? 'Redeem'
                                : 'Insufficient Points',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildImpactCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEcoScoreMessage(int score) {
    if (score >= 80) {
      return 'Excellent! You\'re a sustainability champion!';
    } else if (score >= 60) {
      return 'Great work! Keep up the eco-friendly practices.';
    } else if (score >= 40) {
      return 'Good start! There\'s room for improvement.';
    } else {
      return 'Let\'s work together to improve your eco impact!';
    }
  }
}

// Data Models
class EcoData {
  final int ecoScore;
  final double wasteReduced;
  final double carbonSaved;
  final double waterSaved;
  final double energySaved;
  final int currentEcoPoints;
  final int pointsEarnedThisMonth;
  final int totalPointsEarned;
  final int pointsRedeemed;
  final int nextMilestone;
  final List<SustainabilityPractice> sustainabilityPractices;
  final List<MonthlyProgress> monthlyProgress;
  final List<PointsTransaction> pointsHistory;

  EcoData({
    required this.ecoScore,
    required this.wasteReduced,
    required this.carbonSaved,
    required this.waterSaved,
    required this.energySaved,
    required this.currentEcoPoints,
    required this.pointsEarnedThisMonth,
    required this.totalPointsEarned,
    required this.pointsRedeemed,
    required this.nextMilestone,
    required this.sustainabilityPractices,
    required this.monthlyProgress,
    required this.pointsHistory,
  });

  factory EcoData.fromJson(Map<String, dynamic> json) {
    return EcoData(
      ecoScore: json['ecoScore'] ?? 0,
      wasteReduced: (json['wasteReduced'] ?? 0).toDouble(),
      carbonSaved: (json['carbonSaved'] ?? 0).toDouble(),
      waterSaved: (json['waterSaved'] ?? 0).toDouble(),
      energySaved: (json['energySaved'] ?? 0).toDouble(),
      currentEcoPoints: json['currentEcoPoints'] ?? 0,
      pointsEarnedThisMonth: json['pointsEarnedThisMonth'] ?? 0,
      totalPointsEarned: json['totalPointsEarned'] ?? 0,
      pointsRedeemed: json['pointsRedeemed'] ?? 0,
      nextMilestone: json['nextMilestone'] ?? 0,
      sustainabilityPractices: (json['sustainabilityPractices'] as List<dynamic>? ?? [])
          .map((item) => SustainabilityPractice.fromJson(item))
          .toList(),
      monthlyProgress: (json['monthlyProgress'] as List<dynamic>? ?? [])
          .map((item) => MonthlyProgress.fromJson(item))
          .toList(),
      pointsHistory: (json['pointsHistory'] as List<dynamic>? ?? [])
          .map((item) => PointsTransaction.fromJson(item))
          .toList(),
    );
  }
}

class SustainabilityPractice {
  final String id;
  final String title;
  final String description;
  final bool isActive;
  final int pointsEarned;

  SustainabilityPractice({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.pointsEarned,
  });

  factory SustainabilityPractice.fromJson(Map<String, dynamic> json) {
    return SustainabilityPractice(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }
}

class MonthlyProgress {
  final DateTime month;
  final int ecoPoints;
  final double wasteReduced;

  MonthlyProgress({
    required this.month,
    required this.ecoPoints,
    required this.wasteReduced,
  });

  factory MonthlyProgress.fromJson(Map<String, dynamic> json) {
    return MonthlyProgress(
      month: DateTime.parse(json['month'] ?? DateTime.now().toIso8601String()),
      ecoPoints: json['ecoPoints'] ?? 0,
      wasteReduced: (json['wasteReduced'] ?? 0).toDouble(),
    );
  }
}

class PointsTransaction {
  final String id;
  final String type;
  final int points;
  final String description;
  final DateTime date;

  PointsTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.date,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'earned',
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class EcoReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final IconData icon;
  final Color color;

  EcoReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.icon,
    required this.color,
  });

  factory EcoReward.fromJson(Map<String, dynamic> json) {
    // Map icon names to IconData
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'discount':
          return Icons.local_offer;
        case 'delivery':
          return Icons.local_shipping;
        case 'gift':
          return Icons.card_giftcard;
        case 'tree':
          return Icons.park;
        case 'certificate':
          return Icons.verified;
        default:
          return Icons.card_giftcard;
      }
    }

    // Map color names to Color
    Color getColor(String colorName) {
      switch (colorName) {
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'red':
          return Colors.red;
        default:
          return Colors.green;
      }
    }

    return EcoReward(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      icon: getIcon(json['icon'] ?? 'gift'),
      color: getColor(json['color'] ?? 'green'),
    );
  }
} 