import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({Key? key}) : super(key: key);

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SystemLog> _logs = [];
  List<SystemLog> _filteredLogs = [];
  bool _isLoading = true;
  String _selectedLevel = 'all';
  String _selectedSource = 'all';
  String _searchQuery = '';
  bool _autoRefresh = false;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _logLevels = ['all', 'error', 'warning', 'info', 'debug'];
  final List<String> _logSources = ['all', 'api', 'database', 'payment', 'auth', 'system'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLogs();
    _searchController.addListener(_onSearchChanged);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterLogs();
    });
  }

  void _startAutoRefresh() {
    if (_autoRefresh) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _autoRefresh) {
          _loadLogs(showLoading: false);
          _startAutoRefresh();
        }
      });
    }
  }

  Future<void> _loadLogs({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(
        ApiEndpoints.adminSystemLogs(limit: 500)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _logs = (data['logs'] as List)
              .map((log) => SystemLog.fromJson(log))
              .toList();
          _filteredLogs = _logs;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load system logs');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading logs: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterLogs() {
    _filteredLogs = _logs.where((log) {
      final matchesLevel = _selectedLevel == 'all' || log.level == _selectedLevel;
      final matchesSource = _selectedSource == 'all' || log.source == _selectedSource;
      final matchesSearch = _searchQuery.isEmpty ||
          log.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.source.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.userId.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesLevel && matchesSource && matchesSearch;
    }).toList();
  }

  Future<void> _clearLogs(String level) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${level.toUpperCase()} Logs'),
        content: Text('Are you sure you want to clear all ${level == 'all' ? '' : level} logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.delete(
        ApiEndpoints.adminSystemLogs(level: level != 'all' ? level : null)
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${level.toUpperCase()} logs cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadLogs(showLoading: false);
        }
      } else {
        throw Exception('Failed to clear logs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing logs: ${e.toString()}'),
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
          'System Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _autoRefresh ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
                if (_autoRefresh) {
                  _startAutoRefresh();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            onSelected: (value) => _clearLogs(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'error',
                child: Text('Clear Error Logs'),
              ),
              const PopupMenuItem(
                value: 'warning',
                child: Text('Clear Warning Logs'),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Text('Clear Info Logs'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('Clear All Logs'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadLogs(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'All (${_logs.length})',
              icon: const Icon(Icons.list),
            ),
            Tab(
              text: 'Errors (${_logs.where((l) => l.level == 'error').length})',
              icon: const Icon(Icons.error),
            ),
            Tab(
              text: 'Warnings (${_logs.where((l) => l.level == 'warning').length})',
              icon: const Icon(Icons.warning),
            ),
            Tab(
              text: 'Info (${_logs.where((l) => l.level == 'info').length})',
              icon: const Icon(Icons.info),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogsList(_filteredLogs),
                      _buildLogsList(_filteredLogs.where((l) => l.level == 'error').toList()),
                      _buildLogsList(_filteredLogs.where((l) => l.level == 'warning').toList()),
                      _buildLogsList(_filteredLogs.where((l) => l.level == 'info').toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Auto-refresh indicator
          if (_autoRefresh)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.green[700], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-refresh ON',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (_autoRefresh) const SizedBox(height: 12),
          
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search logs by message, source, or user ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Log Level',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _logLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Row(
                        children: [
                          Icon(
                            _getLogLevelIcon(level),
                            color: _getLogLevelColor(level),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(level.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel = value!;
                      _filterLogs();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSource,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _logSources.map((source) {
                    return DropdownMenuItem(
                      value: source,
                      child: Text(source.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSource = value!;
                      _filterLogs();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Results Count
          Text(
            'Showing ${_filteredLogs.length} of ${_logs.length} logs',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<SystemLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No logs found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogCard(log);
        },
      ),
    );
  }

  Widget _buildLogCard(SystemLog log) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getLogLevelColor(log.level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLogLevelIcon(log.level),
                    color: _getLogLevelColor(log.level),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.level.toUpperCase(),
                        style: TextStyle(
                          color: _getLogLevelColor(log.level),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSourceColor(log.source).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getSourceColor(log.source).withOpacity(0.3)),
                  ),
                  child: Text(
                    log.source.toUpperCase(),
                    style: TextStyle(
                      color: _getSourceColor(log.source),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Log Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                log.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            if (log.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.details,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Additional Info
            Row(
              children: [
                if (log.userId.isNotEmpty)
                  Expanded(
                    child: _buildLogDetailItem(
                      'User ID',
                      log.userId,
                      Icons.person,
                      Colors.blue,
                    ),
                  ),
                if (log.ipAddress.isNotEmpty)
                  Expanded(
                    child: _buildLogDetailItem(
                      'IP Address',
                      log.ipAddress,
                      Icons.public,
                      Colors.purple,
                    ),
                  ),
              ],
            ),
            
            if (log.requestId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildLogDetailItem(
                'Request ID',
                log.requestId,
                Icons.fingerprint,
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getLogLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'debug':
        return Icons.bug_report;
      case 'all':
        return Icons.list;
      default:
        return Icons.help;
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'api':
        return Colors.green;
      case 'database':
        return Colors.blue;
      case 'payment':
        return Colors.purple;
      case 'auth':
        return Colors.orange;
      case 'system':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class SystemLog {
  final String id;
  final String level;
  final String message;
  final String source;
  final DateTime timestamp;
  final String userId;
  final String ipAddress;
  final String requestId;
  final String details;

  SystemLog({
    required this.id,
    required this.level,
    required this.message,
    required this.source,
    required this.timestamp,
    required this.userId,
    required this.ipAddress,
    required this.requestId,
    required this.details,
  });

  factory SystemLog.fromJson(Map<String, dynamic> json) {
    return SystemLog(
      id: json['id'] ?? '',
      level: json['level'] ?? '',
      message: json['message'] ?? '',
      source: json['source'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      userId: json['userId'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      requestId: json['requestId'] ?? '',
      details: json['details'] ?? '',
    );
  }
} 