/// Supported CPU architectures.
enum CpuArchitecture {
  arm,
  arm64,
  x86,
  x86_64,
  mips,
  riscv64,
  unknown,
}

/// Extension helpers for [CpuArchitecture].
extension CpuArchitectureX on CpuArchitecture {
  /// Converts string representation to [CpuArchitecture].
  static CpuArchitecture fromString(String? value) {
    if (value == null) return CpuArchitecture.unknown;
    final lower = value.toLowerCase().replaceAll('-', '_').trim();
    if (lower.contains('arm64') || lower.contains('aarch64')) {
      return CpuArchitecture.arm64;
    }
    if (lower.contains('arm') || lower.contains('v7') || lower.contains('v8l')) {
      return CpuArchitecture.arm;
    }
    if (lower.contains('x86_64') || lower.contains('amd64') || lower.contains('x64')) {
      return CpuArchitecture.x86_64;
    }
    if (lower.contains('x86') || lower.contains('i386') || lower.contains('i686')) {
      return CpuArchitecture.x86;
    }
    if (lower.contains('mips')) {
      return CpuArchitecture.mips;
    }
    if (lower.contains('riscv64') || lower.contains('riscv')) {
      return CpuArchitecture.riscv64;
    }
    return CpuArchitecture.unknown;
  }
}
