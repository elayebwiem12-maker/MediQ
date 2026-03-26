import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttercousd/provider/queue_notifier.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediQ - Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D9E75),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _statCard('En attente', '${queue.waitingCount}', Icons.people)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('En cours', '${queue.calledCount}', Icons.person_pin)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Traités', '${queue.doneCount}', Icons.check_circle)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: queue.waitingCount > 0
                    ? () => context.read<QueueNotifier>().callNext()
                    : null,
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: const Text('Appeler le suivant',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('File d\'attente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (queue.queue.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucun patient en attente', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...queue.queue.map((p) => _queueItem(p)),
            const SizedBox(height: 20),
            if (queue.queue.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<QueueNotifier>().resetQueue(),
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text('Réinitialiser la file', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE1F5EE), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1D9E75)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _queueItem(QueuePatient p) {
    Color statusColor = p.status == 'called'
        ? const Color(0xFF1D9E75)
        : p.status == 'waiting'
        ? Colors.orange
        : Colors.grey;
    String statusText = p.status == 'called' ? 'Appelé' : p.status == 'waiting' ? 'Attente' : 'Terminé';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.status == 'called' ? const Color(0xFFE1F5EE) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: p.status == 'called' ? const Color(0xFF1D9E75) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text('${p.ticketNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 14)),
                Text(p.phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(p.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor)),
          ),
        ],
      ),
    );
  }
}