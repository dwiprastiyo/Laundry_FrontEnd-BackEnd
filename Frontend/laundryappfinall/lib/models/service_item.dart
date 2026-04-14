import 'package:flutter/material.dart';
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
  ServiceItem(4, 'Cuci Express', Icons.timer, 'Rp 10.000/kg', 10, Colors.purple[100]!, Colors.purple[600]!),
];
