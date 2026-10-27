import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/validators.dart';
import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:alburdat_dashboard/data/repositories/settings_repository.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/link_status.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> openConnectionSettings(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ConnectionSettingsPage()),
  );
}

/// Formulir koneksi broker + ID alat. Password disimpan di secure storage
/// dan tidak pernah ditampilkan ulang.
class ConnectionSettingsPage extends StatefulWidget {
  const ConnectionSettingsPage({super.key});

  @override
  State<ConnectionSettingsPage> createState() => _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deviceId;
  late final TextEditingController _host;
  late final TextEditingController _tcpPort;
  late final TextEditingController _wsPort;
  late final TextEditingController _wsPath;
  late final TextEditingController _username;
  final _password = TextEditingController();

  late bool _useTls;
  bool _hasStoredPassword = false;
  bool _clearPassword = false;
  bool _obscure = true;
  bool _saving = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<DeviceService>().config;
    _deviceId = TextEditingController(text: c.deviceId);
    _host = TextEditingController(text: c.host);
    _tcpPort = TextEditingController(text: '${c.tcpPort}');
    _wsPort = TextEditingController(text: '${c.wsPort}');
    _wsPath = TextEditingController(text: c.wsPath);
    _username = TextEditingController(text: c.username);
    _useTls = c.useTls;
    context.read<SettingsRepository>().hasPassword().then((has) {
      if (mounted) setState(() => _hasStoredPassword = has);
    });
  }

  @override
  void dispose() {
    for (final c in [_deviceId, _host, _tcpPort, _wsPort, _wsPath, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  BrokerConfig _draft() => BrokerConfig(
    deviceId: _deviceId.text.trim(),
    host: _host.text.trim(),
    tcpPort: int.tryParse(_tcpPort.text.trim()) ?? BrokerConfig.defaults.tcpPort,
    wsPort: int.tryParse(_wsPort.text.trim()) ?? BrokerConfig.defaults.wsPort,
    wsPath: _wsPath.text.trim().isEmpty ? '/mqtt' : _wsPath.text.trim(),
    useTls: _useTls,
    username: _username.text.trim(),
  );

  void _toggleTls(bool v) {
    setState(() {
      _useTls = v;
      // Sesuaikan port bawaan bila pengguna belum mengubahnya.
      if (_tcpPort.text == '1883' || _tcpPort.text == '8883') _tcpPort.text = v ? '8883' : '1883';
      if (_wsPort.text == '8083' || _wsPort.text == '8084') _wsPort.text = v ? '8084' : '8083';
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft();

    if (!draft.useTls) {
      final proceed = await showConfirmSheet(
        context,
        title: 'Simpan tanpa TLS?',
        message: 'Tanpa TLS, data dan password broker dikirim tanpa enkripsi dan dapat disadap di jaringan.',
        confirmLabel: 'Tetap simpan',
        destructive: true,
        icon: Icons.lock_open_rounded,
      );
      if (!proceed || !mounted) return;
    }

    final password = _clearPassword ? '' : (_password.text.isEmpty ? null : _password.text);
    setState(() => _saving = true);
    try {
      await context.read<DeviceService>().applyConfig(draft, password: password);
      if (!mounted) return;
      showAppSnack(context, 'Tersimpan. Menghubungkan ke ${draft.host}…', tone: Tone.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showAppSnack(context, 'Gagal menyimpan pengaturan', tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final link = LinkStatus.of(device);
    final t = Theme.of(context).textTheme;
    final draft = _draft();
    final willHavePassword = !_clearPassword && (_password.text.isNotEmpty || _hasStoredPassword);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi alat'),
        actions: [
          IconButton(
            tooltip: 'Panduan',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => openGuide(context, GuideTopic.connection),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: () => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
              children: [
                InfoBanner(message: '${link.label} · ${link.detail}', tone: link.tone, icon: link.icon),
                const SizedBox(height: Gap.md),
                AppCard(
                  color: AppColors.surfaceRaised,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Identitas alat', subtitle: 'Tertera pada label alat atau layar OLED'),
                      const SizedBox(height: Gap.lg),
                      TextFormField(
                        controller: _deviceId,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                          LengthLimitingTextInputFormatter(32),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'ID alat',
                          hintText: 'mis. FC-7Q2K9',
                          prefixIcon: Icon(Icons.qr_code_2_rounded),
                        ),
                        validator: Validators.deviceId,
                      ),
                      const SizedBox(height: Gap.sm),
                      Text(
                        Validators.deviceId(draft.deviceId) == null
                            ? 'Topik: ${draft.statusTopic}'
                            : 'Topik: ${AppConfig.topicPrefix}/<ID>/status',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.md),
                AppCard(
                  color: AppColors.surfaceRaised,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Broker MQTT', subtitle: 'Harus sama dengan yang dipakai alat'),
                      const SizedBox(height: Gap.lg),
                      TextFormField(
                        controller: _host,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Alamat broker', prefixIcon: Icon(Icons.dns_outlined)),
                        validator: Validators.host,
                      ),
                      const SizedBox(height: Gap.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _useTls,
                        onChanged: _toggleTls,
                        title: Text('Enkripsi TLS', style: t.titleMedium),
                        subtitle: Text(_useTls ? 'Disarankan — koneksi terenkripsi' : 'Tidak aman', style: t.bodySmall),
                      ),
                      const SizedBox(height: Gap.sm),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Username (opsional)', prefixIcon: Icon(Icons.person_outline_rounded)),
                        validator: (v) => Validators.optionalText(v, max: 64),
                      ),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        enabled: !_clearPassword,
                        decoration: InputDecoration(
                          labelText: 'Password (opsional)',
                          hintText: _hasStoredPassword ? '•••••• tersimpan — isi untuk mengganti' : null,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => Validators.optionalText(v, max: 128),
                      ),
                      if (_hasStoredPassword)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _clearPassword,
                          onChanged: (v) => setState(() {
                            _clearPassword = v ?? false;
                            if (_clearPassword) _password.clear();
                          }),
                          title: Text('Hapus password tersimpan', style: t.bodyMedium),
                        ),
                      const SizedBox(height: Gap.sm),
                      if (!_useTls)
                        const InfoBanner(
                          tone: Tone.danger,
                          message: 'Tanpa TLS, siapa pun di jaringan dapat membaca dan meniru perintah.',
                        )
                      else if (draft.username.isEmpty || !willHavePassword)
                        const InfoBanner(
                          tone: Tone.warning,
                          message: 'Tanpa username & password, orang lain yang mengetahui ID alat dapat mengirim perintah.',
                        )
                      else
                        const InfoBanner(tone: Tone.success, message: 'Koneksi terenkripsi dan terautentikasi.'),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.md),
                AppCard(
                  color: AppColors.surfaceRaised,
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    initiallyExpanded: _showAdvanced,
                    onExpansionChanged: (v) => setState(() => _showAdvanced = v),
                    title: Text('Lanjutan', style: t.titleMedium),
                    subtitle: Text('Port TCP ${draft.tcpPort} · WebSocket ${draft.wsPort}', style: t.bodySmall),
                    childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                    children: [
                      TextFormField(
                        controller: _tcpPort,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Port TCP',
                          helperText: kIsWeb ? 'Tidak dipakai di web' : 'Android, iOS, desktop',
                        ),
                        validator: Validators.port,
                      ),
                      const SizedBox(height: Gap.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _wsPort,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Port WebSocket',
                                helperText: kIsWeb ? 'Dipakai di web' : 'Khusus versi web',
                              ),
                              validator: Validators.port,
                            ),
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: TextFormField(
                              controller: _wsPath,
                              autocorrect: false,
                              decoration: const InputDecoration(labelText: 'Path WebSocket'),
                              validator: (v) => Validators.optionalText(v, max: 64),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.link_rounded),
                  label: const Text('Simpan & hubungkan'),
                ),
                if (device.state != LinkState.notConfigured) ...[
                  const SizedBox(height: Gap.sm),
                  OutlinedButton.icon(
                    onPressed: device.isConnecting ? null : device.reconnectNow,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Sambungkan ulang sekarang'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
