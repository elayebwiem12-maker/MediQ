import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  List _queue = [];
  int _selectedClinicId = 1;
  List _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _loadQueue();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await _api.getClinics();
      setState(() => _clinics = clinics);
    } catch (e) {
      print('Error loading clinics: $e');
    }
  }

  Future<void> _loadQueue() async {
    try {
      final queue = await _api.getQueue(_selectedClinicId);
      setState(() => _queue = queue);
    } catch (e) {
      print('Error loading queue: $e');
    }
  }

  Future<void> _callNext() async {
    try {
      await _api.callNext(_selectedClinicId);
      await _loadQueue();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Patient appelé!')));
    } catch (e) {
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
    final waitingCount = _queue.where((p) => p['status'] == 'waiting').length;
    final calledCount = _queue.where((p) => p['status'] == 'called').length;
    final doneCount = _queue.where((p) => p['status'] == 'done').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediQ - Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_clinics.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Clinique: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedClinicId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _clinics.map<DropdownMenuItem<int>>((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() => _selectedClinicId = v!);
                          _loadQueue();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'En attente',
                    waitingCount.toString(),
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'En cours',
                    calledCount.toString(),
                    Icons.person_pin,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Traités',
                    doneCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: waitingCount > 0 ? _callNext : null,
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: const Text(
                  'Appeler le suivant',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'File d\'attente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_queue.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun patient en attente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _queue.length,
                itemBuilder: (context, index) {
                  final p = _queue[index];
                  Color statusColor = p['status'] == 'called'
                      ? const Color(0xFF1D9E75)
                      : p['status'] == 'waiting'
                      ? Colors.orange
                      : Colors.grey;
                  String statusText = p['status'] == 'called'
                      ? 'Appelé'
                      : p['status'] == 'waiting'
                      ? 'Attente'
                      : 'Terminé';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p['status'] == 'called'
                          ? const Color(0xFFE1F5EE)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: p['status'] == 'called'
                            ? const Color(0xFF1D9E75)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${p['ticket_number']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] ?? 'Patient',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                p['phone'] ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p['type'] ?? 'normal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 11, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
