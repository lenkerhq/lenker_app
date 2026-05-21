import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/connection_state.dart';
import '../models/subscription.dart';

class VpnEngine extends ChangeNotifier {
  AppConnectionState _state = AppConnectionState.disconnected;
  String? _lastError;
  Process? _process;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  String? _configPath;

  AppConnectionState get state => _state;
  String? get lastError => _lastError;

  Future<void> connect(AccessEntry entry) async {
    if (_state == AppConnectionState.connecting ||
        _state == AppConnectionState.connected) {
      return;
    }

    _setState(AppConnectionState.connecting);
    _lastError = null;
    _reconnectAttempts = 0;

    try {
      final singBoxPath = await _findSingBox();
      if (singBoxPath == null) {
        _fail('sing-box not found. Install with: brew install sing-box');
        return;
      }

      await _writeConfig(entry);
      await _startProcess(singBoxPath);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts; // prevent auto-reconnect
    await _stopProcess();
    _setState(AppConnectionState.disconnected);
  }

  Future<String?> _findSingBox() async {
    final result = await Process.run('which', ['sing-box']);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  }

  Future<void> _writeConfig(AccessEntry entry) async {
    final dir = await getApplicationSupportDirectory();
    _configPath = '${dir.path}/sing-box-config.json';
    final config = generateConfig(entry);
    final file = File(_configPath!);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(config));
    // Restrict permissions
    await Process.run('chmod', ['600', _configPath!]);
  }

  Future<void> _startProcess(String singBoxPath) async {
    final script =
        '$singBoxPath run -c ${_configPath!}';
    _process = await Process.start(
      'osascript',
      ['-e', 'do shell script "$script" with administrator privileges'],
      environment: {'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'},
    );

    // Give sing-box a moment to start or fail
    var started = false;
    final errBuf = StringBuffer();

    _process!.stderr.transform(utf8.decoder).listen((data) {
      errBuf.write(data);
    });

    _process!.stdout.transform(utf8.decoder).listen((data) {
      // osascript outputs nothing on success for long-running processes
      if (!started && _state == AppConnectionState.connecting) {
        started = true;
        _setState(AppConnectionState.connected);
      }
    });

    _process!.exitCode.then((code) {
      _process = null;
      if (_state == AppConnectionState.connected ||
          _state == AppConnectionState.connecting) {
        if (_reconnectAttempts < _maxReconnectAttempts) {
          _scheduleReconnect();
        } else {
          _fail(errBuf.isNotEmpty ? errBuf.toString() : 'sing-box exited ($code)');
        }
      }
    });

    // Wait briefly to detect immediate failures
    await Future.delayed(const Duration(seconds: 2));
    if (_state == AppConnectionState.connecting && _process != null) {
      _setState(AppConnectionState.connected);
    }
  }

  void _scheduleReconnect() {
    _setState(AppConnectionState.connecting);
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer = Timer(delay, () async {
      if (_state != AppConnectionState.connecting) return;
      final singBoxPath = await _findSingBox();
      if (singBoxPath != null && _configPath != null) {
        try {
          await _startProcess(singBoxPath);
        } catch (e) {
          _fail(e.toString());
        }
      }
    });
  }

  Future<void> _stopProcess() async {
    if (_process == null) return;
    // osascript spawns sing-box as root; kill via pkill
    await Process.run(
      'osascript',
      ['-e', 'do shell script "pkill -f sing-box" with administrator privileges'],
    );
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    _cleanupConfig();
  }

  void _cleanupConfig() {
    if (_configPath != null) {
      try {
        File(_configPath!).deleteSync();
      } catch (_) {}
      _configPath = null;
    }
  }

  void _setState(AppConnectionState s) {
    _state = s;
    notifyListeners();
  }

  void _fail(String msg) {
    _lastError = msg;
    _setState(AppConnectionState.error);
    _cleanupConfig();
  }

  @visibleForTesting
  static Map<String, dynamic> generateConfig(AccessEntry entry) {
    return {
      'inbounds': [
        {
          'type': 'tun',
          'interface_name': 'lenker0',
          'inet4_address': '172.19.0.1/30',
          'auto_route': true,
          'strict_route': true,
          'stack': 'system',
        }
      ],
      'outbounds': [
        {
          'type': 'vless',
          'tag': 'proxy',
          'server': entry.address,
          'server_port': entry.port,
          'uuid': entry.uuid,
          'flow': entry.flow,
          'tls': {
            'enabled': true,
            'server_name': entry.sni,
            'utls': {'enabled': true, 'fingerprint': entry.fingerprint},
            'reality': {
              'enabled': true,
              'public_key': entry.publicKey,
              'short_id': entry.shortId,
            },
          },
        },
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
      ],
      'route': {
        'auto_detect_interface': true,
        'rules': [
          {'geoip': ['private'], 'outbound': 'direct'},
        ],
      },
    };
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _stopProcess();
    super.dispose();
  }
}
