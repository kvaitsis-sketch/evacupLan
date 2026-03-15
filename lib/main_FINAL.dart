/ ============================================================
// EvacuPlan v3.0 — ΤΕΛΙΚΟ main.dart
// ΟΛΑ τα imports ενεργά — έτοιμο για GitHub + Codemagic
// ============================================================

import 'package:flutter/material.dart';

// ── Imports όλων των screens ──────────────────────────────
import 'screens/peep_registration_screen.dart';
import 'screens/ic_dashboard_screen.dart';
import 'screens/pre_event_planning_screen.dart';
import 'screens/emergency_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EvacuPlanApp());
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────

class EvacuPlanApp extends StatefulWidget {
  const EvacuPlanApp({Key? key}) : super(key: key);

  static EvacuPlanAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<EvacuPlanAppState>();

  @override
  EvacuPlanAppState createState() => EvacuPlanAppState();
}

class EvacuPlanAppState extends State<EvacuPlanApp> {
  Locale _locale = const Locale('el');
  UserRole? _currentRole;

  void setLocale(Locale l) => setState(() => _locale = l);
  void setRole(UserRole role) => setState(() => _currentRole = role);
  void logout() => setState(() => _currentRole = null);
  bool get isGreek => _locale.languageCode == 'el';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvacuPlan',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: _currentRole == null
          ? const LoginScreen()
          : MainShell(role: _currentRole!),
    );
  }
}

// ─────────────────────────────────────────────
// ΡΟΛΟΙ
// ─────────────────────────────────────────────

enum UserRole { incidentCommander, nurse, trainer, admin }

class RoleConfig {
  final String titleEl;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String pin;

  const RoleConfig({
    required this.titleEl, required this.subtitle,
    required this.icon, required this.color, required this.pin,
  });
}

const Map<UserRole, RoleConfig> roleConfigs = {
  UserRole.incidentCommander: RoleConfig(
    titleEl: 'Incident Commander',
    subtitle: 'Ενεργοποίηση εκκένωσης, διαδρομές',
    icon: Icons.emergency, color: Color(0xFFD32F2F), pin: '1234',
  ),
  UserRole.nurse: RoleConfig(
    titleEl: 'Νοσηλευτής / Προσωπικό',
    subtitle: 'PEEP ασθενών, χάρτης, checklist',
    icon: Icons.medical_services, color: Color(0xFF1976D2), pin: '2345',
  ),
  UserRole.trainer: RoleConfig(
    titleEl: 'Εκπαιδευτής',
    subtitle: 'Pre-event planning, ρυθμίσεις',
    icon: Icons.school, color: Color(0xFF388E3C), pin: '3456',
  ),
  UserRole.admin: RoleConfig(
    titleEl: 'Διαχειριστής',
    subtitle: 'Pre-event planning, ρυθμίσεις',
    icon: Icons.admin_panel_settings, color: Color(0xFF7B1FA2), pin: '4567',
  ),
};

// ─────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole? _selectedRole;
  final _pinCtrl = TextEditingController();
  bool _pinError = false;
  bool _obscurePin = true;

  void _login() {
    if (_selectedRole == null) return;
    final cfg = roleConfigs[_selectedRole!]!;
    if (_pinCtrl.text == cfg.pin) {
      EvacuPlanApp.of(context)?.setRole(_selectedRole!);
    } else {
      setState(() => _pinError = true);
      _pinCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: const Icon(Icons.local_hospital, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('EvacuPlan',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
              const Text('Hospital Evacuation System',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 36),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Επιλέξτε Ρόλο',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              ...UserRole.values.map((role) {
                final cfg = roleConfigs[role]!;
                final selected = _selectedRole == role;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedRole = role;
                    _pinError = false;
                    _pinCtrl.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? cfg.color.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? cfg.color : Colors.grey[300]!,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: cfg.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cfg.icon, color: cfg.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cfg.titleEl,
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 15, color: cfg.color)),
                              Text(cfg.subtitle,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (selected) Icon(Icons.check_circle, color: cfg.color),
                      ],
                    ),
                  ),
                );
              }),
              if (_selectedRole != null) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _pinCtrl,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'PIN (4 ψηφία)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _pinError ? 'Λάθος PIN — δοκιμάστε ξανά' : null,
                    filled: true, fillColor: Colors.white,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleConfigs[_selectedRole!]!.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('ΕΙΣΟΔΟΣ',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Demo PIN: ${roleConfigs[_selectedRole!]!.pin}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL — BottomNavigationBar
// ─────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final UserRole role;
  const MainShell({Key? key, required this.role}) : super(key: key);
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // ── TABS με ΠΡΑΓΜΑΤΙΚΑ SCREENS (χωρίς placeholders) ──────────
  List<_ShellTab> get _tabs {
    switch (wid
