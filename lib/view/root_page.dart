import 'dart:async';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:chatApp/controller/discover_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'home_page/ble.dart';
import 'home_page/clock_animation.dart';
import 'home_page/discover_page.dart';

class RootPage extends StatefulWidget {
  RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  final iconList = <IconData>[
    Icons.brightness_5,
    Icons.brightness_4,
    Icons.brightness_6,
    Icons.brightness_7,
  ];

  RxInt activeIndex = 0.obs;

  var pages = [
    const RotatingConicalShape(),
    const BluetoothHomePage(),
    const DiscoverDevicesScreen(),
    const DiscoverDevicesScreen()
  ];



  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      // _adapterState == BluetoothAdapterState.on
      //     ? const ScanScreen()
      //     : BluetoothOffScreen(adapterState: _adapterState),
      Obx(()=> pages[activeIndex.value]),
      backgroundColor: Colors.white10,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: 4,
        tabBuilder: (int index, bool isActive) {
          return Obx(()=>Icon(
              iconList[index],
              size: 24,
                color: index==activeIndex.value?Colors.white:Colors.black
            ),
          );
        },
        notchMargin : 15,
        notchSmoothness: NotchSmoothness.smoothEdge,
        gapLocation: GapLocation.center,
        elevation: 0,
        backgroundColor: Colors.black26,
        height: 100,
        leftCornerRadius: 20,
        rightCornerRadius: 20,
        onTap: (index){
          activeIndex.value = index;
          },
        activeIndex: 1,
        backgroundGradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),


      floatingActionButton: buildFloatingActionButton(context),
    );
  }

  Widget? buildFloatingActionButton(BuildContext context) {
    return Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
        child: FloatingActionButton(
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () {
            discoverMV.startScanning();
          },
          backgroundColor: Colors.white,
          child: Transform.rotate(
              angle: 40 * (3.141592653589793 / 180), // Convert degrees to radians
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient:  LinearGradient(
                    colors: [
                      Colors.blue[200]!,
                      Colors.purple[200]!
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),

                child: const Center(
                  child:Icon(Icons.wifi_tethering)
                ),
              ),
            ),
        )
    );
  }
}