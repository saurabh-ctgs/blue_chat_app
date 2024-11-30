import 'dart:async';
import 'dart:developer';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

DiscoverModelView discoverMV = Get.find<DiscoverModelView>();

class DiscoverModelView extends GetxController {
  final _bluetoothClassicPlugin = BluetoothClassic();
  RxList<Device> scannedDevices = <Device>[].obs;  // List of devices found via bluetooth_classic
  RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;  // List of BluetoothDevices from flutter_blue_plus

  BluetoothDevice? connectedDevice;  // Hold the currently connected device
  BluetoothService? targetService;  // Hold the specific service you want to interact with
  BluetoothCharacteristic? targetCharacteristic;  // Hold the characteristic for communication

  @override
  Future<void> onInit() async {
    super.onInit();
    await _bluetoothClassicPlugin.initPermissions();
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    final status = await Permission.bluetoothScan.request();
    if (status.isGranted) {
      // Fetch bonded devices (if needed)
      fetchBondedDevices();

      // Start scanning for devices
      await startScanning();
    } else {
      Get.snackbar("Permission Denied", "Bluetooth permission is required.");
    }
  }

  void fetchBondedDevices() async {
    // Fetch paired devices if needed
    List<Device> pairedDevices = await _bluetoothClassicPlugin.getPairedDevices();
    // scannedDevices.addAll(pairedDevices);
  }

  Future<void> startScanning() async {
    await _bluetoothClassicPlugin.startScan();
    print("Scanning for devices...");

    _bluetoothClassicPlugin.onDeviceDiscovered().listen((device) {
      if (!scannedDevices.contains(device)) {
        scannedDevices.add(device);
        print("Discovered device: ${device.name} - ${device.address}");
      }
    });

    // Optionally stop scanning after a period of time
    // await Future.delayed(Duration(seconds: 10));  // Set your desired duration
    // await _bluetoothClassicPlugin.stopScan();
    print("Scanning stopped.");
  }

  Future<void> handleDeviceTap(Device device) async {
    try {
      log('Connecting to ${device.name}');

      // Convert the classic Bluetooth device to a BluetoothDevice for flutter_blue_plus
      // BluetoothDevice bluetoothDevice = await getBluetoothDeviceFromAddress(device.address);
      //
      // await bluetoothDevice.connect().timeout(Duration(seconds: 10));
      //
      // log('Connected to ${device.name}');
      //
      // // After connecting, discover services to get the UUIDs
      // await discoverServices(bluetoothDevice);
      //
      // // Here, you can call the service or characteristic after discovering
      // if (targetService != null && targetCharacteristic != null) {
      //   // You can now use the service and characteristic to send/receive data
      //   log("Ready to use service UUID: ${targetService!.uuid} and characteristic UUID: ${targetCharacteristic!.uuid}");
      // }
    } catch (e , st) {
      if (e is PlatformException) {
        log('Error connecting to device: ${e.message}');
        Get.snackbar("Connection Failed", "Could not connect to the device.");
      } else {
        log('Unexpected error: $e \n $st');
        Get.snackbar("Connection Error", "An unexpected error occurred while connecting.");
      }
    }
  }

  // Convert the classic Bluetooth device address to a BluetoothDevice for flutter_blue_plus
  /*Future<BluetoothDevice> getBluetoothDeviceFromAddress(String address) async {
    List<BluetoothDevice> devices = await FlutterBluePlus.onScanResults;
    // Find and return the Bluetooth device by matching the address
    for (var device in devices) {
      print(device.remoteId);
    }
    BluetoothDevice device = devices[0];
    // devices.firstWhere((d) => d.id.id == address, orElse: () => throw Exception('Device not found'));
    return device;
  }*/

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      // Discover the services offered by the device
      List<BluetoothService> services = await device.discoverServices();

      // Iterate over all discovered services and print their UUIDs
      for (BluetoothService service in services) {
        print("Discovered service: ${service.uuid}");

        // If you find the service you want, you can save it
        if (service.uuid == Guid("desired_service_uuid_here")) { // Replace with your desired service UUID
          targetService = service;

          // Now let's find a characteristic from this service
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            print("   Discovered characteristic: ${characteristic.uuid}");

            // Optionally, pick a characteristic you want to interact with
            if (characteristic.uuid == Guid("desired_characteristic_uuid_here")) {  // Replace with your desired characteristic UUID
              targetCharacteristic = characteristic;
            }
          }
        }
      }
    } catch (e) {
      print("Failed to discover services: $e");
    }
  }

  var subscription = FlutterBluePlus.onScanResults.listen((results) {
    if (results.isNotEmpty) {
      ScanResult r = results.last;
      print('${r.device}: "${r.advertisementData.advName}" found!');
    }
  }, onError: (e) => print(e));

  @override
  void onClose() {
    _bluetoothClassicPlugin.stopScan();
    super.onClose();
  }
}
