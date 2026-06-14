import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Конвертация координат WGS-84 (GPS) → GCJ-02 (китайский стандарт).
/// В Китае публичные карты (Amap) используют GCJ-02 со смещением ~100-700м.
/// В БД храним WGS-84, на карте Amap показываем GCJ-02.
class CoordUtils {
  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  static bool _outOfChina(double lng, double lat) {
    return !(lng > 73.66 && lng < 135.05 && lat > 3.86 && lat < 53.55);
  }

  static double _transformLat(double lng, double lat) {
    double ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat +
        0.1 * lng * lat + 0.2 * sqrt(lng.abs());
    ret += (20.0 * sin(6.0 * lng * pi) + 20.0 * sin(2.0 * lng * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(lat * pi) + 40.0 * sin(lat / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(lat / 12.0 * pi) + 320 * sin(lat * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double lng, double lat) {
    double ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng +
        0.1 * lng * lat + 0.1 * sqrt(lng.abs());
    ret += (20.0 * sin(6.0 * lng * pi) + 20.0 * sin(2.0 * lng * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(lng * pi) + 40.0 * sin(lng / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(lng / 12.0 * pi) + 300.0 * sin(lng / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }

  /// WGS-84 → GCJ-02
  static LatLng wgs84ToGcj02(double lat, double lng) {
    if (_outOfChina(lng, lat)) return LatLng(lat, lng);
    double dLat = _transformLat(lng - 105.0, lat - 35.0);
    double dLng = _transformLng(lng - 105.0, lat - 35.0);
    final double radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    final double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * pi);
    return LatLng(lat + dLat, lng + dLng);
  }
}
