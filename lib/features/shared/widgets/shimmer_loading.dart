import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: ShimmerLoading(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerLoading(height: 16, width: double.infinity),
                      const SizedBox(height: 6),
                      const ShimmerLoading(height: 12, width: 80),
                      const SizedBox(height: 4),
                      const ShimmerLoading(height: 12, width: 60),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerLoading(height: 16, width: 70),
                      const ShimmerLoading(
                          height: 24,
                          width: 24,
                          borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PromotionCardShimmer extends StatelessWidget {
  const PromotionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(
              width: 80,
              height: 20,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: 12),
          const ShimmerLoading(width: double.infinity, height: 22),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 150, height: 14),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 100, height: 14),
              const ShimmerLoading(
                  width: 70,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(6))),
            ],
          ),
        ],
      ),
    );
  }
}

class StatisticShimmer extends StatelessWidget {
  const StatisticShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Shimmer
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                  4,
                  (index) => const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: ShimmerLoading(
                            width: 80,
                            height: 32,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                      )),
            ),
          ),
          const SizedBox(height: 24),

          // Summary Cards Shimmer
          Row(
            children: [
              Expanded(
                  child: ShimmerLoading(
                      height: 100, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 12),
              Expanded(
                  child: ShimmerLoading(
                      height: 100, borderRadius: BorderRadius.circular(16))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: ShimmerLoading(
                      height: 100, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 12),
              Expanded(
                  child: ShimmerLoading(
                      height: 100, borderRadius: BorderRadius.circular(16))),
            ],
          ),
          const SizedBox(height: 32),

          // Chart Shimmer
          const ShimmerLoading(width: 120, height: 20),
          const SizedBox(height: 16),
          ShimmerLoading(height: 220, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 32),

          // List Shimmer
          const ShimmerLoading(width: 120, height: 20),
          const SizedBox(height: 16),
          Column(
            children: List.generate(
                3,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerLoading(
                          height: 70, borderRadius: BorderRadius.circular(16)),
                    )),
          ),
        ],
      ),
    );
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          const ShimmerLoading(width: 100, height: 35),
          const SizedBox(height: 30),

          // Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 80, height: 22),
              const ShimmerLoading(width: 110, height: 14),
            ],
          ),
          const SizedBox(height: 15),

          // Overview Cards
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: ShimmerLoading(
                          height: 110, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ShimmerLoading(
                          height: 110, borderRadius: BorderRadius.circular(10))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: ShimmerLoading(
                          height: 110, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ShimmerLoading(
                          height: 110, borderRadius: BorderRadius.circular(10))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Promotions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 140, height: 22),
              const ShimmerLoading(width: 70, height: 14),
            ],
          ),
          const SizedBox(height: 15),

          // Promotions List
          ShimmerLoading(height: 200, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 30),

          // Retailers Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 110, height: 22),
              const ShimmerLoading(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 15),

          // Retailer List
          Column(
            children: List.generate(
                2,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerLoading(
                          height: 65, borderRadius: BorderRadius.circular(8)),
                    )),
          ),
        ],
      ),
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 100, height: 18),
              const ShimmerLoading(width: 70, height: 20, borderRadius: BorderRadius.all(Radius.circular(20))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 120, height: 14),
              const ShimmerLoading(width: 80, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardUserShimmer extends StatelessWidget {
  const DashboardUserShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoading(width: 120, height: 40),
              const ShimmerLoading(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
            ],
          ),
          const SizedBox(height: 20),

          // Greeting
          const ShimmerLoading(width: 150, height: 24),
          const SizedBox(height: 8),
          const ShimmerLoading(width: 200, height: 16),
          const SizedBox(height: 20),

          // Banner
          ShimmerLoading(height: 180, width: double.infinity, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 24),

          // Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) => Column(
              children: [
                const ShimmerLoading(width: 55, height: 55, borderRadius: BorderRadius.all(Radius.circular(30))),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 45, height: 12),
              ],
            )),
          ),
          const SizedBox(height: 24),

          // Recent Orders Header
          const ShimmerLoading(width: 120, height: 20),
          const SizedBox(height: 16),
          
          // Recent Order Cards
          const OrderCardShimmer(),
          const SizedBox(height: 12),
          const OrderCardShimmer(),
          const SizedBox(height: 24),

          // Recommended Header
          const ShimmerLoading(width: 160, height: 20),
          const SizedBox(height: 16),

          // Recommended Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: 2,
            itemBuilder: (context, index) => const ProductCardShimmer(),
          ),
        ],
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Profile Header Shimmer
          Row(
            children: [
              const ShimmerLoading(width: 80, height: 80, borderRadius: BorderRadius.all(Radius.circular(40))),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLoading(width: 150, height: 20),
                  SizedBox(height: 8),
                  ShimmerLoading(width: 100, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 16),
              Expanded(child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(12))),
            ],
          ),
          const SizedBox(height: 32),
          // Details Section
          const ShimmerLoading(width: 120, height: 18),
          const SizedBox(height: 16),
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerLoading(height: 60, width: double.infinity, borderRadius: BorderRadius.circular(12)),
          )),
        ],
      ),
    );
  }
}
