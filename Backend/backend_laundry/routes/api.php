<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache; // <--- WAJIB TAMBAHKAN INI
use App\Models\User;
use App\Models\Order;
use App\Models\Address;
use App\Models\Payment;

// 1. Request OTP (Random)
Route::post('/request-otp', function (Request $request) {
    if (!$request->phone) return response()->json(['success'=>false, 'message'=>'Nomor wajib diisi']);
    
    // Generate nomor acak (random) 4 digit dari 1000 sampai 9999
    $randomOtp = rand(1000, 9999);
    
    // Simpan OTP sementara di memori server (Cache) selama 5 menit, diikat dengan nomor HP-nya
    Cache::put('otp_' . $request->phone, $randomOtp, now()->addMinutes(5));

    // Kirim kembali nomor OTP-nya agar Flutter bisa menampilkannya di SnackBar/Notifikasi
    return response()->json([
        'success' => true, 
        'otp' => (string)$randomOtp, 
        'message' => 'OTP terkirim'
    ]);
});

// 2. Verifikasi OTP (Pengecekan)
Route::post('/verify-otp', function (Request $request) {
    // Ambil OTP yang tersimpan tadi dari dalam memori (Cache)
    $savedOtp = Cache::get('otp_' . $request->phone);

    // Cek apakah ada OTP yang tersimpan DAN nilainya cocok dengan yang diketik user
    if ($savedOtp && $savedOtp == $request->otp) { 
        
        // Hapus (Lupakan) OTP dari memori agar tidak bisa dipakai 2 kali (demi keamanan)
        Cache::forget('otp_' . $request->phone);
        
        return response()->json(['success' => true, 'message' => 'Verifikasi berhasil']);
    }
    
    return response()->json(['success' => false, 'message' => 'Kode OTP salah atau sudah kadaluarsa!']);
});

Route::post('/register', function (Request $request) {
    $request->validate([
        'name' => 'required',
        'phone' => 'required|unique:users',
        'password' => 'required|min:6'
    ]);

    $user = User::create([
        'name' => $request->name,
        'phone' => $request->phone,
        'password' => Hash::make($request->password),
    ]);

    return response()->json(['success' => true, 'message' => 'Akun berhasil dibuat']);
});

Route::post('/login', function (Request $request) {
    $username = $request->username;
    
    // Pengecekan cerdas: cari berdasarkan phone ATAU name
    $user = User::where('phone', $username)
                ->orWhere('name', $username)
                ->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json(['success' => false, 'message' => 'Nama/Nomor atau Password salah.']);
    }

    return response()->json(['success' => true, 'message' => 'Berhasil masuk', 'user' => $user]);
});

// 1. Simpan Alamat Baru User
Route::post('/address', function(Request $request) {
    $address = Address::create([
        'user_id' => clone $request->user_id, // Nanti dikirim dari flutter
        'title' => $request->title,
        'full_address' => $request->full_address,
    ]);
    return response()->json(['success' => true, 'data' => $address]);
});

// 2. Buat Pesanan Baru
Route::post('/order', function(Request $request) {
    $user = User::find($request->user_id);
    $price = $request->total_price;
    $isFree = false;

    // Cek Jika poin sudah 10 (Gratis)
    if ($user->laundry_points >= 10 && $request->use_reward == true) {
        $price = 0;
        $isFree = true;
        // Reset poin setelah dipakai
        $user->laundry_points = $user->laundry_points - 10; 
    } else {
        // Jika bayar normal, tambah poin (+1)
        $user->laundry_points += 1;
    }
    $user->save();

    $order = Order::create([
        'user_id' => $user->id,
        'service_type' => $request->service_type,
        'total_price' => $price,
        'is_free_reward' => $isFree
    ]);

    // Simpan data Pembayaran
    Payment::create([
        'order_id' => $order->id,
        'method' => $request->payment_method,
        'amount' => $price,
        'status' => $isFree ? 'success' : 'pending' // kalau gratis, langsung success
    ]);

    return response()->json(['success' => true, 'message' => 'Pesanan Berhasil Dibuat!', 'points' => $user->laundry_points]);
});

// 3. Ambil Profile & Total Point terkini
Route::get('/user/{id}', function($id) {
    $user = User::find($id);
    return response()->json(['success' => true, 'data' => $user]);
});

// 4. Ambil Riwayat Pesanan Berdasarkan User ID
Route::get('/user/{id}/orders', function($id) {
    // Ambil data order berurut dari yang paling baru
    $orders = App\Models\Order::where('user_id', $id)
                    ->orderBy('created_at', 'desc')
                    ->get();
                    
    return response()->json([
        'success' => true, 
        'data' => $orders
    ]);
});