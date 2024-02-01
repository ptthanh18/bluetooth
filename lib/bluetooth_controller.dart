// bluetooth_controller.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothController extends ChangeNotifier {
  BluetoothConnection? _connection;

  BluetoothConnection? get connection => _connection;

  bool get isConnected => _connection?.isConnected ?? false;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      if (_connection != null && _connection!.isConnected) {
        notifyListeners();
      } else {
        print('Error: Connection is null or not connected.');
      }
    } catch (e) {
      print('Error connecting to ${device.name}: $e');
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.finish();
      _connection = null;
      notifyListeners();
    }
  }

  void sendControlCommand(String command) {
    print('Sent: $command');
    if (isConnected) {
      try {
        _connection!.output.add(utf8.encode(command));
        _connection!.output.allSent.then((_) {
          print('Sent: $command');
        });
      } catch (e) {
        print('Error sending command: $e');
      }
    } else {
      print('Không kết nối đến thiết bị Bluetooth.');
      // Handle the case where Bluetooth is not connected
    }
  }
}
