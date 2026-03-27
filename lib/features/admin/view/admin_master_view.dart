// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../controller/admin_master_controller.dart';

// class AdminMasterView extends StatefulWidget {
//   const AdminMasterView({super.key});

//   @override
//   State<AdminMasterView> createState() => _AdminMasterViewState();
// }

// class _AdminMasterViewState extends State<AdminMasterView> {
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedFilter = 'all'; // 'all', 'active', 'inactive'

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final controller = Provider.of<AdminMasterController>(context, listen: false);
//       controller.fetchAllRetailers();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AdminMasterController(),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           title: const Text(
//             'Kelola Retailer',
//             style: TextStyle(
//               fontFamily: 'Inter',
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           backgroundColor: Colors.white,
//           foregroundColor: const Color(0xFF2E7D32),
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Consumer<AdminMasterController>(
//           builder: (context, controller, child) {
//             if (controller.isLoading && controller.retailers.isEmpty) {
//               return const Center(
//                 child: CircularProgressIndicator(
//                   color: Color(0xFF2E7D32),
//                 ),
//               );
//             }

//             // Filter retailer berdasarkan status
//             List<Map<String, dynamic>> filteredRetailers = controller.filteredRetailers;
//             if (_selectedFilter == 'active') {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] != false)
//                   .toList();
//             } else if (_selectedFilter == 'inactive') {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] == false)
//                   .toList();
//             }

//             return Column(
//               children: [
//                 // Header Stats
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   color: Colors.white,
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Total Retailers',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                               fontFamily: 'Inter',
//                               color: Color(0xFF6B7280),
//                             ),
//                           ),
//                           Text(
//                             '${controller.retailers.length}',
//                             style: const TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'Inter',
//                               color: Color(0xFF1F2937),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       // Active/Inactive Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   _selectedFilter = 'all';
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(vertical: 12),
//                                 decoration: BoxDecoration(
//                                   color: _selectedFilter == 'all'
//                                       ? const Color(0xFF2E7D32)
//                                       : Colors.grey[100],
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Active',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       fontFamily: 'Inter',
//                                       color: _selectedFilter == 'all'
//                                           ? Colors.white
//                                           : const Color(0xFF4B5563),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   _selectedFilter = 'inactive';
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(vertical: 12),
//                                 decoration: BoxDecoration(
//                                   color: _selectedFilter == 'inactive'
//                                       ? const Color(0xFF2E7D32)
//                                       : Colors.grey[100],
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Inactive',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       fontFamily: 'Inter',
//                                       color: _selectedFilter == 'inactive'
//                                           ? Colors.white
//                                           : const Color(0xFF4B5563),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Search Bar
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Cari retailer...',
//                       prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       contentPadding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     onChanged: controller.searchRetailers,
//                   ),
//                 ),
//                 // List Retailers
//                 Expanded(
//                   child: filteredRetailers.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.store_outlined,
//                                 size: 64,
//                                 color: Colors.grey[400],
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Tidak ada data retailer',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontFamily: 'Inter',
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           itemCount: filteredRetailers.length,
//                           itemBuilder: (context, index) {
//                             final retailer = filteredRetailers[index];
//                             final isActive = retailer['isActive'] != false;
//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 16),
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(
//                                   color: Colors.grey[200]!,
//                                   width: 1,
//                                 ),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withValues(alpha: 0.02),
//                                     blurRadius: 4,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           retailer['fullName'] ?? 'Tanpa Nama',
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w600,
//                                             fontFamily: 'Inter',
//                                             color: Color(0xFF1F2937),
//                                           ),
//                                         ),
//                                       ),
//                                       // Status Indicator
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: isActive
//                                               ? const Color(0xFFE8F5E9)
//                                               : const Color(0xFFFFEBEE),
//                                           borderRadius: BorderRadius.circular(20),
//                                         ),
//                                         child: Text(
//                                           isActive ? 'Active' : 'Inactive',
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w500,
//                                             fontFamily: 'Inter',
//                                             color: isActive
//                                                 ? const Color(0xFF2E7D32)
//                                                 : const Color(0xFFD32F2F),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     retailer['address'] ?? 'Alamat tidak tersedia',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontFamily: 'Inter',
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'ID: ${retailer['id']?.substring(0, 8) ?? 'N/A'}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontFamily: 'Inter',
//                                       color: Colors.grey[500],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   // Active/Inactive Toggle Button
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: GestureDetector(
//                                           onTap: () async {
//                                             if (isActive) {
//                                               final success = await controller
//                                                   .disableRetailer(retailer['id']);
//                                               if (success && mounted) {
//                                                 if (mounted) {
//                                                   ScaffoldMessenger.of(context)
//                                                       .showSnackBar(
//                                                     const SnackBar(
//                                                       content: Text(
//                                                           'Retailer dinonaktifkan'),
//                                                       backgroundColor: Colors.orange,
//                                                       duration: Duration(seconds: 1),
//                                                     ),
//                                                   );
//                                                 }
//                                               }
//                                             } else {
//                                               final success = await controller
//                                                   .enableRetailer(retailer['id']);
//                                               if (success && mounted) {
//                                                 if (mounted) {
//                                                   ScaffoldMessenger.of(context)
//                                                       .showSnackBar(
//                                                     const SnackBar(
//                                                       content: Text(
//                                                           'Retailer diaktifkan'),
//                                                       backgroundColor: Colors.green,
//                                                       duration: Duration(seconds: 1),
//                                                     ),
//                                                   );
//                                                 }
//                                               }
//                                             }
//                                           },
//                                           child: Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               vertical: 10,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: isActive
//                                                   ? const Color(0xFFE8F5E9)
//                                                   : const Color(0xFFFFEBEE),
//                                               borderRadius: BorderRadius.circular(8),
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 isActive ? 'Active' : 'Inactive',
//                                                 style: TextStyle(
//                                                   fontSize: 13,
//                                                   fontWeight: FontWeight.w500,
//                                                   fontFamily: 'Inter',
//                                                   color: isActive
//                                                       ? const Color(0xFF2E7D32)
//                                                       : const Color(0xFFD32F2F),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             _showDetailDialog(context, retailer);
//                                           },
//                                           child: Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               vertical: 10,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.grey[100],
//                                               borderRadius: BorderRadius.circular(8),
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 isActive ? 'Inactive' : 'Active',
//                                                 style: TextStyle(
//                                                   fontSize: 13,
//                                                   fontWeight: FontWeight.w500,
//                                                   fontFamily: 'Inter',
//                                                   color: isActive
//                                                       ? const Color(0xFFD32F2F)
//                                                       : const Color(0xFF2E7D32),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   void _showDetailDialog(BuildContext context, Map<String, dynamic> retailer) {
//     final isActive = retailer['isActive'] != false;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundColor: const Color(0xFF2E7D32),
//               child: Text(
//                 (retailer['fullName'] ?? 'R')[0],
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 retailer['fullName'] ?? 'Tanpa Nama',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Inter',
//                 ),
//               ),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _detailRow('Email', retailer['email'] ?? '-'),
//               const Divider(),
//               _detailRow('No. Telepon', retailer['phoneNumber'] ?? '-'),
//               const Divider(),
//               _detailRow('Alamat', retailer['address'] ?? '-'),
//               const Divider(),
//               _detailRow('ID Retailer', retailer['id'] ?? '-'),
//               const Divider(),
//               _detailRow('Status', isActive ? 'Aktif' : 'Nonaktif'),
//               const Divider(),
//               _detailRow('Bergabung', _formatDate(retailer['createdAt'])),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: const Color(0xFF2E7D32),
//             ),
//             child: const Text('Tutup'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//               color: Color(0xFF6B7280),
//               fontFamily: 'Inter',
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontFamily: 'Inter',
//               color: Color(0xFF1F2937),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(dynamic timestamp) {
//     if (timestamp == null) return '-';
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       return '${date.day}/${date.month}/${date.year}';
//     }
//     return timestamp.toString();
//   }
// } 1

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../controller/admin_master_controller.dart';

// class AdminMasterView extends StatefulWidget {
//   const AdminMasterView({super.key});

//   @override
//   State<AdminMasterView> createState() => _AdminMasterViewState();
// }

// class _AdminMasterViewState extends State<AdminMasterView> {
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedFilter = 'active';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AdminMasterController()..fetchAllRetailers(),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new,
//                 color: Color(0xFF1F2937), size: 18),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Consumer<AdminMasterController>(
//           builder: (context, controller, child) {
//             if (controller.isLoading && controller.retailers.isEmpty) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
//               );
//             }

//             // Filter berdasarkan tombol yang dipilih
//             List<Map<String, dynamic>> filteredRetailers =
//                 controller.filteredRetailers;
//             if (_selectedFilter == 'active') {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] == true)
//                   .toList();
//             } else {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] == false)
//                   .toList();
//             }

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Search Bar ──────────────────────────────────────────
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search retailer',
//                       hintStyle: TextStyle(
//                         fontSize: 14,
//                         fontFamily: 'Inter',
//                         color: Colors.grey[400],
//                       ),
//                       prefixIcon: const Icon(Icons.search,
//                           color: Color(0xFF9CA3AF), size: 20),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xFFF3F4F6),
//                       contentPadding:
//                           const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     onChanged: controller.searchRetailers,
//                   ),
//                 ),

//                 // ── Total Retailers + Toggle Active/Inactive ────────────
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     children: [
//                       // Kotak Total Retailers
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 12),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFF3F4F6),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Total Retailers',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontFamily: 'Inter',
//                                   fontWeight: FontWeight.w400,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 '${controller.retailers.length}',
//                                 style: const TextStyle(
//                                   fontSize: 30,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: 'Inter',
//                                   color: Color(0xFF1F2937),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(width: 12),

//                       // Tombol Active & Inactive (vertikal)
//                       Column(
//                         children: [
//                           _filterButton('Active', 'active'),
//                           const SizedBox(height: 8),
//                           _filterButton('Inactive', 'inactive'),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── List Retailer ───────────────────────────────────────
//                 Expanded(
//                   child: filteredRetailers.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.store_outlined,
//                                   size: 64, color: Colors.grey[400]),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Tidak ada data retailer',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontFamily: 'Inter',
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           padding:
//                               const EdgeInsets.symmetric(horizontal: 20),
//                           itemCount: filteredRetailers.length,
//                           itemBuilder: (context, index) {
//                             final retailer = filteredRetailers[index];
//                             final isActive = retailer['isActive'] == true;
//                             return _retailerCard(
//                                 context, retailer, isActive, controller);
//                           },
//                         ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // ── Widget: Tombol Filter Active / Inactive ───────────────────────────
//   Widget _filterButton(String label, String filter) {
//     final isSelected = _selectedFilter == filter;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedFilter = filter),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 110,
//         padding: const EdgeInsets.symmetric(vertical: 11),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF2E7D32)
//                 : const Color(0xFFD1D5DB),
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               fontFamily: 'Inter',
//               color:
//                   isSelected ? Colors.white : const Color(0xFF6B7280),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Widget: Card Retailer ─────────────────────────────────────────────
//   Widget _retailerCard(
//     BuildContext context,
//     Map<String, dynamic> retailer,
//     bool isActive,
//     AdminMasterController controller,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Baris: ikon toko | info | badge status
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Ikon toko bulat hijau
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF66BB6A),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.storefront_rounded,
//                   color: Colors.white,
//                   size: 22,
//                 ),
//               ),

//               const SizedBox(width: 12),

//               // Nama, Alamat, ID
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       retailer['fullName'] ?? 'Tanpa Nama',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF1F2937),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       retailer['address'] ?? '-',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF9CA3AF),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'ID: ${retailer['id'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF9CA3AF),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 8),

