import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../dashboard/controllers/dashboard_admin_controller.dart';
import '../models/complaint.dart';
import 'complaint_detail_cs_view.dart';

class AdminComplaintHistoryView extends StatefulWidget {
  const AdminComplaintHistoryView({super.key});

  @override
  State<AdminComplaintHistoryView> createState() => _AdminComplaintHistoryViewState();
}

class _AdminComplaintHistoryViewState extends State<AdminComplaintHistoryView> {
  final DashboardAdminController _controller = DashboardAdminController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search order ID, issue...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'History Complaint',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black87, size: 24),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _controller.getAllComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final allComplaints = snapshot.data ?? [];
          
          final filteredBySearch = allComplaints.where((c) {
            final searchLower = _searchQuery.toLowerCase();
            return c.orderId.toLowerCase().contains(searchLower) ||
                c.issueType.toLowerCase().contains(searchLower) ||
                c.description.toLowerCase().contains(searchLower);
          }).toList();

          if (filteredBySearch.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBySearch.length,
            itemBuilder: (context, index) {
              final complaint = filteredBySearch[index];
              return _buildComplaintCard(complaint);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off_rounded : Icons.history_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No results found' : 'No complaint history found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComplaintDetailCsView(
                  complaint: complaint,
                  readOnly: true, // Admin cannot reject/resolve
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint.status).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIssueIcon(complaint.issueType),
                    color: _getStatusColor(complaint.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            complaint.issueType,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          _buildStatusBadge(complaint.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order ID: #${complaint.orderId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(complaint.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                          if (complaint.status != 'pending')
                            Text(
                              'Handled by: ${complaint.resolvedByName ?? 'CS'}',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'investigating': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getIssueIcon(String type) {
    switch (type.toLowerCase()) {
      case 'barang rusak': return Icons.broken_image_outlined;
      case 'salah produk': return Icons.wrong_location_outlined;
      case 'kurang jumlah': return Icons.remove_circle_outline;
      case 'pengiriman lambat': return Icons.speed_outlined;
      default: return Icons.report_problem_outlined;
    }
  }
}
