import 'package:flutter/material.dart';
import '../controllers/dashboard_cs_controller.dart';

class DashboardCsView extends StatefulWidget {
  const DashboardCsView({super.key});

  @override
  State<DashboardCsView> createState() => _DashboardCsViewState();
}

class _DashboardCsViewState extends State<DashboardCsView> {
  final DashboardCsController _controller = DashboardCsController();

  int openComplaints = 0;
  int resolvedToday = 0;
  List<Map<String, dynamic>> recentComplaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await _controller.getComplaintStats();
      final complaints = await _controller.getRecentComplaints();

      if (mounted) {
        setState(() {
          openComplaints = stats['openComplaints'] ?? 0;
          resolvedToday = stats['resolvedToday'] ?? 0;
          recentComplaints = complaints;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading CS dashboard data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF458833)),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Welcome CS!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Open Complaints',
                            openComplaints.toString(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Resolved Today',
                            resolvedToday.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Recent Complaints',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Complaints List
                    if (recentComplaints.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No recent complaints'),
                        ),
                      )
                    else
                      ...recentComplaints.map((complaint) => Column(
                            children: [
                              _buildComplaintCard(
                                timeAgo: complaint['timeAgo'],
                                title: complaint['title'],
                                description: complaint['description'],
                                storeName: complaint['storeName'],
                              ),
                              const SizedBox(height: 16),
                            ],
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildStatCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B8A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard({
    required String timeAgo,
    required String title,
    required String description,
    required String storeName,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waktu (Time Ago)
          Align(
            alignment: Alignment.topRight,
            child: Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Judul Komplain
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Deskripsi
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Nama Toko
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF1B8A3A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}