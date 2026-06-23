import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_cs_controller.dart';
import 'form_add_cs_view.dart';
import 'form_edit_cs_view.dart';

class AdminCsView extends StatefulWidget {
  const AdminCsView({super.key});

  @override
  State<AdminCsView> createState() => _AdminCsViewState();
}

class _AdminCsViewState extends State<AdminCsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminCsController()..fetchAllCS(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Customer Support Management',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FormAddCsView()),
                    );
                    if (result == true && context.mounted) {
                      context.read<AdminCsController>().fetchAllCS();
                    }
                  },
                ),
              ],
            ),
            body: Consumer<AdminCsController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.csList.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              );
            }

            List<Map<String, dynamic>> filteredCS = controller.csList;
            if (_selectedFilter == 'active') {
              filteredCS = filteredCS.where((cs) => cs['isActive'] == true).toList();
            } else if (_selectedFilter == 'inactive') {
              filteredCS = filteredCS.where((cs) => cs['isActive'] == false).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats Row ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _buildStatItem('Total CS', '${controller.csList.length}'),
                      const SizedBox(width: 12),
                      _buildStatItem('Active', '${controller.getActiveCSCount()}', color: Colors.green),
                      const SizedBox(width: 12),
                      _buildStatItem('Inactive', '${controller.getInactiveCSCount()}', color: Colors.red),
                    ],
                  ),
                ),

                // ── Filter Chips ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _filterChip('Inactive', 'inactive'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── List CS ─────────────────────────────────────────────
                Expanded(
                  child: filteredCS.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.support_agent_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Customer Support found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredCS.length,
                          itemBuilder: (context, index) {
                            final cs = filteredCS[index];
                            return _csCard(context, cs, controller);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Inter')),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1F2937), fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _csCard(BuildContext context, Map<String, dynamic> cs, AdminCsController controller) {
    final isActive = cs['isActive'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFECF3E8),
            child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cs['username'] ?? cs['fullName'] ?? 'CS User',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
                ),
                Text(
                  cs['email'] ?? '-',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Inter'),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2E7D32), size: 20),
            tooltip: 'Edit CS',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormEditCsView(csData: cs),
                ),
              );
              if (result == true && context.mounted) {
                controller.fetchAllCS();
              }
            },
          ),
          Switch(
            value: isActive,
            activeThumbColor: const Color(0xFF2E7D32),
            onChanged: (value) async {
              final confirmed = await _showConfirmDialog(context, value);
              if (confirmed == true) {
                await controller.toggleCSStatus(cs['id'], value);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, bool newStatus) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activate CS?' : 'Deactivate CS?'),
        content: Text('Are you sure you want to change this Customer Support status?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate', style: TextStyle(color: newStatus ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
  }
}
