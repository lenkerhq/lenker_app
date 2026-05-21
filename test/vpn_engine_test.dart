import 'package:flutter_test/flutter_test.dart';
import 'package:lenker_app/models/subscription.dart';
import 'package:lenker_app/services/vpn_engine.dart';

void main() {
  final entry = AccessEntry(
    protocol: 'vless',
    address: 'node1.example.com',
    port: 8443,
    uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    flow: 'xtls-rprx-vision',
    security: 'reality',
    sni: 'www.microsoft.com',
    fingerprint: 'chrome',
    publicKey: 'test-public-key-abc123',
    shortId: 'ab12',
    node: RegionNode(id: 'n1', name: 'Frankfurt', region: 'EU', countryCode: 'DE'),
  );

  group('VpnEngine.generateConfig', () {
    test('produces valid sing-box structure', () {
      final config = VpnEngine.generateConfig(entry);

      final inbounds = config['inbounds'] as List;
      expect(inbounds[0]['type'], 'tun');

      final outbounds = config['outbounds'] as List;
      expect(outbounds[0]['type'], 'vless');
      expect(outbounds[0]['server'], 'node1.example.com');
      expect(outbounds[0]['server_port'], 8443);
      expect(outbounds[0]['uuid'], 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(outbounds[0]['flow'], 'xtls-rprx-vision');

      final tls = outbounds[0]['tls'] as Map<String, dynamic>;
      expect(tls['server_name'], 'www.microsoft.com');
      expect((tls['reality'] as Map)['public_key'], 'test-public-key-abc123');
      expect((tls['reality'] as Map)['short_id'], 'ab12');

      final route = config['route'] as Map<String, dynamic>;
      expect(route['auto_detect_interface'], true);
    });

    test('maps AccessEntry fields to sing-box keys correctly', () {
      final config = VpnEngine.generateConfig(entry);
      final vless = (config['outbounds'] as List)[0] as Map<String, dynamic>;

      // address → server
      expect(vless['server'], entry.address);
      // port → server_port
      expect(vless['server_port'], entry.port);
      // publicKey → tls.reality.public_key
      expect((vless['tls']['reality'] as Map)['public_key'], entry.publicKey);
      // shortId → tls.reality.short_id
      expect((vless['tls']['reality'] as Map)['short_id'], entry.shortId);
      // sni → tls.server_name
      expect(vless['tls']['server_name'], entry.sni);
      // fingerprint → tls.utls.fingerprint
      expect((vless['tls']['utls'] as Map)['fingerprint'], entry.fingerprint);
    });
  });
}
