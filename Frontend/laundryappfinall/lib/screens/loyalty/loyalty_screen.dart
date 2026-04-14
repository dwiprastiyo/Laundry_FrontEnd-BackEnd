import 'package:flutter/material.dart';
class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  final int currentOrdersCount = 7;
  final int ordersForFree = 10;
  final int freeVouchers = 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gratis 1x Cuci!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Berlaku untuk maks 5kg Cuci & Lipat', style: TextStyle(color: Colors.white70, fontSize: 10)),
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
                                const SnackBar(content: Text('Voucher 1x Cuci berhasil digunakan!')),
                              );
                            },
                            child: const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    );
  }
}