//               // Badge status (tap untuk toggle)
//               GestureDetector(
//                 onTap: () async {
//                   if (isActive) {
//                     final ok = await controller
//                         .disableRetailer(retailer['id']);
//                     if (ok && mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Retailer dinonaktifkan'),
//                           backgroundColor: Colors.orange,
//                           duration: Duration(seconds: 1),
//                         ),
//                       );
//                     }
//                   } else {
//                     final ok =
//                         await controller.enableRetailer(retailer['id']);
//                     if (ok && mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Retailer diaktifkan'),
//                           backgroundColor: Color(0xFF2E7D32),
//                           duration: Duration(seconds: 1),
//                         ),
//                       );
//                     }
//                   }
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isActive
//                         ? const Color(0xFFE8F5E9)
//                         : const Color(0xFFFFEBEE),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.keyboard_arrow_down_rounded,
//                         size: 15,
//                         color: isActive
//                             ? const Color(0xFF2E7D32)
//                             : const Color(0xFFD32F2F),
//                       ),
//                       const SizedBox(width: 2),
//                       Text(
//                         isActive ? 'Active' : 'Inactive',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'Inter',
//                           color: isActive
//                               ? const Color(0xFF2E7D32)
//                               : const Color(0xFFD32F2F),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 14),

//           // Ikon chat di bawah kiri
//           Icon(
//             Icons.chat_bubble_outline_rounded,
//             size: 19,
//             color: Colors.grey[400],
//           ),
//         ],
//       ),
//     );
//   }
// } 2

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../controller/admin_master_controller.dart';

