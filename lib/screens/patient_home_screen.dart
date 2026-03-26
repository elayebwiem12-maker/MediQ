import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttercousd/provider/queue_notifier.dart';

class PatientHomeScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String clinic;

  const PatientHomeScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.clinic,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  int? _myTicketNumber;

  void _takeTicket() {
    final ticketNum = context.read<QueueNotifier>().takeTicket(
      name: widget.name,
      phone: widget.phone,
      clinic: widget.clinic,
    );
    setState(() => _myTicketNumber = ticketNum);
  }

  void _cancelTicket() {
    context.read<QueueNotifier>().cancelTicket(_myTicketNumber!);
    setState(() => _myTicketNumber = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediQ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Patient', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildPrendreTicket()
          : _currentIndex == 1
          ? _buildMonTicket()
          : _buildHistorique(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF1D9E75),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Prendre ticket'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Mon ticket'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
        ],
      ),
    );
  }

  Widget _buildPrendreTicket() {
    final queue = context.watch<QueueNotifier>();
    final hasTicket = _myTicketNumber != null;
    final position = hasTicket ? queue.getPosition(_myTicketNumber!) : 0;
    final minutes = hasTicket ? queue.getWaitMinutes(_myTicketNumber!) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bonjour, ${widget.name} !', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(widget.clinic, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
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
                  const Text('Prendre votre place dans la file',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('${queue.waitingCount} personnes en attente', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _takeTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Prendre un ticket', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1D9E75), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('Votre numéro', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('$_myTicketNumber',
                      style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
                  Text(widget.clinic, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE1F5EE), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('$position', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
                        const Text('Position', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE1F5EE), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('$minutes min', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
                        const Text('Attente', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                onPressed: _cancelTicket,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Annuler mon ticket'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonTicket() {
    final queue = context.watch<QueueNotifier>();
    final hasTicket = _myTicketNumber != null;
    final position = hasTicket ? queue.getPosition(_myTicketNumber!) : 0;

    return Center(
      child: hasTicket
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number, size: 80, color: Color(0xFF1D9E75)),
                const SizedBox(height: 16),
                Text('Ticket N° $_myTicketNumber',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Position: $position', style: const TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            )
          : const Text('Aucun ticket actif', style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }

  Widget _buildHistorique() {
    return const Center(
      child: Text('Historique vide', style: TextStyle(color: Colors.grey)),
    );
  }
}