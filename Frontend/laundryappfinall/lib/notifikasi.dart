import 'package:flutter/material.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Contoh data notifikasi
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Pesanan Selesai!',
        'message': 'Cucian Anda dengan No. Pesanan #12345 telah selesai dan siap diantar/diambil.',
        'time': '10 Menit yang lalu',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'isRead': false,
      },
      {
        'title': 'Promo Spesial Cuci Kilat',
        'message': 'Diskon 20% untuk semua layanan cuci kilat hari ini. Gunakan kode DISKON20!',
        'time': '2 Jam yang lalu',
        'icon': Icons.local_offer_outlined,
        'color': Colors.orange,
        'isRead': false,
      },
      {
        'title': 'Pesanan Sedang Diproses',
        'message': 'Cucian Anda No. Pesanan #12346 sedang dalam proses pencucian kami.',
        'time': '1 Hari yang lalu',
        'icon': Icons.local_laundry_service_outlined,
        'color': Colors.blue,
        'isRead': true,
      },
      {
        'title': 'Selamat Datang!',
        'message': 'Terima kasih telah menggunakan aplikasi layanan Laundry kami.',
        'time': '3 Hari yang lalu',
        'icon': Icons.waving_hand_outlined,
        'color': Colors.indigo,
        'isRead': true,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  decoration: BoxDecoration(
                    color: notif['isRead']
                        ? Theme.of(context).cardColor
                        : (isDark ? Colors.grey[800] : Colors.blue[50]),
                    borderRadius: BorderRadius.circular(16),
                    border: notif['isRead']
                        ? Border.all(
                            color: isDark ? Colors.transparent : Colors.grey[200]!,
                          )
                        : Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.blue[100]!,
                          ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (notif['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notif['icon'],
                          color: notif['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'],
                                    style: TextStyle(
                                      fontWeight: notif['isRead']
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notif['time'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif['message'],
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
