// ============================================================
// EvacuPlan — Incident Commander Dashboard
// lib/screens/ic_dashboard_screen.dart
// Real-time εκκένωση: ενεργοποίηση + blocked routes + tracking
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';

// ─────────────────────────────────────────────
// 1. MODELS
// ─────────────────────────────────────────────

enum IncidentStatus { standby, active, resolved }
enum RouteStatus { open, blocked, caution }

class EvacuationRoute {
  final String id;
  final String name;
  final String location;
  RouteStatus status;
  String? blockedReason;

  EvacuationRoute({
    required this.id, required this.name, required this.location,
    this.status = RouteStatus.open, this.blockedReason,
  });
}

class EvacuationStats {
  int totalPatients;
  int evacuated;
  int pending;
  int e4Remaining;
  int staffDeployed;

  EvacuationStats({
    required this.totalPatients, required this.evacuated,
    required this.pending, required this.e4Remaining,
    required this.staffDeployed,
  });
}

// ─────────────────────────────────────────────
// 2. IC DASHBOARD
// ─────────────────────────────────────────────

class ICDashboardScreen extends StatefulWidget {
  const ICDashboardScreen({Key? key}) : super(key: key);
  @override
  State<ICDashboardScreen> createState() => _ICDashboardScreenState();
}

class _ICDashboardScreenState extends State<ICDashboardScreen> {
  IncidentStatus _status = IncidentStatus.standby;
  DateTime? _activatedAt;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  String _incidentType = 'Πυρκαγιά';

  final List<EvacuationRoute> _routes = [
    EvacuationRoute(id: 'r1', name: 'Σκάλες Α — Βόρεια', location: 'Όλοι οι όροφοι'),
    EvacuationRoute(id: 'r2', name: 'Σκάλες Β — Νότια', location: 'Όλοι οι όροφοι'),
    EvacuationRoute(id: 'r3', name: 'Βόρεια Έξοδος', location: 'Ισόγειο'),
    EvacuationRoute(id: 'r4', name: 'Νότια Έξοδος', location: 'Ισόγειο'),
    EvacuationRoute(id: 'r5', name: 'Είσοδος Πυροσβεστικής (Β)', location: 'Κύρια πρόσοψη — ΜΟΝΟ Πυροσβεστική'),
    EvacuationRoute(id: 'r6', name: 'Ramp Ανατολική', location: 'Ισόγειο — Wheelchair/Φορεία'),
  ];

  final EvacuationStats _stats = EvacuationStats(
    totalPatients: 47, evacuated: 0, pending: 47, e4Remaining: 6, staffDeployed: 0,
  );

  final List<String> _log = [];

  void _activateEvacuation() {
    setState(() {
      _status = IncidentStatus.active;
      _activatedAt = DateTime.now();
      _stats.staffDeployed = 24;
      _addLog('🚨 ΕΚΚΕΝΩΣΗ ΕΝΕΡΓΟΠΟΙΗΘΗΚΕ — $_incidentType');
      _addLog('📱 Push notification σε 24 συσκευές προσωπικού');
      _addLog('🔴 HCC ενεργοποιήθηκε');
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_activatedAt!));
    });
    // Simulate evacuations
    Timer.periodic(const Duration(seconds: 8), (t) {
      if (_stats.evacuated < _stats.totalPatients) {
        setState(() {
          _stats.evacuated += 3;
          if (_stats.evacuated > _stats.totalPatients)
            _stats.evacuated = _stats.totalPatients;
          _stats.pending = _stats.totalPatients - _stats.evacuated;
          _addLog('✅ ${_stats.evacuated} ασθενείς εκκενώθηκαν');
        });
      } else {
        t.cancel();
      }
    });
  }

  void _toggleRoute(EvacuationRoute route) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(route.status == RouteStatus.open
            ? '⚠️ Αποκλεισμός Διαδρομής' : '✅ Άνοιγμα Διαδρομής'),
        content: route.status == RouteStatus.open
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Κλείνετε: ${route.name}'),
                const SizedBox(height: 12),
                const Text('Λόγος αποκλεισμού:'),
                const SizedBox(height: 8),
                ...['Φωτιά / Καπνός', 'Δομική ζημιά', 'Κατάρρευση',
                    'Ασθενής πεσμένος', 'Εξοπλισμός εμποδίζει'].map((r) =>
                    ListTile(
                      title: Text(r),
                      leading: const Icon(Icons.block, color: Colors.red),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          route.status = RouteStatus.blocked;
                          route.blockedReason = r;
                          _addLog('🚫 ${route.name}: ΚΛΕΙΣΤΗ ($r)');
                          _addLog('🔄 Auto-rerouting σε όλες τις συσκευές...');
                        });
                      },
                    )),
              ])
            : Text('Ανοίγετε: ${route.name}; '
                'Επιβεβαιώστε ότι είναι ασφαλής.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Ακύρωση')),
          if (route.status != RouteStatus.open)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  route.status = RouteStatus.open;
                  route.blockedReason = null;
                  _addLog('✅ ${route.name}: ΑΝΟΙΧΤΗ ΠΑΛΙ');
                });
              },
              child: const Text('Άνοιγμα', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _addLog(String msg) {
    final time = TimeOfDay.now();
    _log.insert(0, '${time.hour.toString().padLeft(2, "0")}:'
        '${time.minute.toString().padLeft(2, "0")} — $msg');
    if (_log.length > 50) _log.removeLast();
  }

  String get _elapsedStr {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    return h > 0 ? '${h}ω ${m}λ ${s}δ' : '${m}λ ${s}δ';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _status == IncidentStatus.active;

    return Scaffold(
      backgroundColor: isActive ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isActive ? const Color(0xFFD32F2F) : const Color(0xFF37474F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IC Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              isActive ? '🔴 ΕΝΕΡΓΗ ΕΚΚΕΝΩΣΗ — $_elapsedStr' : '⚪ Αναμονή',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (isActive)
            TextButton(
              onPressed: () {
                _timer?.cancel();
                setState(() {
                  _status = IncidentStatus.resolved;
                  _addLog('✅ Εκκένωση ολοκληρώθηκε — After-Action Review');
                });
              },
              child: const Text('ΤΕΛΟΣ', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── ΚΟΥΜΠΙ ΕΝΕΡΓΟΠΟΙΗΣΗΣ ──
            if (_status == IncidentStatus.standby) ...[
              // Τύπος συμβάντος
              DropdownButtonFormField<String>(
                value: _incidentType,
                decoration: InputDecoration(
                  labelText: 'Τύπος Συμβάντος',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.warning_amber),
                  filled: true, fillColor: Colors.white,
                ),
                items: ['Πυρκαγιά', 'Σεισμός', 'Πλημμύρα', 'CBRN',
                    'Εκτεταμένη Βλάβη', 'Απειλή Βόμβας'].map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _incidentType = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.warning, size: 32),
                  label: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ΕΝΕΡΓΟΠΟΙΗΣΗ ΕΚΚΕΝΩΣΗΣ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Αποστολή notification σε όλο το προσωπικό',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('⚠️ Επιβεβαίωση'),
                      content: Text('Ενεργοποίηση εκκένωσης — $_incidentType;

Θα σταλεί notification σε ΟΛΟ το προσωπικό.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context),
                            child: const Text('Ακύρωση')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () { Navigator.pop(context); _activateEvacuation(); },
                          child: const Text('ΕΝΕΡΓΟΠΟΙΗΣΗ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
