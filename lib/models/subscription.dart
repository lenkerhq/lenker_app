class SubscriptionAccess {
  final String subscriptionId;
  final String planName;
  final String status;
  final String expiresAt;
  final int trafficUsedBytes;
  final int? trafficLimitBytes;
  final int deviceLimit;
  final List<AccessEntry> entries;

  SubscriptionAccess({
    required this.subscriptionId,
    required this.planName,
    required this.status,
    required this.expiresAt,
    required this.trafficUsedBytes,
    this.trafficLimitBytes,
    required this.deviceLimit,
    required this.entries,
  });

  factory SubscriptionAccess.fromJson(Map<String, dynamic> json) {
    return SubscriptionAccess(
      subscriptionId: json['subscription_id'] as String,
      planName: json['plan_name'] as String? ?? '',
      status: json['status'] as String,
      expiresAt: json['expires_at'] as String? ?? '',
      trafficUsedBytes: json['traffic_used_bytes'] as int? ?? 0,
      trafficLimitBytes: json['traffic_limit_bytes'] as int?,
      deviceLimit: json['device_limit'] as int? ?? 1,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => AccessEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AccessEntry {
  final String protocol;
  final String address;
  final int port;
  final String uuid;
  final String flow;
  final String security;
  final String sni;
  final String fingerprint;
  final String publicKey;
  final String shortId;
  final RegionNode node;

  AccessEntry({
    required this.protocol,
    required this.address,
    required this.port,
    required this.uuid,
    required this.flow,
    required this.security,
    required this.sni,
    required this.fingerprint,
    required this.publicKey,
    required this.shortId,
    required this.node,
  });

  factory AccessEntry.fromJson(Map<String, dynamic> json) {
    final endpoint = json['endpoint'] as Map<String, dynamic>? ?? {};
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final nodeJson = json['node'] as Map<String, dynamic>? ?? {};
    return AccessEntry(
      protocol: json['protocol'] as String? ?? 'vless',
      address: endpoint['address'] as String? ?? '',
      port: endpoint['port'] as int? ?? 443,
      uuid: client['id'] as String? ?? '',
      flow: client['flow'] as String? ?? '',
      security: endpoint['security'] as String? ?? '',
      sni: endpoint['sni'] as String? ?? '',
      fingerprint: endpoint['fingerprint'] as String? ?? '',
      publicKey: endpoint['public_key'] as String? ?? '',
      shortId: endpoint['short_id'] as String? ?? '',
      node: RegionNode.fromJson(nodeJson),
    );
  }
}

class RegionNode {
  final String id;
  final String name;
  final String region;
  final String countryCode;

  RegionNode({
    required this.id,
    required this.name,
    required this.region,
    required this.countryCode,
  });

  factory RegionNode.fromJson(Map<String, dynamic> json) {
    return RegionNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
    );
  }
}
