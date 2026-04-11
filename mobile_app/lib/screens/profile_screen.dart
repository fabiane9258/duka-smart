import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../services/profile_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.embedded = false,
    this.onProfileSaved,
  });

  final bool embedded;
  final VoidCallback? onProfileSaved;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _details = TextEditingController();

  ShopProfile _draft = ShopProfile();
  bool _loading = true;
  bool _saving = false;
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final p = await ProfileStore.load();
    if (!mounted) return;
    final settings = AppSettingsScope.of(context);
    setState(() {
      _draft = p;
      _name.text = p.ownerName;
      _shop.text = p.shopName;
      _phone.text = p.phone;
      _email.text = p.email;
      _details.text = p.businessDetails;
      _languageCode = settings.locale.languageCode == 'sw' ? 'sw' : 'en';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _shop.dispose();
    _phone.dispose();
    _email.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final s = AppStrings.of(context);
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.photoWebUnsupported)),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final dest = File('${dir.path}/shop_logo.jpg');
      await File(picked.path).copy(dest.path);
      setState(() {
        _draft = _draft.copyWith(logoImagePath: dest.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  void _removeImage() {
    final path = _draft.logoImagePath;
    if (!kIsWeb && path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    setState(() {
      _draft = _draft.copyWith(clearLogo: true);
    });
  }

  Future<void> _save() async {
    final s = AppStrings.of(context);
    setState(() => _saving = true);
    try {
      final updated = ShopProfile(
        ownerName: _name.text.trim(),
        shopName: _shop.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        businessDetails: _details.text.trim(),
        logoImagePath: _draft.logoImagePath,
      );
      await ProfileStore.save(updated);
      await AppSettingsScope.of(context).setLocale(
        Locale(_languageCode == 'sw' ? 'sw' : 'en'),
      );
      if (!mounted) return;
      widget.onProfileSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profileSaved)),
      );
      setState(() => _draft = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _avatar(AppStrings s) {
    final path = _draft.logoImagePath;
    final hasFile = !kIsWeb &&
        path != null &&
        path.isNotEmpty &&
        File(path).existsSync();
    return CircleAvatar(
      radius: 44,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundImage: hasFile ? FileImage(File(path!)) : null,
      child: !hasFile
          ? Icon(
              Icons.storefront_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }

  Widget _body(AppStrings s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              _avatar(s),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(s.changePhoto),
                  ),
                  if (_draft.logoImagePath != null)
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(s.removePhoto),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.profileTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          s.profileIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: s.ownerName,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _shop,
          decoration: InputDecoration(
            labelText: s.shopName,
            prefixIcon: const Icon(Icons.store_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: s.contactPhone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: s.contactEmail,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _details,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: s.businessDetails,
            hintText: s.businessDetailsHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Text(s.language, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'en', label: Text(s.langEnglish)),
            ButtonSegment(value: 'sw', label: Text(s.langSwahili)),
          ],
          selected: {_languageCode},
          onSelectionChanged: (set) {
            setState(() => _languageCode = set.first);
          },
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(s.saveProfile),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final body = _body(s);
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.navProfile)),
      body: body,
    );
  }
}
