import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'pemesanan.dart';

class ServiceItem {
  final int id;
  final String name;
  final IconData icon;
  final String price;
  final int basePrice;
  final Color bgColor;
  final Color iconColor;

  ServiceItem(this.id, this.name, this.icon, this.price, this.basePrice, this.bgColor, this.iconColor);
}

final List<ServiceItem> services = [
  ServiceItem(1, 'Cuci Basah', Icons.local_laundry_service, 'Rp 4.000/kg', 4, Colors.blue[100]!, Colors.blue[600]!),
  ServiceItem(2, 'Cuci Kering', Icons.air, 'Rp 6.000/kg', 6, Colors.cyan[100]!, Colors.cyan[600]!),
  ServiceItem(3, 'Cuci Setrika', Icons.dry_cleaning, 'Rp 8.000/kg', 8, Colors.indigo[100]!, Colors.indigo[600]!),
  ServiceItem(4, 'Cuci Ekspres', Icons.timer, 'Rp 10.000/kg', 10, Colors.purple[100]!, Colors.purple[600]!),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentOrdersCount = 0;
  final int ordersForFree = 10;
  bool hasActiveOrder = false;
  String userName = 'Pengguna';
  String activeOrderId = '';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Selamat Pagi,';
    if (hour >= 12 && hour < 15) return 'Selamat Siang,';
    if (hour >= 15 && hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  bool _isStoreClosed() {
    final hour = DateTime.now().hour;
    return hour >= 0 && hour < 5; // 00:00 to 04:59
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        currentOrdersCount = prefs.getInt('rewards_count') ?? 0;
        hasActiveOrder = prefs.getBool('has_active_order') ?? false;
        userName = prefs.getString('profile_name') ?? 'Pengguna';
        activeOrderId = prefs.getString('active_order_id') ?? 'ORD-0000';
      });
    }
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              const Text('Rincian Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('No. Pesanan', style: TextStyle(color: Colors.grey)), Text(activeOrderId, style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Layanan', style: TextStyle(color: Colors.grey)), Text('Layanan Laundry', style: TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Status', style: TextStyle(color: Colors.grey)), Text('Sedang Diproses', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold))]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                      ),
                      child: Stack(
                        children: [
                          Icon(Icons.notifications_none, color: Colors.grey[700], size: 28),
                          if (hasActiveOrder)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              ),
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Loyalty Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.cyan[500]!]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Program Loyalitas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$currentOrdersCount', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                const Text(' / 10', style: TextStyle(color: Colors.white, fontSize: 16)),
                                const Text(' Pesanan', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentOrdersCount / ordersForFree,
                        backgroundColor: Colors.blue[800]?.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${ordersForFree - currentOrdersCount} pesanan lagi untuk Gratis 1x Cuci!', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Order (Only visible if hasActiveOrder is true)
              if (hasActiveOrder) ...[
                GestureDetector(
                  onTap: () => _showOrderDetails(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pesanan Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
                              child: Text('Sedang Diproses', style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                              child: Icon(Icons.local_laundry_service, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pesanan $activeOrderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Text('Buka Lacak Pesanan untuk info', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Services
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Layanan Kami', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              if (_isStoreClosed())
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bedtime, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text('Mohon Maaf, Toko Sedang Tutup', style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Waktu operasional Laundry adalah 05:00 - 23:59. Silakan kembali lagi di jam buka ya!', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400], fontSize: 12)),
                    ],
                  ),
                )
              else
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final s = services[index];
                    return GestureDetector(
                      onTap: () async {
                        // Return true from OrderFlowScreen sets reload
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderFlowScreen(service: s)));
                        if (result == true) {
                          _loadData();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: s.bgColor, shape: BoxShape.circle),
                              child: Icon(s.icon, color: s.iconColor, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(s.price, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}