import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/service_item.dart';

class OrderFlowScreen extends StatefulWidget {
  final ServiceItem service;
  const OrderFlowScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<OrderFlowScreen> createState() => _OrderFlowScreenState();
}

class _OrderFlowScreenState extends State<OrderFlowScreen> {
  int _step = 1; // 1: Berat, 2: Alamat, 3: Bayar
  int _weight = 1;
  int _paymentMethod = 1; // 1: SeaBank/ShopeePay, 2: QRIS, 3: Cash
  int _deliveryMode = 1; // 1: Kurir, 2: Antar ke Outlet

  int _selectedOutletIndex = 0;
  List<Map<String, String>> _outlets = [
    {
      'name': 'Laundry App Pusat',
      'address': 'Jl. Jendral Sudirman No. 1, Jakarta Pusat',
    },
    {
      'name': 'Laundry App Cabang Selatan',
      'address': 'Jl. Kemang Raya No. 45, Jakarta Selatan',
    },
    {
      'name': 'Laundry App Cabang Barat',
      'address': 'Jl. Kebon Jeruk No. 10, Jakarta Barat',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? savedOutlets = prefs.getString('custom_outlets');
      if (savedOutlets != null) {
        List<dynamic> decoded = jsonDecode(savedOutlets);
        _outlets = decoded.map((e) => Map<String, String>.from(e)).toList();
      }
    });
  }

  Future<void> _saveOutlets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_outlets', jsonEncode(_outlets));
  }

  void _showAddEditOutletDialog({int? index}) {
    final nameController = TextEditingController(text: index != null ? _outlets[index]['name'] : '');
    final addressController = TextEditingController(text: index != null ? _outlets[index]['address'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index != null ? 'Edit Outlet' : 'Tambah Outlet Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Outlet', hintText: 'Contoh: Laundry Pilihan Saya'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap', hintText: 'Contoh: Jl. Merdeka No 10'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            if (index != null && _outlets.length > 1)
              TextButton(
                onPressed: () async {
                  setState(() {
                    if (_selectedOutletIndex == index) {
                      _selectedOutletIndex = 0;
                    } else if (_selectedOutletIndex > index) {
                      _selectedOutletIndex--;
                    }
                    _outlets.removeAt(index);
                  });
                  await _saveOutlets();
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close bottom sheet
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan Alamat tidak boleh kosong')));
                  return;
                }
                setState(() {
                  if (index != null) {
                    _outlets[index] = {
                      'name': nameController.text.trim(),
                      'address': addressController.text.trim(),
                    };
                  } else {
                    _outlets.add({
                      'name': nameController.text.trim(),
                      'address': addressController.text.trim(),
                    });
                    _selectedOutletIndex = _outlets.length - 1; // auto-select new outlet
                  }
                });
                await _saveOutlets();
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close bottom sheet
              },
              child: const Text('Simpan'),
            )
          ],
        );
      }
    );
  }

  void _showOutletSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Outlet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton.icon(
                    onPressed: () => _showAddEditOutletDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Baru'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _outlets.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.storefront, color: _selectedOutletIndex == index ? Colors.blue[600] : Colors.grey),
                      title: Text(_outlets[index]['name']!, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOutletIndex == index ? Colors.blue[600] : Colors.black87)),
                      subtitle: Text(_outlets[index]['address']!, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                            onPressed: () => _showAddEditOutletDialog(index: index),
                          ),
                          if (_selectedOutletIndex == index)
                            Icon(Icons.check_circle, color: Colors.blue[600]),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedOutletIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 2, color: _step >= 2 ? Colors.blue[600] : Colors.grey[300])),
              Expanded(child: Container(height: 2, color: _step >= 3 ? Colors.blue[600] : Colors.grey[300])),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepCircle(1),
              _buildStepCircle(2),
              _buildStepCircle(3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNum) {
    bool isActive = _step >= stepNum;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[600] : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? Colors.blue[600]! : Colors.grey[300]!, width: 2),
      ),
      child: Text(
        '$stepNum',
        style: TextStyle(color: isActive ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        title: Text(
          _step == 1 ? 'Pilih Layanan' : _step == 2 ? 'Pengiriman' : 'Pembayaran',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 1 ? _buildStep1() : _step == 2 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: widget.service.bgColor, borderRadius: BorderRadius.circular(8)),
                        child: Icon(widget.service.icon, color: widget.service.iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(widget.service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(widget.service.price, style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tambahkan (Max 8kg)', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() { if (_weight > 1) _weight--; }),
                          child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]), child: const Icon(Icons.remove, size: 16)),
                        ),
                        SizedBox(width: 40, child: Text('$_weight', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        InkWell(
                          onTap: () => setState(() { if (_weight < 8) _weight++; }),
                          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.blue[600], shape: BoxShape.circle), child: const Icon(Icons.add, size: 16, color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),

            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => setState(() => _step = 2),
            child: const Text('Lanjutkan ke Alamat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metode Penyerahan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _deliveryMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _deliveryMode == 1 ? Colors.blue[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _deliveryMode == 1 ? Colors.blue[600]! : Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bike, size: 16, color: _deliveryMode == 1 ? Colors.blue[600] : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Kurir', style: TextStyle(color: _deliveryMode == 1 ? Colors.blue[700] : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _deliveryMode = 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _deliveryMode == 2 ? Colors.blue[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _deliveryMode == 2 ? Colors.blue[600]! : Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront, size: 16, color: _deliveryMode == 2 ? Colors.blue[600] : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Outlet', style: TextStyle(color: _deliveryMode == 2 ? Colors.blue[700] : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(_deliveryMode == 1 ? Icons.location_on : Icons.storefront, color: Colors.blue[600], size: 18), 
                  const SizedBox(width: 8), 
                  Text(_deliveryMode == 1 ? 'Lokasi Penjemputan' : 'Lokasi Outlet', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_deliveryMode == 1 ? 'Rumah - Budi Santoso' : _outlets[_selectedOutletIndex]['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_deliveryMode == 1 ? 'Jl. Merdeka No. 45, RT 01/RW 02, Jakarta Selatan, 12345' : _outlets[_selectedOutletIndex]['address']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _deliveryMode == 1 
                    ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu Ubah Alamat diklik'))); }
                    : _showOutletSelection,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: Text(_deliveryMode == 1 ? '+ Ubah Alamat' : '+ Ubah Outlet', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold, fontSize: 12))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => setState(() => _step = 3),
            child: const Text('Lanjutkan ke Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStep3() {
    int total = _weight * widget.service.basePrice;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.service.name} ($_weight kg)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Rp $total.000', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Biaya Jemput & Antar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Gratis', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rp $total.000', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = 1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _paymentMethod == 1 ? Colors.blue[50] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentMethod == 1 ? Colors.blue[600]! : Colors.grey[200]!, width: _paymentMethod == 1 ? 2 : 1)),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('SeaBank/ShopeePay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _paymentMethod == 1 ? Colors.white : Colors.transparent, border: Border.all(color: _paymentMethod == 1 ? Colors.blue[600]! : Colors.grey[300]!, width: _paymentMethod == 1 ? 5 : 2))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _paymentMethod == 2 ? Colors.blue[50] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentMethod == 2 ? Colors.blue[600]! : Colors.grey[200]!, width: _paymentMethod == 2 ? 2 : 1)),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _paymentMethod == 2 ? Colors.white : Colors.transparent, border: Border.all(color: _paymentMethod == 2 ? Colors.blue[600]! : Colors.grey[300]!, width: _paymentMethod == 2 ? 5 : 2))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = 3),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _paymentMethod == 3 ? Colors.blue[50] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentMethod == 3 ? Colors.blue[600]! : Colors.grey[200]!, width: _paymentMethod == 3 ? 2 : 1)),
                  child: Row(
                    children: [
                      Icon(Icons.money, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Pembayaran Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _paymentMethod == 3 ? Colors.white : Colors.transparent, border: Border.all(color: _paymentMethod == 3 ? Colors.blue[600]! : Colors.grey[300]!, width: _paymentMethod == 3 ? 5 : 2))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              
              await prefs.setBool('active_order_free', false);
              await prefs.setBool('has_active_order', true);
              await prefs.setString('active_service_name', widget.service.name);
              await prefs.setInt('active_order_weight', _weight);
              await prefs.setInt('active_order_price', total);
              await prefs.setString('active_order_id', 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
              await prefs.setInt('active_order_time', DateTime.now().millisecondsSinceEpoch);
              
              if (mounted) {
                Navigator.pop(context, true); // Kembali ke Home dan trigger reload
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat! Cek tab Pesanan untuk lacak status secara real-time.')));
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Konfirmasi Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )
      ],
    );
  }
}
