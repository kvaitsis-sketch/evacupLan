// ============================================================
// EvacuPlan — Emergency Navigation Page
// lib/screens/emergency_navigation_page.dart
// Χάρτης ορόφων + διαδρομές εκκένωσης + BLE beacons
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────
// 1. MODELS
// ─────────────────────────────────────────────

enum RoomType { ward, icu, staircase, exit, assembly, fireExit, elevator, bathroom }

class HospitalRoom {
  final String id;
  final String name;
  final RoomType type;
  final int floor;
  final double x; // grid position
  final double y;
  bool isBlocked;
  String? blockReason;

  HospitalRoom({
    required this.id, required this.name, required this.type,
    required this.floor, required this.x, required this.y,
    this.isBlocked = false, this.blockReason,
  });
}

class EvacuationPath {
  final String id;
  final String name;
  final List<String> roomIds; // sequence of rooms
  final bool isPrimary;
  bool isBlocked;

  EvacuationPath({
    required this.id, required this.name, required this.roomIds,
    this.isPrimary = true, this.isBlocked = false,
  });
}

// ─────────────────────────────────────────────
// 2. MAIN NAVIGATION SCREEN
// ─────────────────────────────────────────────

class EmergencyNavigationPage extends StatefulWidget {
  const EmergencyNavigationPage({Key? key}) : super(key: key);
  @override
  State<EmergencyNavigationPage> createState() => _EmergencyNavigationPageState();
}

