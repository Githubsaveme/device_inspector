import '../utils/safe_parser.dart';
import '../utils/validators.dart';

/// Network interface details and status.
class NetworkInfo {
  /// Name of the network interface (e.g. "wlan0", "eth0", "en0").
  final String? interfaceName;

  /// Interface medium type (e.g., "wifi", "ethernet", "cellular", "loopback", "vpn").
  final String? interfaceType;

  /// Operational state (e.g., "up", "down", "connected", "disconnected").
  final String? status;

  /// Primary IPv4 address assigned to this interface.
  final String? ipv4Address;

  /// Primary IPv6 address assigned to this interface.
  final String? ipv6Address;

  /// Estimated link speed in Mbps.
  final int? linkSpeedMbps;

  /// Hardware MAC address (where permitted by OS privacy restrictions).
  final String? macAddress;

  const NetworkInfo({
    this.interfaceName,
    this.interfaceType,
    this.status,
    this.ipv4Address,
    this.ipv6Address,
    this.linkSpeedMbps,
    this.macAddress,
  });

  /// Creates a [NetworkInfo] from a native Map response.
  factory NetworkInfo.fromMap(Map<String, dynamic> map) {
    return NetworkInfo(
      interfaceName: SafeParser.parseString(map['interfaceName']),
      interfaceType: SafeParser.parseString(map['interfaceType']),
      status: SafeParser.parseString(map['status']),
      ipv4Address: SafeParser.parseString(map['ipv4Address']),
      ipv6Address: SafeParser.parseString(map['ipv6Address']),
      linkSpeedMbps: Validators.validateNonNegativeInt(SafeParser.parseInt(map['linkSpeedMbps'])),
      macAddress: SafeParser.parseString(map['macAddress']),
    );
  }

  /// Converts this model to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'interfaceName': interfaceName,
      'interfaceType': interfaceType,
      'status': status,
      'ipv4Address': ipv4Address,
      'ipv6Address': ipv6Address,
      'linkSpeedMbps': linkSpeedMbps,
      'macAddress': macAddress,
    };
  }

  NetworkInfo copyWith({
    String? interfaceName,
    String? interfaceType,
    String? status,
    String? ipv4Address,
    String? ipv6Address,
    int? linkSpeedMbps,
    String? macAddress,
  }) {
    return NetworkInfo(
      interfaceName: interfaceName ?? this.interfaceName,
      interfaceType: interfaceType ?? this.interfaceType,
      status: status ?? this.status,
      ipv4Address: ipv4Address ?? this.ipv4Address,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      linkSpeedMbps: linkSpeedMbps ?? this.linkSpeedMbps,
      macAddress: macAddress ?? this.macAddress,
    );
  }

  @override
  String toString() => 'NetworkInfo(interface: $interfaceName, type: $interfaceType, ipv4: $ipv4Address)';
}
