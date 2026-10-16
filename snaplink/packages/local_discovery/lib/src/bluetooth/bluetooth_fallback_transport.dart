class BluetoothFallbackTransport {
  const BluetoothFallbackTransport();

  bool get supportsDiscoveryOnly => true;
  bool get supportsTransfer => false;
}