// class AdminMasterView extends StatefulWidget {
//   const AdminMasterView({super.key});

//   @override
//   State<AdminMasterView> createState() => _AdminMasterViewState();
// }

// class _AdminMasterViewState extends State<AdminMasterView> {
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedFilter = 'active';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AdminMasterController()..fetchAllRetailers(),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new,
//                 color: Color(0xFF1F2937), size: 18),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Consumer<AdminMasterController>(
//           builder: (context, controller, child) {
//             if (controller.isLoading && controller.retailers.isEmpty) {
//               return const Center(
//                 child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
//               );
//             }

//             // Filter berdasarkan tombol yang dipilih
//             List<Map<String, dynamic>> filteredRetailers =
//                 controller.filteredRetailers;
//             if (_selectedFilter == 'active') {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] == true)
//                   .toList();
//             } else {
//               filteredRetailers = filteredRetailers
//                   .where((r) => r['isActive'] == false)
//                   .toList();
//             }

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Search Bar ──────────────────────────────────────────
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search retailer',
//                       hintStyle: TextStyle(
//                         fontSize: 14,
//                         fontFamily: 'Inter',
//                         color: Colors.grey[400],
//                       ),
//                       prefixIcon: const Icon(Icons.search,
//                           color: Color(0xFF9CA3AF), size: 20),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xFFF3F4F6),
//                       contentPadding:
//                           const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     onChanged: controller.searchRetailers,
//                   ),
//                 ),

