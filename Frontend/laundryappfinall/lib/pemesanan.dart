import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'tabberanda.dart';
import 'services/order_service.dart';

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

  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingLocation = false;

  int _freeVouchers = 0;
  String _voucherServiceType = '';
  bool _useVoucher = false;

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
    _addressController.text = '';
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _freeVouchers = prefs.getInt('free_vouchers') ?? 0;
      _voucherServiceType = prefs.getString('voucher_service_type') ?? '';
      
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

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan lokasi tidak aktif di HP Anda.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin akses lokasi ditolak.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak secara permanen. Mohon ubah melalui pengaturan HP.';
      }

      // Gunakan desiredAccuracy best untuk mendapatkan akurasi murni GPS tinggi
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String streetName = place.street ?? '';
          if (streetName.isEmpty && place.name != null) {
              streetName = place.name!;
          }
          String address = [
              streetName,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.postalCode
          ].where((e) => e != null && e.isNotEmpty).join(", ");
          
          setState(() {
            _addressController.text = address;
          });
        } else {
          setState(() {
            _addressController.text = "GPS: ${position.latitude}, ${position.longitude}";
          });
        }
      } catch (geocodeError) {
        setState(() {
          _addressController.text = "Kordinat GPS: ${position.latitude}, ${position.longitude}";
        });
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: widget.service.bgColor, borderRadius: BorderRadius.circular(8)),
                          child: Icon(widget.service.icon, color: widget.service.iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.service.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    const Expanded(
                      child: Text('Tambahkan (Max 8kg)', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
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
                      onTap: () => setState(() {
                        _deliveryMode = 2;
                      }),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_deliveryMode == 1 ? Icons.location_on : Icons.storefront, color: Colors.blue[600], size: 18), 
                      const SizedBox(width: 8), 
                      Text(_deliveryMode == 1 ? 'Detail Alamat Anda' : 'Lokasi Outlet', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_deliveryMode == 1)
                    TextButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 14),
                      label: Text(_isLoadingLocation ? 'Mendeteksi...' : 'Radar GPS', style: const TextStyle(fontSize: 12)),
                    )
                ],
              ),
              const SizedBox(height: 12),
              if (_deliveryMode == 1)
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ketik alamat manual atau gunakan fitur Radar GPS...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[300]!)),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_outlets[_selectedOutletIndex]['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_outlets[_selectedOutletIndex]['address']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _showOutletSelection,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text('+ Ubah Outlet', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () {
              if (_deliveryMode == 1 && _addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan masukkan alamat atau gunakan GPS')));
                return;
              }
              setState(() => _step = 3);
            },
            child: const Text('Lanjutkan ke Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStep3() {
    int total = _weight * widget.service.basePrice;
    if (_useVoucher) {
      total = 0;
    }

    bool isVoucherValid = _freeVouchers > 0 && widget.service.name == _voucherServiceType;

    return Column(
      children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isVoucherValid ? const LinearGradient(colors: [Colors.green, Colors.teal]) : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isVoucherValid ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.stars, color: isVoucherValid ? Colors.white : Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voucher Cuci Gratis', style: TextStyle(color: isVoucherValid ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        _freeVouchers > 0 
                          ? (isVoucherValid ? 'Pakai 1x Cuci Gratis Anda' : 'Berlaku khusus untuk $_voucherServiceType') 
                          : 'Kumpulkan 10 Pesanan untuk 1x gratis',
                        style: TextStyle(color: isVoucherValid ? Colors.white70 : Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useVoucher,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green[800],
                  onChanged: isVoucherValid ? (val) {
                    setState(() {
                      _useVoucher = val;
                      if (_useVoucher) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher diterapkan! Biaya menjadi Rp 0')));
                      }
                    });
                  } : null,
                )
              ],
            ),
          ),
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
                  Text(_useVoucher ? 'Rp 0 (GRATIS)' : 'Rp ${(_weight * widget.service.basePrice)}.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, decoration: _useVoucher ? TextDecoration.lineThrough : null)),
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
              int? userId = prefs.getInt('profile_id');

              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi pengguna tidak valid. Silakan login ulang.')));
                return;
              }

              // Show loading bar internally through state ideally, but we can just use the Service first
              String paymentStr = _paymentMethod == 1 ? 'SeaBank/ShopeePay' 
                                : _paymentMethod == 2 ? 'QRIS' 
                                : 'Cash';
              
              // Simpan alamat jika menggunakan mode Kurir (1)
              if (_deliveryMode == 1) {
                await OrderService().saveAddress(userId, 'Alamat Pengiriman', _addressController.text.trim());
              }

              // Buat pesanan ke database
              final apiResponse = await OrderService().createOrder(
                userId, 
                widget.service.name, 
                _useVoucher ? 0 : total, 
                paymentStr, 
                _useVoucher
              );

              if (apiResponse['success'] == true) {
                // SINKRONISASI POIN DARI SERVER
                int currentPoints = int.tryParse(apiResponse['points']?.toString() ?? '0') ?? 0;
                int freeV = (currentPoints / 10).floor();
                int remainingProgress = currentPoints % 10;
                
                await prefs.setInt('free_vouchers', freeV);
                await prefs.setInt('rewards_count', remainingProgress);

                if (_useVoucher) {
                  await prefs.setBool('active_order_free', true);
                } else {
                  await prefs.setBool('active_order_free', false);
                }

                await prefs.setBool('has_active_order', true);
                await prefs.setString('active_service_name', widget.service.name);
                await prefs.setInt('active_order_weight', _weight);
                await prefs.setInt('active_order_price', _useVoucher ? 0 : total);
                await prefs.setString('active_order_id', apiResponse['order_id']?.toString() ?? 'ORD-${Random().nextInt(9000)+1000}');
                await prefs.setInt('active_order_time', DateTime.now().millisecondsSinceEpoch);
                
                if (mounted) {
                  // Tampilkan Notifikasi Sukses yang lebih jelas
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 80),
                          const SizedBox(height: 16),
                          const Text('Pesanan Selesai!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Pesanan Anda telah berhasil dibuat dan disimpan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Tutup dialog
                                Navigator.pop(context, true); // Kembali ke Home
                              },
                              child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
              } else {
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: ${apiResponse['message']}')));
                 }
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
