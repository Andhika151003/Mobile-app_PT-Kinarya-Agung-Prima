import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/promotion_admin_controller.dart';
import '../models/promotion.dart';
import 'form_promotion_admin_view.dart';
import 'promotion_detail_admin_view.dart';

class PromotionAdminView extends StatefulWidget {
  const PromotionAdminView({super.key});

  @override
  State<PromotionAdminView> createState() => _PromotionAdminViewState();
}

class _PromotionAdminViewState extends State<PromotionAdminView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PromotionAdminController()..fetchAllPromotions(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false, // ← hapus back button
          title: const Text(
            'Promotions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        body: Consumer<PromotionAdminController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.promotions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              );
            }

            return Column(
              children: [
                // ── Search Bar ──────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Promotions',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search,
                            color: Colors.white, size: 20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: controller.searchPromotions,
                  ),
                ),

                const SizedBox(height: 8),

                // ── List Promotions ─────────────────────────────────
                Expanded(
                  child: controller.filteredPromotions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No promotions found',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add a new promotion',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: controller.filteredPromotions.length,
                          itemBuilder: (context, index) {
                            final promo =
                                controller.filteredPromotions[index];
                            return _promotionCard(
                                context, promo, controller);
                          },
                        ),
                ),
              ],
            );
          },
        ),

        // ── FAB ──────────────────────────────────────────────────
        floatingActionButton: Consumer<PromotionAdminController>(
          builder: (context, controller, _) => FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FormPromotionAdminView(),
                ),
              );
              controller.fetchAllPromotions();
            },
            backgroundColor: const Color(0xFF2E7D32),
            shape: const CircleBorder(),
            elevation: 4,
            child:
                const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _promotionCard(
    BuildContext context,
    PromotionModel promo,
    PromotionAdminController controller,
  ) {
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (promo.isEndingSoon) {
      statusText = 'Ending Soon';
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (promo.isActive) {
      statusText = 'Active';
      statusColor = const Color(0xFF6366F1);
      statusBgColor = const Color(0xFFEEF2FF);
    } else {
      statusText = 'Expired';
      statusColor = const Color(0xFF9CA3AF);
      statusBgColor = const Color(0xFFF3F4F6);
    }

    Color discountColor;
    Color discountBgColor;
    switch (promo.discountType) {
      case 'bogo':
        discountColor = const Color(0xFF6366F1);
        discountBgColor = const Color(0xFFEEF2FF);
        break;
      case 'fixed':
        discountColor = const Color(0xFFEA580C);
        discountBgColor = const Color(0xFFFFF7ED);
        break;
      case 'bundle':
        discountColor = const Color(0xFFD97706);
        discountBgColor = const Color(0xFFFEF3C7);
        break;
      default:
        discountColor = const Color(0xFF16A34A);
        discountBgColor = const Color(0xFFDCFCE7);
    }

    final isExpired = !promo.isActive && !promo.isEndingSoon;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PromotionDetailAdminView(promotion: promo),
          ),
        );
        controller.fetchAllPromotions();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Status + SKU
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  promo.sku,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Judul
            Text(
              promo.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isExpired
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF1F2937),
                decoration:
                    isExpired ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),

            // Valid date
            Text(
              'Valid: ${promo.formattedDateRange}',
              style: TextStyle(
                fontSize: 12,
                color: isExpired
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),

            // SKU + Discount badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SKU: ${promo.sku.replaceAll('#PRM-', '')}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: discountBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    promo.discountText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: discountColor,
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
}