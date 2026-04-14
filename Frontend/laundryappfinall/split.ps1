$lines = Get-Content -Path .\laundry

function Write-Part {
    param($Start, $End, $Path, $Imports)
    $part = $lines[($Start-1)..($End-1)]
    $content = $Imports + "`n" + ($part -join "`n")
    Set-Content -Path $Path -Value $content
}

# 1. Models
Write-Part -Start 403 -End 420 -Path ".\lib\models\service_item.dart" -Imports "import 'package:flutter/material.dart';"

# Auth Screens
Write-Part -Start 33 -End 97 -Path ".\lib\screens\auth\welcome_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport 'phone_screen.dart';"
Write-Part -Start 99 -End 180 -Path ".\lib\screens\auth\phone_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport 'otp_screen.dart';"
Write-Part -Start 182 -End 261 -Path ".\lib\screens\auth\otp_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport 'register_screen.dart';"
Write-Part -Start 263 -End 347 -Path ".\lib\screens\auth\register_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport '../main_screen.dart';"

# Main Screen
Write-Part -Start 353 -End 397 -Path ".\lib\screens\main_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport 'home/home_screen.dart';`nimport 'tracking/tracking_screen.dart';`nimport 'loyalty/loyalty_screen.dart';`nimport 'profile/profile_screen.dart';"

# Home Screen
Write-Part -Start 422 -End 634 -Path ".\lib\screens\home\home_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport '../../models/service_item.dart';`nimport '../order/order_flow_screen.dart';"

# Order Flow Screen
Write-Part -Start 640 -End 976 -Path ".\lib\screens\order\order_flow_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport '../../models/service_item.dart';"

# Other Screens
Write-Part -Start 982 -End 1093 -Path ".\lib\screens\tracking\tracking_screen.dart" -Imports "import 'package:flutter/material.dart';"
Write-Part -Start 1099 -End 1245 -Path ".\lib\screens\loyalty\loyalty_screen.dart" -Imports "import 'package:flutter/material.dart';"
Write-Part -Start 1251 -End 1298 -Path ".\lib\screens\profile\profile_screen.dart" -Imports "import 'package:flutter/material.dart';`nimport '../auth/welcome_screen.dart';"

# Main.dart (since file starts with import, we prepend the needed import and let the rest flow)
Write-Part -Start 1 -End 27 -Path ".\lib\main.dart" -Imports "import 'screens/auth/welcome_screen.dart';"
