import 'package:flutter/material.dart';

class QueuePatient {
  final int ticketNumber;
  final String name;
  final String phone;
  final String clinic;
  final String time;
  String status;

  QueuePatient({
    required this.ticketNumber,
    required this.name,
    required this.phone,
    required this.clinic,
    required this.time,
    this.status = 'waiting',
  });
}

class QueueNotifier extends ChangeNotifier {
  final List<QueuePatient> _queue = [];
  int _nextTicketNumber = 1;

  List<QueuePatient> get queue => List.unmodifiable(_queue);
  List<QueuePatient> get waiting => _queue.where((p) => p.status == 'waiting').toList();
  List<QueuePatient> get called => _queue.where((p) => p.status == 'called').toList();
  List<QueuePatient> get done => _queue.where((p) => p.status == 'done').toList();

  int get waitingCount => waiting.length;
  int get calledCount => called.length;
  int get doneCount => done.length;

  int takeTicket({required String name, required String phone, required String clinic}) {
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final patient = QueuePatient(
      ticketNumber: _nextTicketNumber,
      name: name,
      phone: phone,
      clinic: clinic,
      time: timeStr,
    );
    _queue.add(patient);
    _nextTicketNumber++;
    notifyListeners();
    return patient.ticketNumber;
  }

  void cancelTicket(int ticketNumber) {
    _queue.removeWhere((p) => p.ticketNumber == ticketNumber);
    notifyListeners();
  }

  int getPosition(int ticketNumber) {
    final waitingList = waiting;
    for (int i = 0; i < waitingList.length; i++) {
      if (waitingList[i].ticketNumber == ticketNumber) return i + 1;
    }
    return 0;
  }

  int getWaitMinutes(int ticketNumber) {
    return getPosition(ticketNumber) * 7;
  }

  void callNext() {
    for (var p in _queue) {
      if (p.status == 'called') {
        p.status = 'done';
        break;
      }
    }
    for (var p in _queue) {
      if (p.status == 'waiting') {
        p.status = 'called';
        break;
      }
    }
    notifyListeners();
  }

  void resetQueue() {
    _queue.clear();
    _nextTicketNumber = 1;
    notifyListeners();
  }
}