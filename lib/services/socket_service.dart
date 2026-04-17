import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static const String serverUrl = 'http://localhost:3000';

  IO.Socket? _socket;
  String? _currentClinicId;

  void connect(String token) {
    _socket = IO.io(serverUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((data) {
      print('Socket error: $data');
    });
  }

  void joinClinic(String clinicId) {
    if (_currentClinicId != null) {
      leaveClinic(_currentClinicId!);
    }
    _currentClinicId = clinicId;
    _socket?.emit('join_clinic', clinicId);
    print('Joined clinic: $clinicId');
  }

  void leaveClinic(String clinicId) {
    _socket?.emit('leave_clinic', clinicId);
    print('Left clinic: $clinicId');
  }

  void onQueueUpdated(Function(dynamic) callback) {
    _socket?.on('queue_updated', (data) {
      print('Queue updated: $data');
      callback(data);
    });
  }

  void onPatientCalled(Function(dynamic) callback) {
    _socket?.on('patient_called', (data) {
      print('Patient called: $data');
      callback(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  bool get isConnected => _socket?.connected ?? false;
}
