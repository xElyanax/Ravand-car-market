import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'api_setup_sheet.dart';
import 'widgets/brand_mark.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tokenController = TextEditingController();
  bool _obscure = true;
  bool _working = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _openApiSetup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ApiSetupSheet(controller: widget.controller),
    );
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    if (_tokenController.text.trim().isEmpty || _working) return;

    setState(() => _working = true);
    final connected = await widget.controller.connectWithToken(
      _tokenController.text,
    );

    if (!mounted) return;
    setState(() => _working = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? 'اتصال برقرار شد و داده‌های زنده دریافت شدند.'
              : widget.controller.errorMessage ??
                  'اتصال برقرار نشد؛ توکن یا دسترسی شبکه را بررسی کنید.',
        ),
      ),
    );
  }

  Future<void> _useDemo() async {
    if (_working) return;

    setState(() => _working = true);
    await widget.controller.useDemoMode();

    if (!mounted) return;
    setState(() => _working = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('توکن حذف شد و حالت نمایشی فعال شد.'),
      ),
    );
  }

  Future<void> _refresh() async {
    if (_working) return;

    setState(() => _working = true);
    await widget.controller.refresh();

    if (!mounted) return;
    setState(() => _working = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('داده‌ها به‌روزرسانی شدند.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        actions: [
          IconButton(
            tooltip: 'به‌روزرسانی داده‌ها',
            onPressed: _working ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandMark.lockup(showTagline: true),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'وضعیت اتصال',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'منبع داده',
                    value: _sourceLabel(widget.controller.source),
                  ),
                  _InfoRow(
                    label: 'توکن ذخیره‌شده',
                    value: widget.controller.hasToken ? 'دارد' : 'ندارد',
                  ),
                  _InfoRow(
                    label: 'آخرین دریافت',
                    value: widget.controller.fetchedAt == null
                        ? 'نامشخص'
                        : widget.controller.fetchedAt!.toLocal().toString(),
                  ),
                  _InfoRow(
                    label: 'حالت فعلی',
                    value: widget.controller.isDemo
                        ? 'نمایشی'
                        : widget.controller.isCached
                            ? 'کش'
                            : 'شبکه',
                  ),
                  if (widget.controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.controller.errorMessage!,
                      style: TextStyle(color: cs.error),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'مدیریت توکن',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'توکن API',
                      hintText: 'توکن جدید را وارد کنید',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'نمایش توکن' : 'پنهان کردن توکن',
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _working ? null : _connect,
                    icon: _working
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(
                      _working ? 'در حال بررسی...' : 'ذخیره و تست اتصال',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _working ? null : _openApiSetup,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('باز کردن صفحه اتصال اولیه'),
                  ),
                  if (widget.controller.hasToken) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _working ? null : _useDemo,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('حذف توکن و استفاده از حالت نمایشی'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _sourceLabel(dynamic source) {
    final value = source?.toString().split('.').last ?? 'unknown';
    switch (value) {
      case 'network':
        return 'شبکه';
      case 'cache':
        return 'کش';
      case 'demo':
        return 'نمایشی';
      default:
        return value;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
