import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../provider/queue_notifier.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _api = ApiService();
  List _clinics = [];
  int? _selectedClinicId;
  int? _myTicketNumber;
  String _message = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await _api.getClinics();
      setState(() {
        _clinics = clinics;
        if (clinics.isNotEmpty) _selectedClinicId = clinics[0]['id'];
      });
    } catch (e) {
      setState(() => _message = 'Erreur: $e');
    }
  }

  Future<void> _takeTicket() async {
    if (_selectedClinicId == null) return;
    try {
      final ticket = await _api.takeTicket(_selectedClinicId!, 'normal');
      setState(() {
        _myTicketNumber = ticket['ticket_number'];
        _message = 'Votre ticket: ${ticket['ticket_number']}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket #${ticket['ticket_number']} pris!')),
      );
    } catch (e) {
      setState(() => _message = 'Erreur: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
          ? _buildPrendreTicket(queue, hasTicket, position, minutes)
          : _buildMonTicket(hasTicket, position),
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
        ],
      ),
    );
  }

  Widget _buildPrendreTicket(queue, bool hasTicket, int position, int minutes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_clinics.isNotEmpty) ...[
            const Text(
              'Choisissez votre clinique',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedClinicId,
              isExpanded: true,
              items: _clinics.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name']),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedClinicId = v),
            ),
            const SizedBox(height: 20),
          ],
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
                    'Prendre votre place dans la file',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${queue.waitingCount} personnes en attente',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _takeTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Prendre un ticket',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Votre numéro',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '$_myTicketNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _clinics.firstWhere(
                          (c) => c['id'] == _selectedClinicId,
                        )['name'] ??
                        '',
                    style: const TextStyle(color: Colors.white70),
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
                          '$position',
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
                          '$minutes min',
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
                const Icon(
                  Icons.confirmation_number,
                  size: 80,
                  color: Color(0xFF1D9E75),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ticket N° $_myTicketNumber',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Position: $position',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            )
          : const Text(
              'Aucun ticket actif',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
    );
  }
}
