// ============================================================
// EvacuPlan — PEEP Registration Module
// lib/screens/peep_registration_screen.dart
// Personal Emergency Evacuation Plan — IASC 2019 + HICS
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────
// 1. MODELS
// ─────────────────────────────────────────────

enum EvacuationLevel {
  E1, // Κινητός — μόνος του
  E2, // Χρειάζεται βοήθεια βάδισης (1 άτομο)
  E3, // Wheelchair / φορείο (2 άτομα)
  E4, // ICU / Αναπνευστήρας (dedicated team 4+)
}

class PatientPEEP {
  final String id;
  String name;
  String wardRoom;      // π.χ. "ΜΕΘ / Κλίνη 3"
  String floor;
  EvacuationLevel level;
  List<String> specialNeeds;  // π.χ. ["Αναπνευστήρας", "IV line", "Δίσκος φαρμάκων"]
  String assignedStaff;       // Ποιος νοσηλευτής είναι υπεύθυνος
  String notes;
  DateTime registeredAt;
  bool isEvacuated;           // Real-time tracking κατά το συμβάν

  PatientPEEP({
    required this.id,
    required this.name,
    required this.wardRoom,
    required this.floor,
    required this.level,
    this.specialNeeds = const [],
    this.assignedStaff = '',
    this.notes = '',
    required this.registeredAt,
    this.isEvacuated = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'wardRoom': wardRoom, 'floor': floor,
    'level': level.index, 'specialNeeds': specialNeeds,
    'assignedStaff': assignedStaff, 'notes': notes,
    'registeredAt': registeredAt.toIso8601String(),
    'isEvacuated': isEvacuated,
  };

  factory PatientPEEP.fromJson(Map<String, dynamic> j) => PatientPEEP(
    id: j['id'], name: j['name'], wardRoom: j['wardRoom'], floor: j['floor'],
    level: EvacuationLevel.values[j['level']],
    specialNeeds: List<String>.from(j['specialNeeds'] ?? []),
    assignedStaff: j['assignedStaff'] ?? '',
    notes: j['notes'] ?? '',
    registeredAt: DateTime.parse(j['registeredAt']),
    isEvacuated: j['isEvacuated'] ?? false,
  );
}

// ─────────────────────────────────────────────
// 2. PEEP LIST SCREEN
// ─────────────────────────────────────────────

class PEEPListScreen extends StatefulWidget {
  const PEEPListScreen({Key? key}) : super(key: key);
  @override
  State<PEEPListScreen> createState() => _PEEPListScreenState();
}

class _PEEPListScreenState extends State<PEEPListScreen> {
  List<PatientPEEP> _patients = [];
  String _filterLevel = 'ALL';

  final Map<EvacuationLevel, Color> levelColors = {
    EvacuationLevel.E1: const Color(0xFF4CAF50),
    EvacuationLevel.E2: const Color(0xFFFFC107),
    EvacuationLevel.E3: const Color(0xFFFF9800),
    EvacuationLevel.E4: const Color(0xFFD32F2F),
  };

  final Map<EvacuationLevel, String> levelLabels = {
    EvacuationLevel.E1: 'E1 — Κινητός',
    EvacuationLevel.E2: 'E2 — Βοήθεια βάδισης',
    EvacuationLevel.E3: 'E3 — Wheelchair/Φορείο',
    EvacuationLevel.E4: 'E4 — ICU/Αναπνευστήρας',
  };

  final Map<EvacuationLevel, String> levelIcons = {
    EvacuationLevel.E1: '🚶', EvacuationLevel.E2: '🦯',
    EvacuationLevel.E3: '♿', EvacuationLevel.E4: '🏥',
  };

  final Map<EvacuationLevel, int> levelStaff = {
    EvacuationLevel.E1: 0, EvacuationLevel.E2: 1,
    EvacuationLevel.E3: 2, EvacuationLevel.E4: 4,
  };

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('peep_patients') ?? [];
    setState(() {
      _patients = raw.map((s) => PatientPEEP.fromJson(jsonDecode(s))).toList();
      // Sort: E4 πρώτα
      _patients.sort((a, b) => b.level.index.compareTo(a.level.index));
    });
  }

  Future<void> _savePatients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'peep_patients', _patients.map((p) => jsonEncode(p.toJson())).toList());
  }

  List<PatientPEEP> get _filtered {
    if (_filterLevel == 'ALL') return _patients;
    final level = EvacuationLevel.values
        .firstWhere((e) => e.name == _filterLevel);
    return _patients.where((p) => p.level == level).toList();
  }

  int _staffNeeded(EvacuationLevel level) => levelStaff[level]!;
  int get _totalStaffNeeded =>
      _patients.fold(0, (sum, p) => sum + _staffNeeded(p.level));

  @override
  Widget build(BuildContext context) {
    final e4count = _patients.where((p) => p.level == EvacuationLevel.E4).length;
    final e3count = _patients.where((p) => p.level == EvacuationLevel.E3).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PEEP — Μητρώο Ασθενών',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Personal Emergency Evacuation Plans',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 30),
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PEEPFormScreen()));
              if (result != null) {
                setState(() => _patients.add(result));
                _patients.sort((a, b) => b.level.index.compareTo(a.level.index));
                _savePatients();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats banner ──
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1565C0).withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip('Σύνολο', '${_patients.length}', Colors.blue),
                _statChip('E4 ICU', '$e4count', Colors.red),
                _statChip('E3 Φορείο', '$e3count', Colors.orange),
                _statChip('Προσωπικό
Απαιτείται', '$_totalStaffNeeded', Colors.purple),
              ],
            ),
          ),
          // ── Filter tabs ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['ALL', 'E4', 'E3', 'E2', 'E1'].map((f) {
                final active = _filterLevel == f;
                Color chipColor = Colors.grey;
                if (f == 'E4') chipColor = Colors.red;
                else if (f == 'E3') chipColor = Colors.orange;
                else if (f == 'E2') chipColor = Colors.amber;
                else if (f == 'E1') chipColor = Colors.green;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'ALL' ? 'Όλοι' : f,
                        style: TextStyle(
                            color: active ? Colors.white : chipColor,
                            fontWeight: FontWeight.bold)),
                    selected: active,
                    backgroundColor: Colors.white,
                    selectedColor: chipColor,
                    onSelected: (_) => setState(() => _filterLevel = f),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── List ──
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Δεν υπάρχουν ασθενείς',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PEEPFormScreen()));
                            if (result != null) {
                              setState(() => _patients.add(result));
                              _savePatients();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Προσθήκη ασθενή'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildPatientCard(_filtered[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Νέος Ασθενής'),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PEEPFormScreen()));
          if (result != null) {
            setState(() => _patients.add(result));
            _patients.sort((a, b) => b.level.index.compareTo(a.level.index));
            _savePatients();
          }
        },
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold,
            fontSi
