import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../../dashboard/controllers/dashboard_cs_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintDetailCsView extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailCsView({super.key, required this.complaint});

  @override
  State<ComplaintDetailCsView> createState() => _ComplaintDetailCsViewState();
}

class _ComplaintDetailCsViewState extends State<ComplaintDetailCsView> {
  final DashboardCsController _controller = DashboardCsController();
  bool _isResolving = false;
  bool _isRejecting = false;
  Map<String, dynamic>? _retailerProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchRetailerProfile();
  }

  Future<void> _fetchRetailerProfile() async {
    try {
      final profile = await _controller.getUserProfile(widget.complaint.userId);
      if (mounted) {
        setState(() {
          _retailerProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _resolveComplaint() async {
    setState(() => _isResolving = true);
    try {
      final success = await _controller.resolveComplaint(widget.complaint.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint resolved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _rejectComplaint() async {
    setState(() => _isRejecting = true);
    try {
      final success = await _controller.rejectComplaint(widget.complaint.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint rejected')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = _retailerProfile?['phoneNumber'];
    if (phoneNumber == null || phoneNumber.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retailer phone number not found')),
      );
      return;
    }

    String cleanNumber = phoneNumber.toString().replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final String message = 'Halo ${_retailerProfile?['fullName'] ?? 'Retailer'},\n\n'
        'Saya CS dari PT Kinarya Agung Prima terkait komplain Anda:\n'
        'Order ID: #${widget.complaint.orderId}\n'
        'Isu: ${widget.complaint.issueType}';

    final Uri whatsappUri = Uri.parse(
      'whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}'
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        final Uri webUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}'
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Complaint Detail', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildInfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.complaint.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.complaint.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.complaint.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Submitted At', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(widget.complaint.createdAt),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Retailer Profile Section
            const Text('Retailer Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoCard(
              child: _isLoadingProfile
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1B8A3A).withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: Color(0xFF1B8A3A)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _retailerProfile?['fullName'] ?? 'Unknown Retailer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _retailerProfile?['email'] ?? 'No email',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              Text(
                                _retailerProfile?['phoneNumber'] ?? 'No phone number',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _launchWhatsApp,
                          icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                          tooltip: 'Chat on WhatsApp',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Order & Product Info
            const Text('Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoCard(
              child: Column(
                children: [
                  _buildDetailRow('Order ID', widget.complaint.orderId),
                  const Divider(height: 24),
                  _buildDetailRow('Issue Type', widget.complaint.issueType),
                  if (widget.complaint.productName != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow('Product', widget.complaint.productName!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoCard(
              child: Text(
                widget.complaint.description,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),

            // Images
            if (widget.complaint.imgUrl.isNotEmpty || widget.complaint.imageUrls.isNotEmpty) ...[
              const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (widget.complaint.imgUrl.isNotEmpty)
                      _buildImageThumbnail(widget.complaint.imgUrl),
                    
                    ...widget.complaint.imageUrls
                        .where((url) => url != widget.complaint.imgUrl)
                        .map((url) => _buildImageThumbnail(url)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (widget.complaint.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isRejecting || _isResolving ? null : _rejectComplaint,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isRejecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            )
                          : const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isResolving || _isRejecting ? null : _resolveComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B8A3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isResolving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Resolve',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
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
}
