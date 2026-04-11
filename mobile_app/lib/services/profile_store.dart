import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Business and owner details stored on device (JSON + optional image path).
class ShopProfile {
  String ownerName;
  String shopName;
  String phone;
  String email;
  String businessDetails;
  /// Local file path to shop logo / profile photo (non-web).
  String? logoImagePath;

  ShopProfile({
    this.ownerName = '',
    this.shopName = '',
    this.phone = '',
    this.email = '',
    this.businessDetails = '',
    this.logoImagePath,
  });

  Map<String, dynamic> toJson() => {
        'ownerName': ownerName,
        'shopName': shopName,
        'phone': phone,
        'email': email,
        'businessDetails': businessDetails,
        'logoImagePath': logoImagePath,
      };

  factory ShopProfile.fromJson(Map<String, dynamic>? j) {
    if (j == null) return ShopProfile();
    return ShopProfile(
      ownerName: j['ownerName'] as String? ?? '',
      shopName: j['shopName'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      email: j['email'] as String? ?? '',
      businessDetails: j['businessDetails'] as String? ?? '',
      logoImagePath: j['logoImagePath'] as String?,
    );
  }

  ShopProfile copyWith({
    String? ownerName,
    String? shopName,
    String? phone,
    String? email,
    String? businessDetails,
    String? logoImagePath,
    bool clearLogo = false,
  }) {
    return ShopProfile(
      ownerName: ownerName ?? this.ownerName,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessDetails: businessDetails ?? this.businessDetails,
      logoImagePath: clearLogo ? null : (logoImagePath ?? this.logoImagePath),
    );
  }
}

class ProfileStore {
  static const _kProfile = 'shop_profile_v1';
  static const _kLegacyName = 'shopkeeper_name';

  static Future<ShopProfile> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kProfile);
    if (raw != null && raw.isNotEmpty) {
      try {
        return ShopProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    final legacy = p.getString(_kLegacyName)?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      return ShopProfile(ownerName: legacy);
    }
    return ShopProfile();
  }

  static Future<void> save(ShopProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kProfile, jsonEncode(profile.toJson()));
    await p.setString(_kLegacyName, profile.ownerName.trim());
  }

  static Future<String?> ownerDisplayName() async {
    final o = (await load()).ownerName.trim();
    return o.isEmpty ? null : o;
  }
}