//                 // ── Total Retailers + Active/Inactive ──
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     children: [
//                       // Kotak Total Retailers
//                       SizedBox(
//                         width: 120,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 12),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFF3F4F6),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Total Retailers',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontFamily: 'Inter',
//                                   fontWeight: FontWeight.w400,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 '${controller.retailers.length}',
//                                 style: const TextStyle(
//                                   fontSize: 28,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: 'Inter',
//                                   color: Color(0xFF1F2937),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(width: 16),

//                       // Tombol Active & Inactive (STYLE SESUAI GUI)
//                       Expanded(
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _filterButton('Active', 'active'),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _filterButton('Inactive', 'inactive'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── List Retailer ───────────────────────────────────────
//                 Expanded(
//                   child: filteredRetailers.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.store_outlined,
//                                   size: 64, color: Colors.grey[400]),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Tidak ada data retailer',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontFamily: 'Inter',
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           padding:
//                               const EdgeInsets.symmetric(horizontal: 20),
//                           itemCount: filteredRetailers.length,
//                           itemBuilder: (context, index) {
//                             final retailer = filteredRetailers[index];
//                             final isActive = retailer['isActive'] == true;
//                             return _retailerCard(
//                                 context, retailer, isActive, controller);
//                           },
//                         ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // ── Widget: Tombol Filter Active / Inactive (STYLE SESUAI GUI) ────────
//   Widget _filterButton(String label, String filter) {
//     final isSelected = _selectedFilter == filter;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedFilter = filter),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           // Warna: #48752C dengan opacity 42% (0.42)
//           color: isSelected
//               ? const Color(0xFF48752C).withValues(alpha: 0.42)
//               : Colors.white,
//           borderRadius: BorderRadius.circular(8), // Sudut agak melengkung
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF48752C)
//                 : const Color(0xFFE5E7EB),
//             width: 1,
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               fontFamily: 'Inter',
//               color: isSelected
//                   ? const Color(0xFF2E5C1E)
//                   : const Color(0xFF6B7280),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Widget: Card Retailer ─────────────────────────────────────────────
//   Widget _retailerCard(
//     BuildContext context,
//     Map<String, dynamic> retailer,
//     bool isActive,
//     AdminMasterController controller,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF66BB6A),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.storefront_rounded,
//                   color: Colors.white,
//                   size: 22,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       retailer['fullName'] ?? 'Tanpa Nama',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF1F2937),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       retailer['address'] ?? '-',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF9CA3AF),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'ID: ${retailer['id'] ?? 'N/A'}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'Inter',
//                         color: Color(0xFF9CA3AF),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               GestureDetector(
//                 onTap: () async {
//                   if (isActive) {
//                     final ok = await controller
//                         .disableRetailer(retailer['id']);
//                     if (ok && mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Retailer dinonaktifkan'),
//                           backgroundColor: Colors.orange,
//                           duration: Duration(seconds: 1),
//                         ),
//                       );
//                     }
//                   } else {
//                     final ok =
//                         await controller.enableRetailer(retailer['id']);
//                     if (ok && mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Retailer diaktifkan'),
//                           backgroundColor: Color(0xFF2E7D32),
//                           duration: Duration(seconds: 1),
//                         ),
//                       );
//                     }
//                   }
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isActive
//                         ? const Color(0xFFE8F5E9)
//                         : const Color(0xFFFFEBEE),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.keyboard_arrow_down_rounded,
//                         size: 15,
//                         color: isActive
//                             ? const Color(0xFF2E7D32)
//                             : const Color(0xFFD32F2F),
//                       ),
//                       const SizedBox(width: 2),
//                       Text(
//                         isActive ? 'Active' : 'Inactive',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'Inter',
//                           color: isActive
//                               ? const Color(0xFF2E7D32)
//                               : const Color(0xFFD32F2F),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           Icon(
//             Icons.chat_bubble_outline_rounded,
//             size: 19,
//             color: Colors.grey[400],
//           ),
//         ],
//       ),
//     );
//   }
// } 3

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/admin_master_controller.dart';

class AdminMasterView extends StatefulWidget {
  const AdminMasterView({super.key});

  @override
  State<AdminMasterView> createState() => _AdminMasterViewState();
}

class _AdminMasterViewState extends State<AdminMasterView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // ← UBAH KE 'all' AGAR SEMUA DATA MUNCUL

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminMasterController()..fetchAllRetailers(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1F2937), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<AdminMasterController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.retailers.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              );
            }

            // Filter berdasarkan tombol yang dipilih
            List<Map<String, dynamic>> filteredRetailers =
                controller.filteredRetailers;
            if (_selectedFilter == 'active') {
              filteredRetailers = filteredRetailers
                  .where((r) => r['isActive'] == true)
                  .toList();
            } else if (_selectedFilter == 'inactive') {
              filteredRetailers = filteredRetailers
                  .where((r) => r['isActive'] == false)
                  .toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search retailer',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF9CA3AF), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: controller.searchRetailers,
                  ),
                ),

                // ── Total Retailers + Active/Inactive ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Kotak Total Retailers
                      SizedBox(
                        width: 120,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Retailers',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${controller.retailers.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Tombol Active & Inactive
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _filterButton('Active', 'active'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _filterButton('Inactive', 'inactive'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── List Retailer ───────────────────────────────────────
                Expanded(
                  child: filteredRetailers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data retailer',
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredRetailers.length,
                          itemBuilder: (context, index) {
                            final retailer = filteredRetailers[index];
                            final isActive = retailer['isActive'] == true;
                            return _retailerCard(
                                context, retailer, isActive, controller);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Widget: Tombol Filter Active / Inactive ───────────────────────────
  Widget _filterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF48752C).withValues(alpha: 0.42)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF48752C)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: isSelected
                  ? const Color(0xFF2E5C1E)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget: Card Retailer ─────────────────────────────────────────────
  Widget _retailerCard(
    BuildContext context,
    Map<String, dynamic> retailer,
    bool isActive,
    AdminMasterController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF66BB6A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      retailer['fullName'] ?? 'Tanpa Nama',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      retailer['address'] ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${retailer['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (isActive) {
                    final ok = await controller
                        .disableRetailer(retailer['id']);
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retailer dinonaktifkan'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } else {
                    final ok =
                        await controller.enableRetailer(retailer['id']);
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retailer diaktifkan'),
                          backgroundColor: Color(0xFF2E7D32),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 19,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}