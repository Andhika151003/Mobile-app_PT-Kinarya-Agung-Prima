import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';
import 'form_edit_admin_view.dart';
import '../controllers/profile_admin_controller.dart';

class ProfileAdminView extends StatefulWidget {
  const ProfileAdminView({super.key});

  @override
  State<ProfileAdminView> createState() => _ProfileAdminViewState();
}

class _ProfileAdminViewState extends State<ProfileAdminView> {
  final AdminProfileController _adminController = AdminProfileController();
  String adminName = 'Loading...';
  String location = 'Loading...';
  String contact = 'Loading...';
  String bankAccount = 'Loading...';
  String bankName = 'Loading...';
  String distributorId = '-';
  int totalSupply = 0; 
  int totalRevenue = 0; 
  String? photoUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final data = await _adminController.getAdminProfile();

      if (data != null && mounted) {
        setState(() {
          adminName = data['fullName'] ?? 'No Name';
          location = data['address'] ?? 'No Location';
          contact = data['phoneNumber'] ?? 'No Contact';
          bankAccount = data['bankAccount'] ?? 'Not Set';
          bankName = data['bankName'] ?? 'Not Set';
          distributorId = '#DS${data['uid'].substring(0, 6).toUpperCase()}';
          photoUrl = data['photoUrl'];

          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching admin data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF458833)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileHeader(),
                  const SizedBox(height: 40),
                  _buildBusinessDetails(),
                  const SizedBox(height: 32),
                  _buildStatsCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total Supply',
                    value: totalSupply.toString(),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Total Revenue',
                    value: 'Rp $totalRevenue',
                  ),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- FUNGSI POP-UP LOGOUT ---

  void _showLogoutDialog(BuildContext context) {
    const primaryGreen = Color(0xFF458833);

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: primaryGreen),
                            ),
                          );

                          try {
                            await FirebaseAuth.instance.signOut();

                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginView()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logout failed: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET SECTIONS ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black45),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF458833), width: 2),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? const Icon(Icons.storefront_outlined, size: 40, color: Color(0xFF458833))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            adminName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distributor',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FormProfileAdminView()),
                  );
                  if (result == true) {
                    setState(() => isLoading = true);
                    _fetchAdminData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF458833),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  minimumSize: const Size(70, 30),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Details',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Distributor ID', distributorId),
        const SizedBox(height: 16),
        _buildDetailRow('Location', location),
        const SizedBox(height: 16),
        _buildDetailRow('Contact', contact),
        const SizedBox(height: 16),
        _buildDetailRow('Bank Account', bankAccount),
        const SizedBox(height: 16),
        _buildDetailRow('Bank Name', bankName),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatsCard({required IconData icon, required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF458833), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF458833),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}