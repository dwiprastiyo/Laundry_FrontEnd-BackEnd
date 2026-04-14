import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _currentStep = 0;
  Timer? _timer;
  bool _hasActiveOrder = false;
  bool _isLoading = true;
  String _activeOrderId = '';

  @override
  void initState() {
    super.initState();
  Future<void> _checkActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    bool active = prefs.getBool('has_active_order') ?? false;
    setState(() {
      _hasActiveOrder = active;
      _activeOrderId = prefs.getString('active_order_id') ?? 'ORD-0000';
      _isLoading = false;
    });

    if (active) {
      _startDemoSimulation();
    }
  }

  Future<void> _completeOrder() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Simpan history sebelum menghapus active order
    String rService = prefs.getString('active_service_name') ?? 'Layanan Spesial';
    int rWeight = prefs.getInt('active_order_weight') ?? 1;
    int rPrice = prefs.getInt('active_order_price') ?? 0;
    String rId = prefs.getString('active_order_id') ?? 'ORD-0000';
    
    List<String> histList = prefs.getStringList('history_orders') ?? [];
    DateTime now = DateTime.now();
    List<String> months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    String dateStr = '${now.day.toString().padLeft(2,'0')} ${months[now.month-1]} ${now.year}';
    
    Map<String, dynamic> historyEntry = {
      'orderId': rId,
      'service': '$rService ($rWeight kg)',
      'date': dateStr,
      'price': rPrice == 0 ? 'Rp 0' : 'Rp $rPrice.000',
    };
    histList.insert(0, jsonEncode(historyEntry));
    await prefs.setStringList('history_orders', histList);

    await prefs.setBool('has_active_order', false);
    
    int rewardsCount = prefs.getInt('rewards_count') ?? 0;
    rewardsCount++;
    if (rewardsCount >= 10) {
      rewardsCount = 0;
      int freeVouchers = prefs.getInt('free_vouchers') ?? 0;
      await prefs.setInt('free_vouchers', freeVouchers + 1);
      String lastService = prefs.getString('active_service_name') ?? 'Layanan Spesial';
      await prefs.setString('voucher_service_type', lastService);
    }
    await prefs.setInt('rewards_count', rewardsCount);

    if (mounted) {
      // Delay sebentar untuk menunjukkan tulisan selesai sebelum restart
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _hasActiveOrder = false;
            _currentStep = 0;
          });
        }
      });
    }
  }

  void _startDemoSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentStep < 4) {
          _currentStep++;
          if (_currentStep == 4) {
            timer.cancel(); // Stop here and process rewards
            _completeOrder();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconColor = isDone ? Colors.white : (isCurrent ? Colors.blue[600]! : Colors.grey[500]!);
    Color bgColor = isDone ? Colors.blue[600]! : (isCurrent ? Colors.blue[100]! : Colors.grey[200]!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [if (isCurrent) BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)],
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? Colors.blue[600] : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 4),
              child: Opacity(
                opacity: (isDone || isCurrent) ? 1.0 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCurrent ? Colors.blue[600] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (!_hasActiveOrder) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Belum ada pesanan.', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Silakan buat pesanan baru melalui tab Beranda.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: const Text(
              'Lacak Pesanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ID Pesanan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(_activeOrderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            FutureBuilder<SharedPreferences>(
                              future: SharedPreferences.getInstance(),
                              builder: (context, snapshot) {
                                if(snapshot.hasData) {
                                  bool usedVoucher = snapshot.data!.getBool('active_order_free') ?? false;
                                  return Text(usedVoucher ? 'Rp 0' : 'Menyesuaikan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[600]));
                                }
                                return Text('...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[600]));
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildTimelineItem(
                      icon: Icons.check,
                      title: 'Pesanan Dibuat',
                      subtitle: '10:30 WIB, Hari ini',
                      isDone: _currentStep > 0,
                      isCurrent: _currentStep == 0,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.directions_bike,
                      title: 'Kurir Menjemput',
                      subtitle: 'Posisi kurir sedang menuju letak Anda',
                      isDone: _currentStep > 1,
                      isCurrent: _currentStep == 1,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.local_laundry_service,
                      title: 'Sedang Dicuci (Proses)',
                      subtitle: 'Pakaian sedang dicuci dan disetrika',
                      isDone: _currentStep > 2,
                      isCurrent: _currentStep == 2,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.local_shipping,
                      title: 'Kurir Mengantar',
                      subtitle: 'Kurir sedang dalam perjalanan',
                      isDone: _currentStep > 3,
                      isCurrent: _currentStep == 3,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.check_circle,
                      title: 'Pesanan Selesai',
                      subtitle: _currentStep == 4 ? 'Cucian telah diterima (Otomatis ditutup)' : 'Cucian telah diterima',
                      isDone: _currentStep == 4,
                      isCurrent: _currentStep == 4,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