class _EmergencyNavigationPageState extends State<EmergencyNavigationPage>
    with SingleTickerProviderStateMixin {
  int _selectedFloor = 1;
  late TabController _tabController;
  bool _emergencyMode = false;
  String _selectedPath = 'primary';

  // ── Δεδομένα ορόφων ──────────────────────────────────────
  final Map<int, List<HospitalRoom>> _floors = {
    0: [ // Ισόγειο
      HospitalRoom(id: 'g_er',    name: 'Επείγοντα',        type: RoomType.ward,      floor: 0, x: 1, y: 1),
      HospitalRoom(id: 'g_xray',  name: 'Ακτινολογικό',    type: RoomType.ward,      floor: 0, x: 3, y: 1),
      HospitalRoom(id: 'g_exit_n',name: 'Έξοδος Βόρεια ▼', type: RoomType.exit,      floor: 0, x: 0, y: 0),
      HospitalRoom(id: 'g_exit_s',name: 'Έξοδος Νότια ▼',  type: RoomType.exit,      floor: 0, x: 4, y: 2),
      HospitalRoom(id: 'g_stair_a',name:'Σκάλες Α',         type: RoomType.staircase, floor: 0, x: 2, y: 0),
      HospitalRoom(id: 'g_stair_b',name:'Σκάλες Β',         type: RoomType.staircase, floor: 0, x: 2, y: 2),
      HospitalRoom(id: 'g_ramp',  name: 'Ramp ♿',           type: RoomType.exit,      floor: 0, x: 4, y: 0),
      HospitalRoom(id: 'g_assembly',name:'Assembly Point 🟢',type: RoomType.assembly,  floor: 0, x: 0, y: 2),
    ],
    1: [ // 1ος όροφος
      HospitalRoom(id: '1_path',  name: 'Παθολογική',       type: RoomType.ward,      floor: 1, x: 1, y: 1),
      HospitalRoom(id: '1_card',  name: 'Καρδιολογία',      type: RoomType.ward,      floor: 1, x: 3, y: 1),
      HospitalRoom(id: '1_stair_a',name:'Σκάλες Α ↓',       type: RoomType.staircase, floor: 1, x: 2, y: 0),
      HospitalRoom(id: '1_stair_b',name:'Σκάλες Β ↓',       type: RoomType.staircase, floor: 1, x: 2, y: 2),
      HospitalRoom(id: '1_nurse', name: 'Νοσ. Σταθμός',     type: RoomType.ward,      floor: 1, x: 2, y: 1),
      HospitalRoom(id: '1_comp_a',name: 'Compartment A',    type: RoomType.ward,      floor: 1, x: 0, y: 1),
      HospitalRoom(id: '1_comp_b',name: 'Compartment B',    type: RoomType.ward,      floor: 1, x: 4, y: 1),
      HospitalRoom(id: '1_elev',  name: 'Ασανσέρ ✗',        type: RoomType.elevator,  floor: 1, x: 4, y: 0),
    ],
    2: [ // 2ος όροφος — ΜΕΘ
      HospitalRoom(id: '2_icu',   name: 'ΜΕΘ',              type: RoomType.icu,       floor: 2, x: 2, y: 1),
      HospitalRoom(id: '2_surg',  name: 'Χειρουργική',      type: RoomType.ward,      floor: 2, x: 0, y: 1),
      HospitalRoom(id: '2_stair_a',name:'Σκάλες Α ↓',       type: RoomType.staircase, floor: 2, x: 2, y: 0),
      HospitalRoom(id: '2_stair_b',name:'Σκάλες Β ↓',       type: RoomType.staircase, floor: 2, x: 2, y: 2),
      HospitalRoom(id: '2_nurse', name: 'Νοσ. Σταθμός',     type: RoomType.ward,      floor: 2, x: 1, y: 1),
      HospitalRoom(id: '2_fire',  name: 'Πυράντοχη Πόρτα',  type: RoomType.fireExit,  floor: 2, x: 4, y: 1),
      HospitalRoom(id: '2_comp_a',name: 'Compartment A',    type: RoomType.ward,      floor: 2, x: 0, y: 0),
      HospitalRoom(id: '2_comp_b',name: 'Compartment B',    type: RoomType.ward,      floor: 2, x: 4, y: 2),
    ],
  };

  final List<EvacuationPath> _paths = [
    EvacuationPath(
      id: 'primary', name: 'Πρωτεύουσα — Σκάλες Α → Βόρεια Έξοδος',
      roomIds: ['2_stair_a', '1_stair_a', 'g_stair_a', 'g_exit_n'],
      isPrimary: true,
    ),
    EvacuationPath(
      id: 'secondary', name: 'Εφεδρική — Σκάλες Β → Νότια Έξοδος',
      roomIds: ['2_stair_b', '1_stair_b', 'g_stair_b', 'g_exit_s'],
      isPrimary: false,
    ),
    EvacuationPath(
      id: 'wheelchair', name: 'Wheelchair/Φορείο — Ramp Ανατολική',
      roomIds: ['1_stair_a', 'g_stair_a', 'g_ramp'],
      isPrimary: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedFloor = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleBlock(HospitalRoom room) {
    if (room.type == RoomType.staircase || room.type == RoomType.exit) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(room.isBlocked ? '✅ Άνοιγμα' : '🚫 Αποκλεισμός'),
          content: Text(room.isBlocked
              ? 'Ανοίγετε: ${room.name}'
              : 'Κλείνετε: ${room.name}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Ακύρωση')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: room.isBlocked ? Colors.green : Colors.red),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  room.isBlocked = !room.isBlocked;
                  room.blockReason = room.isBlocked ? 'Μη ασφαλής' : null;
                });
              },
              child: Text(room.isBlocked ? 'Άνοιγμα' : 'Αποκλεισμός',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Color _roomColor(HospitalRoom room) {
    if (room.isBlocked) return Colors.red[700]!;
    switch (room.type) {
      case RoomType.icu:        return Colors.red[300]!;
      case RoomType.staircase:  return Colors.blue[400]!;
      case RoomType.exit:       return Colors.green[500]!;
      case RoomType.assembly:   return Colors.green[700]!;
      case RoomType.fireExit:   return Colors.orange[400]!;
      case RoomType.elevator:   return Colors.grey[400]!;
      default:                  return Colors.blue[100]!;
    }
  }

  IconData _roomIcon(HospitalRoom room) {
    if (room.isBlocked) return Icons.block;
    switch (room.type) {
      case RoomType.icu:        return Icons.monitor_heart;
      case RoomType.staircase:  return Icons.stairs;
      case RoomType.exit:       return Icons.exit_to_app;
      case RoomType.assembly:   return Icons.people;
      case RoomType.fireExit:   return Icons.local_fire_department;
      case RoomType.elevator:   return Icons.elevator;
      default:                  return Icons.bed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: _emergencyMode ? Colors.red[700] : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_emergencyMode ? '🚨 ΕΚΚΕΝΩΣΗ — Χάρτης' : 'Χάρτης Εκκένωσης',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Πλοήγηση ανά όροφο',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Switch(
            value: _emergencyMode,
            activeColor: Colors.white,
            onChanged: (v) => setState(() => _emergencyMode = v),
          ),
          const Text('🚨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Ισόγειο'),
            Tab(text: '1ος Όροφος'),
            Tab(text: '2ος — ΜΕΘ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Legend ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legendItem(Colors.blue[100]!, 'Τμήμα'),
                  _legendItem(Colors.red[300]!, 'ΜΕΘ'),
                  _legendItem(Colors.blue[400]!, 'Σκάλες'),
                  _legendItem(Colors.green[500]!, 'Έξοδος'),
                  _legendItem(Colors.green[700]!, 'Assembly'),
                  _legendItem(Colors.red[700]!, 'ΚΛΕΙΣΤΟ'),
                  _legendItem(Colors.grey[400]!, 'Ασανσέρ ✗'),
                ],
              ),
            ),
          ),

          // ── Χάρτης ορόφου ───────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [0, 1, 2].map((floor) => _buildFloorMap(floor)).toList(),
            ),
          ),

          // ── Διαδρομές εκκένωσης ───────────
