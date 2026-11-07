# Bluetooth design

Opening the Bluetooth tab immediately starts `MockBluetoothScanner`, which asynchronously emits explicitly labeled simulated nearby collars. Selecting one obtains a simulated location through `MockLocationService`, then opens the dog profile. The interface explicitly says that real BLE and GPS are not used in this development flow. It does not refresh manually or continuously track location.

`CoreBluetoothScanner` is deliberately an inactive placeholder. iOS does not expose arbitrary BLE MAC addresses. `collars` therefore separates an internal hardware identifier from a future advertisement identifier. After hardware selection, agree a stable, privacy-aware advertisement payload and map it to a registered collar; only then implement CoreBluetooth parsing and scanning. Collar displays, if supported, may show only an assigned dog icon.

The current location RPC validates coordinates and active-dog status, but it cannot prove an iPhone physically detected a collar: no collar advertisement protocol exists yet, and the mock proves nothing. In the hardware phase, consider a rotating signed advertisement or server-verifiable challenge, per-device/request rate limits, location plausibility checks, minimum accuracy and timestamp checks, and abuse monitoring. These are future decisions, not implemented protections.
