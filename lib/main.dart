import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class ArduinoController {
  void openRelay1() {
    print('Mở rờ le 1');
  }

  void closeRelay1() {
    print('Đóng rờ le 1');
  }

  void openRelay2() {
    print('Mở rờ le 2');
  }

  void closeRelay2() {
    print('Đóng rờ le 2');
  }

  void openRelay3() {
    print('Mở rờ le 3');
  }

  void closeRelay3() {
    print('Đóng rờ le 3');
  }

  void openRelay4() {
    print('Mở rờ le 4');
  }

  void closeRelay4() {
    print('Đóng rờ le 4');
  }
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/': (context) => BluetoothScanPage(),
        '/device-list': (context) => const BluetoothDeviceList(),
      },
      home: BluetoothScanPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> _requestBluetoothPermission() async {
  PermissionStatus status = await Permission.bluetooth.status;
  if (status != PermissionStatus.granted) {
    status = await Permission.bluetooth.request();
    if (status != PermissionStatus.granted) {
      print('Quyền BLUETOOTH không được cấp');
    }
  }
}

class BluetoothDeviceList extends StatefulWidget {
  const BluetoothDeviceList({Key? key, this.connection}) : super(key: key);
  final BluetoothConnection? connection;
  @override
  _BluetoothDeviceListState createState() => _BluetoothDeviceListState();
}

class _BluetoothDeviceListState extends State<BluetoothDeviceList> {
  List<BluetoothDevice> devices = [];
  bool isLoading = true;
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    if (!mounted) return;

    setState(() {
      devices = [];
      isLoading = true;
      scanning = true;
    });

    FlutterBluetoothSerial.instance.startDiscovery().listen(
      (BluetoothDiscoveryResult result) {
        if (!mounted) return;

        setState(() {
          devices.add(result.device);
        });
      },
      onDone: () {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          scanning = false;
        });
      },
      onError: (dynamic error) {
        if (!mounted) return;

        print('Error during Bluetooth scanning: $error');
        setState(() {
          isLoading = false;
          scanning = false;
        });
      },
    );
  }

  void _connectToDevice(
      BluetoothConnection? connection, BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      if (connection.isConnected) {
        await _setupBaudRate(connection);
        _sendControlCommand(connection, 'START_SIGNAL');
        print('Connected to ${device.name}');
      } else {
        print('Error: Connection is null or not connected.');
      }
    } catch (e) {
      print('Error connecting to ${device.name}: $e');
    }
  }

  void _sendControlCommand(BluetoothConnection? connection, String command) {
    print('Sent: $command');
    if (connection != null && connection.isConnected) {
      try {
        connection.output.add(utf8.encode(command));
        connection.output.allSent.then((_) {
          print('Sent: $command');
        });
      } catch (e) {
        print('Error sending command: $e');
      }
    } else {
      print('Không kết nối đến thiết bị Bluetooth.');
    }
  }

  Future<void> _setupBaudRate(BluetoothConnection? connection) async {
    try {
      if (connection != null && connection.isConnected) {
        const int baudRate = 9600;
        final Uint8List data =
            Uint8List.fromList([0x02, 0x31, 0x30, 0x30, 0x30, 0x03, 9600]);
        connection.output.add(Uint8List.fromList(data));
        await connection.output.allSent;
        print('Baud rate set to $baudRate');
      } else {
        print('Error: Connection is null or not connected.');
      }
    } catch (e) {
      print('Error setting up baud rate: $e');
    }
  }

  void _disconnectFromDevice(
      BluetoothConnection? connection, BluetoothDevice device) async {
    try {
      await connection?.finish();
      print('Disconnected from ${device.name}');
    } catch (e) {
      print('Error disconnecting from ${device.name}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Scan'),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devices[index];
                  return BluetoothDeviceListItem(
                    device: device,
                    onConnect: (p0) => _connectToDevice(widget.connection, p0),
                    onDisconnect: (p0) =>
                        _disconnectFromDevice(widget.connection, p0),
                  );
                },
              ),
      ),
    );
  }
}

class BluetoothDeviceListItem extends StatelessWidget {
  final BluetoothDevice device;
  final Function(BluetoothDevice) onConnect;
  final Function(BluetoothDevice) onDisconnect;

  const BluetoothDeviceListItem({
    Key? key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name ?? 'Thiết Bị Không Xác Định'),
      subtitle: Text(device.address),
      trailing: device.isConnected
          ? ElevatedButton(
              onPressed: () => onDisconnect.call(device),
              child: const Text('Ngắt Kết Nối'),
            )
          : ElevatedButton(
              onPressed: () => onConnect.call(device),
              child: const Text('Kết Nối'),
            ),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({Key? key}) : super(key: key);

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<String> options = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  String selectedOption = 'Option 1';
  ArduinoController arduinoController = ArduinoController();
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  bool isLoading = true;
  bool scanning = false;

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builderContext) {
        return SizedBox(
          height: 200,
          child: ListWheelScrollView(
            itemExtent: 40,
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedOption = options[index];
              });
            },
            children: List.generate(4, (index) {
              return Center(
                child: Text(options[index]),
              );
            }),
          ),
        );
      },
    );
  }

  void _sendControlCommand(BluetoothConnection? connection, String command) {
    print('Sent: $command');
    if (connection != null && connection.isConnected) {
      try {
        connection.output.add(utf8.encode(command));
        connection.output.allSent.then((_) {
          print('Sent: $command');
        });
      } catch (e) {
        print('Error sending command: $e');
      }
    } else {
      print('Không kết nối đến thiết bị Bluetooth.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Điều Khiển Từ Xa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () async {
              final router = Navigator.of(context);
              await _requestBluetoothPermission();
              router.push(
                MaterialPageRoute(
                  builder: (context) => BluetoothDeviceList(
                    connection: connection,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _showBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedOption,
                    style: const TextStyle(fontSize: 25),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print('Bật');
                        if (selectedOption == 'Option 1') {
                          arduinoController.openRelay1();
                          _sendControlCommand(connection, '1');
                        } else if (selectedOption == 'Option 2') {
                          arduinoController.openRelay2();
                          _sendControlCommand(connection, '2');
                        } else if (selectedOption == 'Option 3') {
                          arduinoController.openRelay3();
                          _sendControlCommand(connection, '3');
                        } else if (selectedOption == 'Option 4') {
                          arduinoController.openRelay4();
                          _sendControlCommand(connection, '4');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.cyanAccent,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text('Bật', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print('Tắt');
                        if (selectedOption == 'Option 1') {
                          arduinoController.closeRelay1();
                          _sendControlCommand(connection, '5');
                        } else if (selectedOption == 'Option 2') {
                          arduinoController.closeRelay2();
                          _sendControlCommand(connection, '6');
                        } else if (selectedOption == 'Option 3') {
                          arduinoController.closeRelay3();
                          _sendControlCommand(connection, '7');
                        } else if (selectedOption == 'Option 4') {
                          arduinoController.closeRelay4();
                          _sendControlCommand(connection, '8');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.cyanAccent,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text('Tắt', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
