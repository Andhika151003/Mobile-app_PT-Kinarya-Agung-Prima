import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/statistic_controller.dart';
import '../../product/views/product_detail_admin_view.dart';
import '../../product/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/shimmer_loading.dart';

class AdminStatisticView extends StatefulWidget {
  const AdminStatisticView({super.key});

  @override
  State<AdminStatisticView> createState() => _AdminStatisticViewState();
}

class _AdminStatisticViewState extends State<AdminStatisticView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AdminStatisticController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Admin Statistics',
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
                icon: Icon(Icons.refresh, color: Colors.grey[600]),
                onPressed: controller.isLoading
                    ? null
                    : () => controller.fetchAnalyticsData(),
              ),
            ],
          ),
          body: Builder(builder: (context) {
            if (controller.isLoading &&
                controller.totalOrders == 0 &&
                controller.salesTrend.isEmpty) {
              return const StatisticShimmer();
            }

            return RefreshIndicator(
              onRefresh: controller.fetchAnalyticsData,
              color: const Color(0xFF2E7D32),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2E7D32)),
                          minHeight: 2,
                        ),
                      ),
                    _buildFilterSection(controller),
                    const SizedBox(height: 20),

                    // --- REVENUE & ORDERS ---
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Revenue',
                                currencyFormat.format(controller.totalRevenue),
                                Icons.payments_outlined,
                                Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Orders',
                                '${controller.totalOrders}',
                                Icons.shopping_cart_outlined,
                                Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Cancel',
                                '${controller.cancelledOrders}',
                                Icons.cancel_outlined,
                                Colors.red)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildSummaryCard(
                                'Total Complaint',
                                '${controller.totalComplaints}',
                                Icons.assignment_late_outlined,
                                Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SALES TREND CHART ---
                    const Text('Sales Trend',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 12),
                    _buildLineChart(controller.salesTrend),
                    const SizedBox(height: 24),

                    // --- TOP PRODUCTS ---
                    _buildTopProductsSection(controller.topProducts),
                    const SizedBox(height: 24),

                    // --- TOP RETAILERS ---
                    _buildRankingSection(
                        'Top Retailers',
                        controller.topRetailers,
                        (item) => currencyFormat.format(item['spent']),
                        Icons.storefront_outlined),
                    const SizedBox(height: 24),

                    // --- CATEGORY POPULARITY PIE CHART ---
                    const Text('Category Popularity',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(
                      'Distribusi pesanan berdasarkan kategori produk untuk melihat tren minat pelanggan.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryPieChart(controller.categoryOrderCounts),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFilterSection(AdminStatisticController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatFilter.values.map((filter) {
          final isSelected = controller.currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: isSelected,
              onSelected: (val) => controller.setFilter(filter),
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(StatFilter filter) {
    switch (filter) {
      case StatFilter.today: return 'Today';
      case StatFilter.week: return 'Last 7 Days';
      case StatFilter.month: return 'Last 30 Days';
      case StatFilter.all: return 'All Time';
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)))),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) {
      return _emptyContainer('No trend data available');
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < trend.length; i++) {
      double val = trend[i]['value'];
      spots.add(FlSpot(i.toDouble(), val));
    }

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF2E7D32),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index < 0 || index >= trend.length) return null;
                  final value = barSpot.y;
                  return LineTooltipItem(
                    '${trend[index]['date']}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    children: [
                      TextSpan(
                        text: currencyFormat.format(value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  int index = val.toInt();
                  if (index < 0 || index >= trend.length)
                    return const Text('');
                  if (trend.length > 7 && index % (trend.length ~/ 4) != 0)
                    return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(trend[index]['date'],
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[500])),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF2E7D32),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFF2E7D32).withValues(alpha: 0.3), const Color(0xFF2E7D32).withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection(List<Map<String, dynamic>> products) {
    final top5Products = products.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Products',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: top5Products.isEmpty
              ? _emptyContainer('No product data available', height: 100)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top5Products.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final item = top5Products[index];
                  final productId = item['id'];
                  final imageUrl = item['imageUrl'];

                  return ListTile(
                    onTap: productId != null ? () async {
                      final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
                      if (doc.exists && context.mounted) {
                        final product = ProductModel.fromMap(doc.data()!, doc.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailAdminView(product: product),
                          ),
                        );
                      }
                    } : null,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        image: imageUrl != null ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: imageUrl == null ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                    ),
                    title: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('${item['sales']} items sold', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(item['revenue']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildRankingSection(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) valueLabel, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: items.isEmpty 
            ? _emptyContainer('No data available', height: 100)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[50],
                      child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    title: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Top spender', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Text(valueLabel(item), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(Map<String, int> categories) {
    if (categories.isEmpty) return _emptyContainer('No category data available');

    final List<Color> colors = [
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
      const Color(0xFFFFA000),
      const Color(0xFFD32F2F),
      const Color(0xFF7B1FA2),
      const Color(0xFF0097A7),
    ];

    List<PieChartSectionData> sections = [];
    int i = 0;
    categories.forEach((name, count) {
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: count.toDouble(),
        title: '$count',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categories.keys.toList().asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(entry.value, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _emptyContainer(String message, {double height = 150}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14))),
    );
  }
}
