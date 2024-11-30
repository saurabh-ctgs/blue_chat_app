import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothHomePage extends StatefulWidget {
  const BluetoothHomePage({super.key});

  @override
  _BluetoothHomePageState createState() => _BluetoothHomePageState();
}

class _BluetoothHomePageState extends State<BluetoothHomePage> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  StreamSubscription? scanSubscription;
  StreamSubscription? connectionSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        print('Bluetooth is off');
      }
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel(); // Cancel scan subscription
    connectionSubscription?.cancel(); // Cancel connection subscription when widget is disposed
    super.dispose();
  }

  Future<void> startScan() async {
    // Ensure Bluetooth is enabled
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    // Start scanning with filters
    await FlutterBluePlus.startScan(
      withServices: [Guid("180D")], // Filter by specific service UUID (optional)
      withNames: ["Bluno"], // Filter by specific device name (optional)
      timeout: Duration(seconds: 15),
    );

    // Listen to scan results
    scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (var result in results) {
        print('Discovered: ${result.device.name} - ${result.device.id}');
        setState(() {
          if (!scanResults.contains(result)) {
            scanResults.add(result);
          }
        });
      }
    }, onError: (e) {
      print("Scan error: $e");
    });

    // Stop scanning when complete
    FlutterBluePlus.cancelWhenScanComplete(scanSubscription!);
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      print('Connected to ${device.name}');

      // Listen for connection state changes (disconnected, etc.)
      connectionSubscription = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          print("Device disconnected: ${device.remoteId}");
          await reconnectToDevice(device);
        }
      });

      // Discover services after successful connection
      await discoverServices(device);
    } catch (e) {
      print("Failed to connect: $e");
    }
  }

  void disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      setState(() {
        connectedDevice = null; // Reset connected device on disconnect
      });
      print('Disconnected from ${device.name}');
    } catch (e) {
      print("Failed to disconnect: $e");
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        print("Discovered service: ${service.uuid}");
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("Discovered characteristic: ${characteristic.uuid}");
        }
      }
    } catch (e) {
      print("Failed to discover services: $e");
    }
  }

  Future<void> reconnectToDevice(BluetoothDevice device) async {
    try {
      print("Attempting to reconnect...");
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      await discoverServices(device);
    } catch (e) {
      print("Reconnection failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Demo')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: startScan,
            child: Text('Start Scan'),
          ),
          ElevatedButton(
            onPressed: stopScan,
            child: Text('Stop Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  title: Text(result.device.name.isNotEmpty
                      ? result.device.name
                      : 'Unknown Device'),
                  subtitle: Text(result.device.id.toString()),
                  onTap: () => connectToDevice(result.device), // Connect when tapped
                );
              },
            ),
          ),
          if (connectedDevice != null)
            Column(
              children: [
                Text('Connected to ${connectedDevice!.name}'),
                ElevatedButton(
                  onPressed: () => disconnectFromDevice(connectedDevice!),
                  child: Text('Disconnect'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
