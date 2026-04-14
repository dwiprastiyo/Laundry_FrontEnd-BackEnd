import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/order_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int currentOrdersCount = 0;
  final int ordersForFree = 10;
  int freeVouchers = 0;
  String voucherServiceType = 'Semua Layanan';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchersData();
  }

  Future<void> _loadVouchersData() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('profile_id');

    if (userId != null) {
      // Ambil data profile terbaru dari server untuk sinkronisasi Point
      try {
        final response = await OrderService().getUserProfile(userId);
        if (response['success'] == true && response['data'] != null) {
          int laundryPoints = int.tryParse(response['data']['laundry_points']?.toString() ?? '0') ?? 0;
          
          // Konversi Poin Server ke UI Flutter
          // Setiap 10 poin = 1 voucher gratis
          int calculatedVouchers = (laundryPoints / 10).floor();
          int currentProgress = laundryPoints % 10;

          await prefs.setInt('rewards_count', currentProgress);
          await prefs.setInt('free_vouchers', calculatedVouchers);
        }
      } catch (e) {
        // Abaikan error jaringan saat render offline
      }
    }

    if (mounted) {
      setState(() {
        currentOrdersCount = prefs.getInt('rewards_count') ?? 0;
        freeVouchers = prefs.getInt('free_vouchers') ?? 0;
        voucherServiceType = prefs.getString('voucher_service_type') ?? 'Semua Layanan';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadVouchersData,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text('Progress Cuci Gratis', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$currentOrdersCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text(' / 10', style: TextStyle(fontSize: 24, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Kumpulkan 10 pesanan untuk 1x cuci gratis!', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 24),
                  
                  // Visual Stamp Card Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: ordersForFree,
                      itemBuilder: (context, index) {
                        bool isEarned = index < currentOrdersCount;
                        return Container(
                          decoration: BoxDecoration(
                            color: isEarned ? Colors.white : Colors.blue[800]?.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: isEarned 
                            ? Icon(Icons.check_circle, color: Colors.blue[600])
                            : Text('${index + 1}', style: TextStyle(color: Colors.blue[200], fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voucher Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    if (freeVouchers > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.local_laundry_service, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded( // Use Expanded directly
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Gratis $voucherServiceType', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Anda punya $freeVouchers Voucher', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voucher otomatis dipakai saat memesan cuci di Beranda.')),
                                );
                              },
                              child: const Text('Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.local_laundry_service, color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Gratis 1x Cuci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Selesaikan ${ordersForFree - currentOrdersCount} pesanan lagi', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                              child: const Text('Terkunci', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}