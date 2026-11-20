import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// Nimo v4.0 Ultra — Full Phone & Installed Apps Management Hub.
class DeviceHubScreen extends ConsumerStatefulWidget {
  const DeviceHubScreen({super.key});

  @override
  ConsumerState<DeviceHubScreen> createState() => _DeviceHubScreenState();
}

class _DeviceHubScreenState extends ConsumerState<DeviceHubScreen> {
  DeviceStatusInfo _status = const DeviceStatusInfo();
  List<InstalledAppInfo> _apps = [];
  String _appFilter = '';
  bool _loadingApps = true;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _refreshDevice();
  }

  Future<void> _refreshDevice() async {
    final bridge = ref.read(nativeBridgeProvider);
    final status = await bridge.getDeviceStatus();
    final apps = await bridge.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _status = status;
      _torchOn = status.torchEnabled;
      _apps = apps;
      _loadingApps = false;
    });
  }

  Future<void> _toggleTorch() async {
    final next = !_torchOn;
    final ok = await ref.read(nativeBridgeProvider).toggleFlashlight(next);
    if (mounted && ok) setState(() => _torchOn = next);
  }

  void _showQuickActionSheet({
    required String title,
    required String field1Label,
    String? field2Label,
    required Future<void> Function(String v1, String v2) onSubmit,
  }) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: c1, decoration: InputDecoration(labelText: field1Label)),
            if (field2Label != null) ...[
              const SizedBox(height: 10),
              TextField(controller: c2, decoration: InputDecoration(labelText: field2Label)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSubmit(c1.text.trim(), c2.text.trim());
            },
            child: Text(isAr ? 'تنفيذ' : 'Run'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final bridge = ref.read(nativeBridgeProvider);
    final theme = Theme.of(context);

    final filteredApps = _appFilter.trim().isEmpty
        ? _apps
        : _apps.where((a) {
            final q = _appFilter.toLowerCase();
            return a.name.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الهاتف والتطبيقات' : 'Phone & Apps Manager'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _refreshDevice,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Live Hardware Telemetry Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const IosIconBadge(
                    icon: CupertinoIcons.device_phone_portrait,
                    color: TalkoraColors.iosBlue,
                    size: 46,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_status.manufacturer} ${_status.model}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Android ${_status.androidVersion} • ${_apps.length} ${isAr ? 'تطبيق مثبت' : 'installed apps'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_status.batteryLevel >= 0)
                    IosStatusPill(
                      label: '${_status.batteryLevel}%',
                      color: _status.batteryLevel > 25 ? TalkoraColors.iosGreen : TalkoraColors.iosRed,
                      icon: _status.isCharging
                          ? CupertinoIcons.battery_charging
                          : CupertinoIcons.battery_75_percent,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Quick Phone Actions Grid
          Text(isAr ? 'أدوات التحكم السريع بالهاتف' : 'Quick Phone Controls', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ControlTile(
                icon: _torchOn ? CupertinoIcons.lightbulb_fill : CupertinoIcons.lightbulb,
                color: _torchOn ? TalkoraColors.iosOrange : TalkoraColors.iosIndigo,
                label: isAr ? (_torchOn ? 'الكشاف: شغال' : 'الكشاف') : 'Flashlight',
                onTap: _toggleTorch,
              ),
              _ControlTile(
                icon: CupertinoIcons.chat_bubble_text_fill,
                color: TalkoraColors.iosGreen,
                label: isAr ? 'رسالة واتساب' : 'WhatsApp',
                onTap: () => _showQuickActionSheet(
                  title: isAr ? 'إرسال واتساب مباشر' : 'Direct WhatsApp',
                  field1Label: isAr ? 'رقم الهاتف (مثال 010...)' : 'Phone number',
                  field2Label: isAr ? 'الرسالة' : 'Message',
                  onSubmit: (p, m) async => bridge.openWhatsApp(phone: p, message: m),
                ),
              ),
              _ControlTile(
                icon: CupertinoIcons.alarm_fill,
                color: TalkoraColors.iosRed,
                label: isAr ? 'ضبط منبه' : 'Set Alarm',
                onTap: () => _showQuickActionSheet(
                  title: isAr ? 'ضبط منبه جديد' : 'Set Alarm',
                  field1Label: isAr ? 'الساعة (مثال 07:30)' : 'Time (HH:MM)',
                  field2Label: isAr ? 'عنوان المنبه' : 'Label',
                  onSubmit: (t, msg) async {
                    final p = t.split(':');
                    final h = int.tryParse(p.isNotEmpty ? p[0] : '7') ?? 7;
                    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
                    await bridge.setAlarm(hour: h, minute: m, message: msg.isEmpty ? 'Nimo' : msg);
                  },
                ),
              ),
              _ControlTile(
                icon: CupertinoIcons.map_pin_ellipse,
                color: TalkoraColors.iosBlue,
                label: isAr ? 'خرائط GPS' : 'Maps GPS',
                onTap: () => _showQuickActionSheet(
                  title: isAr ? 'الانتقال عبر الخرائط' : 'Open Maps',
                  field1Label: isAr ? 'المكان أو العنوان' : 'Place or address',
                  onSubmit: (q, _) async => bridge.openMaps(q, navigate: false),
                ),
              ),
              _ControlTile(
                icon: CupertinoIcons.play_rectangle_fill,
                color: TalkoraColors.iosPink,
                label: isAr ? 'بحث يوتيوب' : 'YouTube',
                onTap: () => _showQuickActionSheet(
                  title: isAr ? 'بحث في يوتيوب' : 'Search YouTube',
                  field1Label: isAr ? 'كلمة البحث' : 'Search query',
                  onSubmit: (q, _) async => bridge.searchYoutube(q),
                ),
              ),
              _ControlTile(
                icon: CupertinoIcons.wifi,
                color: TalkoraColors.iosTeal,
                label: isAr ? 'إعدادات Wi-Fi' : 'Wi-Fi',
                onTap: () => bridge.openSystemSetting('wifi'),
              ),
              _ControlTile(
                icon: CupertinoIcons.bluetooth,
                color: TalkoraColors.iosBlue,
                label: isAr ? 'البلوتوث' : 'Bluetooth',
                onTap: () => bridge.openSystemSetting('bluetooth'),
              ),
              _ControlTile(
                icon: CupertinoIcons.speaker_2_fill,
                color: TalkoraColors.iosPurple,
                label: isAr ? 'الصوت' : 'Sound',
                onTap: () => bridge.openSystemSetting('sound'),
              ),
              _ControlTile(
                icon: CupertinoIcons.gear_solid,
                color: const Color(0xFF636366),
                label: isAr ? 'إعدادات النظام' : 'System',
                onTap: () => bridge.openSystemSetting('main'),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Installed Apps Launcher Section
          Text(
            isAr ? 'جميع تطبيقات الهاتف (${_apps.length})' : 'Installed Phone Apps (${_apps.length})',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _appFilter = v),
            decoration: InputDecoration(
              hintText: isAr ? 'ابحث عن أي تطبيق لفتحه فوراً...' : 'Search any installed app to launch...',
              prefixIcon: const Icon(CupertinoIcons.search),
            ),
          ),
          const SizedBox(height: 10),

          if (_loadingApps)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (filteredApps.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isAr
                      ? 'لا توجد تطبيقات مطابقة — يمكنك أيضاً فتح أي تطبيق بالصوت من المحادثة اللايف.'
                      : 'No matching apps found.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            IosGroupedSection(
              children: filteredApps.take(80).map((app) {
                return IosSettingsRow(
                  icon: CupertinoIcons.app_badge_fill,
                  iconColor: theme.colorScheme.primary,
                  title: app.name,
                  subtitle: app.packageName,
                  onTap: () => bridge.launchApp(app.packageName),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IosIconBadge(icon: icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
