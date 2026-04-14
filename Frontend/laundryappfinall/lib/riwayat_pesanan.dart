import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/order_service.dart';

class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('profile_id');
    
    if (userId == null) {
      if (mounted) {
         setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final response = await OrderService().getOrderHistory(userId);
      if (response['success'] == true && response['data'] != null) {
        List<dynamic> serverData = response['data'];
        
        List<Map<String, dynamic>> apiHistory = serverData.map((order) {
           return {
             'orderId': 'ORD-${order['id']}',
             'service': order['service_type']?.toString() ?? 'Layanan Laundry',
             'date': order['created_at'] != null ? order['created_at'].toString().split('T')[0] : 'Baru Saja',
             'price': 'Rp ${order['total_price']}.000',
             'status': 'Selesai',
           };
        }).toList();
        
        if (mounted) {
          setState(() {
            _historyList = apiHistory;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Riwayat Pesanan', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Belum ada riwayat', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    return _buildHistoryCard(
                      context, 
                      item['orderId'] ?? 'ORD-0000', 
                      item['service'] ?? 'Layanan Laundry', 
                      item['date'] ?? 'Sempat Berlalu', 
                      item['price'] ?? 'Rp 0'
                    );
                  },
                ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, String orderId, String service, String date, String price) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.green[900]?.withOpacity(0.3) : Colors.green[50], shape: BoxShape.circle),
            child: Icon(Icons.check_circle, color: isDark ? Colors.green[400] : Colors.green[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(orderId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(service, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Selesai', style: TextStyle(color: isDark ? Colors.green[400] : Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
