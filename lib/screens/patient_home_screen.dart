import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../provider/queue_notifier.dart';
import '../services/socket_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _api = ApiService();
  final SocketService _socketService = SocketService();
  static const int _defaultClinicId = 1;
  int? _myTicketNumber;
  String _myPriority = 'normal';
  int _currentIndex = 0;
  int _waitingCount = 0;
  List _history = [];

  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadHistory();
  }

  Future<void> _initSocket() async {
    final token = await _api.getToken();
    if (token != null) {
      _socketService.connect(token);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _socketService.joinClinic(_defaultClinicId.toString());
    _setupSocketListeners();
    _loadWaitingCount();
  }

  void _setupSocketListeners() {
    _socketService.onQueueUpdated((data) {
      _loadWaitingCount();
    });

    _socketService.onPatientCalled((data) {
      print('Patient called event received: $data');
      if (mounted && data['ticketNumber'] == _myTicketNumber) {
        _showPatientNotification(
          data['ticketNumber'],
          data['priority'] ?? 'normal',
        );
      }
    });
  }

  void _showPatientNotification(int ticketNumber, String priority) {
    final isUrgent = priority == 'urgent';

    String title = isUrgent ? 'URGENT - Cest votre tour' : 'Cest votre tour';
    String message =
        'Ticket ' +
        ticketNumber.toString() +
        ' - Veuillez vous presenter au cabinet de la Clinique El Manar.';

    if (isUrgent) {
      message = 'URGENT - ' + message;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isUrgent ? Colors.red : Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket numero ' + ticketNumber.toString()),
            const SizedBox(height: 10),
            Text('Veuillez vous presenter au cabinet.'),
            if (isUrgent) ...[
              const SizedBox(height: 10),
              Text(
                'Patient URGENT - Priorite absolue',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWaitingCount() async {
    try {
      final queue = await _api.getQueue(_defaultClinicId);
      if (mounted) {
        setState(() {
          _waitingCount = queue.where((p) => p['status'] == 'waiting').length;
        });
      }
    } catch (e) {
      print('Error loading queue: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _api.getMyTickets();
      if (mounted) {
        setState(() {
          _history = history;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _takeTicket(String priority) async {
    try {
      final ticket = await _api.takeTicket(_defaultClinicId, priority);
      setState(() {
        _myTicketNumber = ticket['ticket_number'];
        _myPriority = priority;
      });
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket ' +
                  ticket['ticket_number'].toString() +
                  ' (' +
                  priority +
                  ') pris avec succes',
            ),
            backgroundColor: priority == 'urgent'
                ? Colors.red
                : const Color(0xFF1D9E75),
          ),
        );
      }
      _loadWaitingCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    _socketService.disconnect();
    await _api.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueNotifier>();
    final hasTicket = _myTicketNumber != null;
    final position = hasTicket ? queue.getPosition(_myTicketNumber!) : 0;
    final minutes = hasTicket ? queue.getWaitMinutes(_myTicketNumber!) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediQ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1D9E75),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildPrendreTicket(hasTicket, position, minutes)
          : _currentIndex == 1
          ? _buildMonTicket(hasTicket, position)
          : _buildHistory(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF1D9E75),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Prendre ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Mon ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
        ],
      ),
    );
  }

  Widget _buildPrendreTicket(bool hasTicket, int position, int minutes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinique El Manar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D9E75),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '123 Rue de Tunis, El Manar',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (!hasTicket) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9FE1CB)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.queue, size: 48, color: Color(0xFF1D9E75)),
                  const SizedBox(height: 12),
                  const Text(
                    'Choisissez votre type de ticket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _waitingCount.toString() + ' personnes en attente',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _takeTicket('normal'),
                      icon: const Icon(Icons.people, color: Colors.white),
                      label: const Text(
                        'Normal',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _takeTicket('urgent'),
                      icon: const Icon(Icons.emergency, color: Colors.white),
                      label: const Text(
                        'Urgent',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _myPriority == 'urgent'
                    ? Colors.red
                    : const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _myPriority == 'urgent' ? 'URGENT' : 'Normal',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    _myTicketNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Clinique El Manar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          position.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        const Text(
                          'Position',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          minutes.toString() + ' min',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        const Text(
                          'Attente',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _myTicketNumber = null;
                  _myPriority = 'normal';
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Annuler mon ticket'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonTicket(bool hasTicket, int position) {
    return Center(
      child: hasTicket
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 80,
                  color: _myPriority == 'urgent'
                      ? Colors.red
                      : const Color(0xFF1D9E75),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ticket N° ' + _myTicketNumber.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _myPriority == 'urgent'
                        ? Colors.red
                        : const Color(0xFF1D9E75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _myPriority == 'urgent' ? 'URGENT' : 'Normal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Position: ' + position.toString(),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clinique El Manar',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            )
          : const Text(
              'Aucun ticket actif',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun historique',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Vos tickets apparaitront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final ticket = _history[index];
        final isUrgent = ticket['priority'] == 'urgent';
        final isDone = ticket['status'] == 'done';
        final date = ticket['created_at'] != null
            ? DateTime.parse(
                ticket['created_at'],
              ).toString().substring(0, 19).replaceAll('T', ' ')
            : 'Date inconnue';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isUrgent ? Border.all(color: Colors.red, width: 1) : null,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isUrgent
                    ? Colors.red
                    : const Color(0xFF1D9E75),
                child: Text(
                  ticket['ticket_number'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    'Ticket #' + ticket['ticket_number'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinique: ' +
                        (ticket['clinic_name'] ?? 'Clinique El Manar'),
                  ),
                  Text('Date: ' + date),
                  Text('Statut: ' + (isDone ? 'Termine' : ticket['status'])),
                ],
              ),
              trailing: isDone
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.pending, color: Colors.orange),
            ),
          ),
        );
      },
    );
  }
}
