# QR Konum Uygulaması

Flutter tabanlı QR okuyucu + SVG harita konum göstericisi.

---

## Kurulum

### 1. Bağımlılıkları yükle
```bash
flutter pub get
```

### 2. SVG krokisini yerleştir
`assets/kroki.svg` dosyanı projeye koy.  
SVG'nin orijinal viewBox boyutları `FloorPlanWidget` içindeki sabitlerle eşleşmeli:

```dart
// lib/widgets/floor_plan_widget.dart
static const double svgWidth = 800.0;   // SVG viewBox genişliği
static const double svgHeight = 600.0;  // SVG viewBox yüksekliği
```

SVG'nin gerçek viewBox'una göre bu değerleri güncelle.

### 3. API URL'ini güncelle
```dart
// lib/services/location_service.dart
static const String _baseUrl = 'https://api.site.com';
```

### 4. Android kamera izni (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 5. iOS kamera izni (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>QR kodu okumak için kamera gereklidir</string>
```

---

## Klasör Yapısı

```
lib/
├── main.dart
├── models/
│   ├── location_model.dart       # API response modeli
│   └── exceptions.dart           # Özel exception sınıfları
├── services/
│   └── location_service.dart     # HTTP API servisi
├── screens/
│   ├── home_screen.dart          # Ana ekran (harita + buton)
│   └── qr_scanner_screen.dart    # QR kamera ekranı
└── widgets/
    ├── floor_plan_widget.dart    # SVG + marker overlay
    ├── pulse_marker.dart         # Animasyonlu kırmızı marker
    └── location_info_bar.dart    # Alt konum bilgi çubuğu
assets/
└── kroki.svg                     # Bina krokisi (senin dosyan)
```

---

## Koordinat Sistemi

Backend'den gelen `x`, `y` değerleri **SVG koordinat uzayında** olmalıdır.  
`FloorPlanWidget`, bu koordinatları ekran boyutuna otomatik olarak ölçekler:

```
ekran_x = svg_x * (ekran_genişliği / svgWidth)
ekran_y = svg_y * (ekran_yüksekliği / svgHeight)
```

---

## API Kontratı

```
GET https://api.site.com/location/{locationId}

Response 200:
{
  "id": "A12",
  "name": "Sol Koridor",
  "x": 120,
  "y": 340
}

Response 404: → LocationNotFoundException gösterilir
Response 5xx: → ApiException snackbar gösterilir
```

---

## Test (Geliştirme Ortamı)

`HomeScreen` AppBar'ındaki `⋮` menüsünden test konum ID'leri seçilebilir.  
Üretime geçmeden önce bu menüyü kaldır.
