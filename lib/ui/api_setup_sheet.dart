import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'widgets/brand_mark.dart';

class ApiSetupSheet extends StatefulWidget {
  const ApiSetupSheet({super.key, required this.controller});

  final AppController controller;

  @override
  State<ApiSetupSheet> createState() => _ApiSetupSheetState();
}

class _ApiSetupSheetState extends State<ApiSetupSheet> {
  final _tokenController = TextEditingController();
  bool _obscure = true;
  bool _working = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(24, 12, 24, 24 + bottom),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const BrandMark.lockup(showTagline: true),
              const SizedBox(height: 26),
              Text(
                'اتصال مستقیم به SourceArena',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'توکن را وارد کن تا قیمت‌های زنده و تاریخچه مستقیماً از API دریافت شوند. در نبود توکن، اپ با داده‌ی نمایشی کامل قابل بررسی است.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _tokenController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => _connect(),
                decoration: InputDecoration(
                  labelText: 'توکن API',
                  hintText: '••••••••••••••••••••••••••••••••',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'نمایش توکن' : 'پنهان کردن توکن',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _working ? null : _connect,
                icon: _working
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_rounded),
                label: Text(
                  _working ? 'در حال بررسی اتصال…' : 'اتصال و دریافت داده',
                ),
              ),
              if (widget.controller.hasToken) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _working ? null : _useDemo,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('حذف توکن و استفاده از حالت نمایشی'),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'در اپ بدون بک‌اند، توکن به‌طور کامل قابل مخفی‌سازی نیست. توکن واردشده فقط روی همین دستگاه ذخیره می‌شود؛ برای انتشار عمومی از کلید محدودشده استفاده کن.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (_tokenController.text.trim().isEmpty || _working) return;
    setState(() => _working = true);
    final connected = await widget.controller.connectWithToken(
      _tokenController.text,
    );
    if (!mounted) return;
    setState(() => _working = false);
    if (connected) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اتصال برقرار شد؛ داده‌های زنده دریافت شدند.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ??
                'اتصال برقرار نشد؛ توکن یا دسترسی شبکه را بررسی کنید.',
          ),
        ),
      );
    }
  }

  Future<void> _useDemo() async {
    setState(() => _working = true);
    await widget.controller.useDemoMode();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
