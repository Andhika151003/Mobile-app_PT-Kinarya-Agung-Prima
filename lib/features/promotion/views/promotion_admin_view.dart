import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/promotion_admin_controller.dart';
import '../models/promotion.dart';
import 'form_promotion_admin_view.dart';
import 'promotion_detail_admin_view.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../../core/theme/app_colors.dart';

class PromotionAdminView extends StatefulWidget {
  const PromotionAdminView({super.key});

  @override
  State<PromotionAdminView> createState() => _PromotionAdminViewState();
}

class _PromotionAdminViewState extends State<PromotionAdminView> {
  final TextEditingController _searchController = TextEditingController();
  late final PromotionAdminController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PromotionAdminController()..fetchAllPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
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
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const PromotionCardShimmer(),
              );
            }

            return Column(
              children: [
                if (controller.isLoading && controller.promotions.isNotEmpty)
                  const LinearProgressIndicator(
                    color: Color(0xFF2E7D32),
                    backgroundColor: Color(0xFFE8F5E9),
                    minHeight: 3,
                  ),
                _buildFilters(controller),
                const SizedBox(height: 16),
                Expanded(
                  child: controller.filteredPromotions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No promotions found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: controller.filteredPromotions.length,
                          itemBuilder: (context, index) {
                            final promo = controller.filteredPromotions[index];
                            return _promotionCard(context, promo, controller);
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormPromotionAdminView()),
            );
            _controller.fetchAllPromotions();
          },
          backgroundColor: const Color(0xFF2E7D32),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildSearchBar(PromotionAdminController controller) {
    return TextField(
      controller: _searchController,
      onChanged: controller.searchPromotions,
      decoration: InputDecoration(
        hintText: 'Search Promotions',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildFilters(PromotionAdminController controller) {
    final statuses = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Active', 'value': 'active'},
      {'label': 'Upcoming', 'value': 'upcoming'},
      {'label': 'Ending', 'value': 'ending_soon'},
      {'label': 'Expired', 'value': 'expired'},
    ];

    final types = [
      {'label': 'All Types', 'value': 'all'},
      {'label': 'Percentage', 'value': 'percentage'},
      {'label': 'BOGO', 'value': 'bogo'},
      {'label': 'Bundle', 'value': 'bundle'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          _buildSearchBar(controller),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...statuses.map((status) {
                  bool isSelected =
                      controller.selectedStatus == status['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status['label']!),
                      onSelected: (_) =>
                          controller.filterByStatus(status['value']!),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.black54,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      backgroundColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...types.map((type) {
                  bool isSelected = controller.selectedType == type['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(type['label']!),
                      onSelected: (_) =>
                          controller.filterByType(type['value']!),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.black54,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _promotionCard(
    BuildContext context,
    PromotionModel promo,
    PromotionAdminController controller,
  ) {
    String statusText;
    Color statusColor, statusBgColor;

    if (promo.isUpcoming) {
      statusText = 'Upcoming';
      statusColor = const Color(0xFF0891B2);
      statusBgColor = const Color(0xFFECFEFF);
    } else if (promo.isEndingSoon) {
      statusText = 'Ending Soon';
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (promo.isActive) {
      statusText = 'Active';
      statusColor = const Color(0xFF2E7D32);
      statusBgColor = const Color(0xFFE8F5E9);
    } else {
      statusText = 'Expired';
      statusColor = const Color(0xFF9CA3AF);
      statusBgColor = const Color(0xFFF3F4F6);
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromotionDetailAdminView(promotion: promo),
          ),
        );
        controller.fetchAllPromotions();
        if (result == 'deleted' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Promotion deleted successfully'),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SKU: ${promo.sku}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
              ],
            ),
            const SizedBox(height: 10),
            Text(
              promo.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valid: ${promo.formattedDateRange}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      promo.discountText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    if (promo.discountType == 'bogo' &&
                        promo.maxDiscount != null)
                      Text(
                        'Up to ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(promo.maxDiscount)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
