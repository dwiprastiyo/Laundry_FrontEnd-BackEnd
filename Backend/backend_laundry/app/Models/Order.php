<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
protected $fillable = [
    'user_id', 
    'service_type', 
    'total_price', 
    'payment_method', 
    'use_reward'
];
}
