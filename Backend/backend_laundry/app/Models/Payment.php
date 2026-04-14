<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model // <-- Pastikan class ininya benar
{
    // Tambahkan ini
    protected $fillable = [
        'order_id',          // INI YANG PALING PENTING
        'method',
        'amount',
        'status'
    ];
    
    // (Lanjutkan dengan kode yang sudah ada)
}