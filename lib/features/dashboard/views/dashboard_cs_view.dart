import 'package:flutter/material.dart';
import '../controllers/dashboard_cs_controller.dart';
import '../../complaint/views/complaint_detail_cs_view.dart';

class DashboardCsView extends StatefulWidget {
  const DashboardCsView({super.key});

  @override
  State<DashboardCsView> createState() => _DashboardCsViewState();
}

class _DashboardCsViewState extends State<DashboardCsView> {
  final DashboardCsController _controller = DashboardCsController();

  String csName = 'CS';
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadCsInfo();
  }

  Future<void> _loadCsInfo() async {
    try {
      final profile = await _controller.getCsInfo();
      if (mounted) {
        setState(() {
          csName = profile?['fullName'] ?? 'CS';
          isLoadingName = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoadingName
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

                    Text(
                      'Welcome $csName!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Cards
                    StreamBuilder<Map<String, int>>(
                      stream: _controller.getComplaintStatsStream(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {'openComplaints': 0, 'resolvedToday': 0};
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Open Complaints',
                                stats['openComplaints'].toString(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Resolved Today',
                                stats['resolvedToday'].toString(),
                              ),
                            ),
                          ],
                        );
                      }
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
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _controller.getRecentComplaintsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        
                        final complaints = snapshot.data ?? [];
                        
                        if (complaints.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No recent complaints'),
                            ),
                          );
                        }
                        
                        return Column(
                          children: complaints.map(
                            (complaint) => Column(
                              children: [
                                _buildComplaintCard(
                                  timeAgo: complaint['timeAgo'],
                                  title: complaint['title'],
                                  description: complaint['description'],
                                  storeName: complaint['storeName'],
                                  status: complaint['status'] ?? 'pending',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ComplaintDetailCsView(
                                          complaint: complaint['model'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ).toList(),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
    );
  }

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
    required String status,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'resolved':
        statusColor = const Color(0xFF1B8A3A);
        statusLabel = 'RESOLVED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
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
      ),
    );
  }
}
