// ============================================================
// EvacuPlan — Pre-Event Planning Checklist Module
// lib/screens/pre_event_planning_screen.dart
// Βάσει: HICS IRG Evacuation + WHO Emergency Response Checklist
//        + NFPA 101 + UK Fire Safety Guidelines
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// 1. DATA MODEL
// ─────────────────────────────────────────────

enum PlanningCategory {
  structural,    // Δομικά / Φυσικά
  clinical,      // Κλινικά / PEEP
  operational,   // Επιχειρησιακά / HICS
  communication, // Επικοινωνία
  fireCompartments, // Διαμερίσματα πυροπροστασίας
}

class PlanningItem {
  final String id;
  final String titleEl;
  final String titleEn;
  final String detailEl;
  final String detailEn;
  final PlanningCategory category;
  final bool isCritical; // Κόκκινο αν δεν έχει γίνει
  bool isCompleted;
  String? notes;

  PlanningItem({
    required this.id,
    required this.titleEl,
    required this.titleEn,
    required this.detailEl,
    required this.detailEn,
    required this.category,
    this.isCritical = false,
    this.isCompleted = false,
    this.notes,
  });
}

// ─────────────────────────────────────────────
// 2. PLANNING DATA
// ─────────────────────────────────────────────

final List<PlanningItem> planningItems = [

  // ══ ΔΙΑΜΕΡΙΣΜΑΤΑ ΠΥΡΟΠΡΟΣΤΑΣΙΑΣ ══
  PlanningItem(
    id: 'fc_01',
    titleEl: 'Χαρτογράφηση διαμερισμάτων πυροπροστασίας',
    titleEn: 'Fire compartment mapping',
    detailEl: 'Ορισμός ορίων κάθε compartment ανά όροφο (max 250τμ). Σήμανση στον χάρτη.',
    detailEn: 'Define compartment boundaries per floor (max 250sqm). Mark on floor plan.',
    category: PlanningCategory.fireCompartments,
    isCritical: true,
  ),
  PlanningItem(
    id: 'fc_02',
    titleEl: 'Έλεγχος πυράντοχων πορτών (30-60 λεπτά)',
    titleEn: 'Fire door inspection (30-60 min rating)',
    detailEl: 'Επαλήθευση ότι κλείνουν αυτόματα, χωρίς εμπόδια. Ημερομηνία τελευταίου ελέγχου.',
    detailEn: 'Verify auto-close function, no obstructions. Record last inspection date.',
    category: PlanningCategory.fireCompartments,
    isCritical: true,
  ),
  PlanningItem(
    id: 'fc_03',
    titleEl: 'Πρωτόκολλο οριζόντιας εκκένωσης ανά compartment',
    titleEn: 'Horizontal evacuation protocol per compartment',
    detailEl: 'Κάθε compartment → ποιο γειτονικό λαμβάνει τους ασθενείς; Χωρητικότητα;',
    detailEn: 'Each compartment → which adjacent compartment receives patients? Capacity?',
    category: PlanningCategory.fireCompartments,
    isCritical: true,
  ),
  PlanningItem(
    id: 'fc_04',
    titleEl: 'Είσοδος πυροσβεστικής: ΔΙΑΦΟΡΕΤΙΚΗ από έξοδο εκκένωσης',
    titleEn: 'Fire dept entry: SEPARATE from evacuation exit',
    detailEl: 'Πυροσβεστική: Είσοδος Β (Βόρεια). Εκκένωση ασθενών: Νότια/Ανατολική έξοδος.',
    detailEn: 'Fire dept: North Entry B. Patient evacuation: South/East exit.',
    category: PlanningCategory.fireCompartments,
    isCritical: true,
  ),
  PlanningItem(
    id: 'fc_05',
    titleEl: 'Σήμανση "Είσοδος Πυροσβεστικής" στην πρόσοψη',
    titleEn: 'Fire dept entry signage on building facade',
    detailEl: 'Πινακίδα εξωτερικά + σε χάρτη που δίνεται στην Πυροσβεστική πριν το συμβάν.',
    detailEn: 'External sign + map shared with Fire Dept pre-event.',
    category: PlanningCategory.fireCompartments,
    isCritical: false,
  ),

  // ══ ΔΟΜΙΚΑ / ΦΥΣΙΚΑ ══
  PlanningItem(
    id: 'st_01',
    titleEl: 'Πρωτεύουσες & εφεδρικές σκάλες εκκένωσης',
    titleEn: 'Primary & secondary evacuation stairwells',
    detailEl: 'Σκάλες Α = πρωτεύουσες. Σκάλες Β = εφεδρικές. Χωρίς εξοπλισμό στους διαδρόμους.',
    detailEn: 'Stairwell A = primary. Stairwell B = secondary. No equipment in corridors.',
    category: PlanningCategory.structural,
    isCritical: true,
  ),
  PlanningItem(
    id: 'st_02',
    titleEl: 'Σημεία συγκέντρωσης (Assembly Points) — 3 σημεία',
    titleEn: 'Assembly points — minimum 3 locations',
    detailEl: 'Αυλή Α (κύρια), Αυλή Β (εφεδρική), Πάρκινγκ Γ (για ΜΕΘ/ΜΕΝΝ). Χωρητικότητα;',
    detailEn: 'Courtyard A (main), Courtyard B (backup), Parking C (ICU/NICU). Capacity?',
    category: PlanningCategory.structural,
    isCritical: true,
  ),
  PlanningItem(
    id: 'st_03',
    titleEl: 'Staging area για ασθενοφόρα/ΕΚΑΒ',
    titleEn: 'Staging area for ambulances/EKAV',
    detailEl: 'Πού σταθμεύουν τα οχήματα; Να μην εμποδίζουν πεζή εκκένωση.',
    detailEn: 'Where do vehicles stage? Must not block pedestrian evacuation.',
    category: PlanningCategory.structural,
    isCritical: true,
  ),
  PlanningItem(
    id: 'st_04',
    titleEl: 'Ramps για φορεία / αναπηρικά καροτσάκια',
    titleEn: 'Ramps for stretchers / wheelchairs',
    detailEl: 'Έλεγχος κλίσης (max 1:12). Ελεύθεροι; Φωτισμός έκτακτης ανάγκης;',
    detailEn: 'Check slope (max 1:12). Clear? Emergency lighting?',
    category: PlanningCategory.structural,
    isCritical: false,
  ),
  PlanningItem(
    id: 'st_05',
    titleEl: 'Φωτισμός έκτακτης ανάγκης σε όλες τις οδούς εκκένωσης',
    titleEn: 'Emergency lighting on all evacuation routes',
    detailEl: 'Λειτουργεί σε διακοπή ρεύματος; Τελευταίος έλεγχος;',
    detailEn: 'Operational during power failure? Last test date?',
    category: PlanningCategory.structural,
    isCritical: true,
  ),

  // ══ ΚΛΙΝΙΚΑ / PEEP ══
  PlanningItem(
    id: 'cl_01',
    titleEl: 'PEEP καταχώριση για ΟΛΟΥΣ τους νοσηλευόμενους',
    titleEn: 'PEEP registration for ALL inpatients',
    detailEl: 'E1=Κινητός, E2=Βοήθεια, E3=Wheelchair/φορείο, E4=ICU/Αναπνευστήρας. Ενημέρωση κατά εισαγωγή.',
    detailEn: 'E1=Mobile, E2=Assisted, E3=Wheelchair/stretcher, E4=ICU/Ventilator. Update on admission.',
    category: PlanningCategory.clinical,
    isCritical: true,
  ),
  PlanningItem(
    id: 'cl_02',
    titleEl: 'Λίστα E4 ασθενών με εξοπλισμό μεταφοράς',
    titleEn: 'E4 patient list with transfer equipment',
    detailEl: 'Ανά E4: ποιος αναπνευστήρας, ποια κανάλια, πόσο προσωπικό (min 4 άτομα/ασθενή).',
    detailEn: 'Per E4: which ventilator, which lines, how many staff (min 4/patient).',
    category: PlanningCategory.clinical,
    isCritical: true,
  ),
  PlanningItem(
    id: 'cl_03',
    titleEl: 'Προσυμφωνημένα receiving hospitals (min 5)',
    titleEn: 'Pre-arranged receiving hospitals (min 5)',
    detailEl: 'Επαφές, χωρητικότητα ΜΕΘ/ΜΕΝΝ/παθολογικές. Ενημέρωση κάθε 3 μήνες.',
    detailEn: 'Contacts, ICU/NICU/medical capacity. Update every 3 months.',
    category: PlanningCategory.clinical,
    isCritical: true,
  ),
  PlanningItem(
    id: 'cl_04',
    titleEl: 'Πρωτόκολλο "Go-Bag" ανά κλίνη',
    titleEn: 'Per-bed "Go-Bag" protocol',
    detailEl: 'Ποια φάρμακα/αρχεία συνοδεύουν τον ασθενή; Face sheet HICS 254;',
    detailEn: 'Which meds/records travel with patient? HICS 254 face sheet?',
    category: PlanningCategory.clinical,
    isCritical: false,
  ),

  // ══ ΕΠΙΧΕΙΡΗΣΙΑΚΑ / HICS ══
  PlanningItem(
    id: 'op_01',
    titleEl: 'Incident Commander + αναπληρωτής (ορισμένοι)',
    titleEn: 'Incident Commander + deputy (designated)',
    detailEl: 'Ονόματα, τηλέφωνα, εξουσία ενεργοποίησης. Γνωστό σε ΟΛΟ το προσωπικό.',
    detailEn: 'Names, phones, activation authority. Known to ALL staff.',
    category: PlanningCategory.operational,
    isCritical: true,
  ),
  PlanningItem(
    id: 'op_02',
    titleEl: 'Decision triggers: μερική vs πλήρης εκκένωση',
    titleEn: 'Decision triggers: partial vs full evacuation',
    detailEl: 'π.χ. Φωτιά 1 compartment = οριζόντια. Φωτιά 2+ ορόφων = κατακόρυφη. Σεισμός ≥6R = πλήρης.',
    detailEn: 'e.g. Fire 1 compartment = horizontal. Fire 2+ floors = vertical. Earthquake ≥6R = full.',
    category: PlanningCategory.operational,
    isCritical: true,
  ),
  PlanningItem(
    id: 'op_03',
    titleEl: 'Job Action Sheets διανεμημένα σε όλους τους ρόλους',
    titleEn: 'Job Action Sheets distributed to all roles',
    detailEl: '8 ρόλοι HICS. Κάθε άτομο γνωρίζει το JAS του. Επαναλαμβανόμενη εκπαίδευση.',
    detailEn: '8 HICS roles. Each person knows their JAS. Recurring training.',
    category: PlanningCategory.operational,
    isCritical: true,
  ),
  PlanningItem(
    id: 'op_04',
    titleEl: 'Άσκηση εκκένωσης (τουλάχιστον 1x/έτος)',
    titleEn: 'Evacuation drill (at least 1x/year)',
    detailEl: 'Tabletop + functional drill. After-Action Review. Βελτίωση πλάνου βάσει ευρημάτων.',
    detailEn: 'Tabletop + functional drill. After-Action Review. Plan improvement based on findings.',
    category: PlanningCategory.operational,
    isCritical: false,
  ),
  PlanningItem(
    id: 'op_05',
    titleEl: 'Πρωτόκολλο ασφάλειας κτιρίου (Security Branch)',
    titleEn: 'Building security protocol (Security Branch)',
    detailEl: 'Κλείδωμα εισόδων κατά εκκένωση. Έλεγχος μη εξουσιοδοτημένων. Escort πυροσβεστικής.',
    detailEn: 'Lock entries during evacuation. Control unauthorized access. Fire dept escort.',
    category: PlanningCategory.operational,
    isCritical: false,
  ),

  // ══ ΕΠΙΚΟΙΝΩΝΙΑ ══
  PlanningItem(
    id: 'co_01',
    titleEl: 'Κωδικές λέξεις (Code Red, Code Orange κ.λπ.)',
    titleEn: 'Code words (Code Red, Code Orange, etc.)',
    detailEl: 'Γνωστές σε ΟΛΟ το προσωπικό. Αναρτημένες στις νοσηλευτικές σταθμίσεις.',
    detailEn: 'Known to ALL staff. Posted at nursing stations.',
    category: PlanningCategory.communication,
    isCritical: true,
  ),
  PlanningItem(
    id: 'co_02',
    titleEl: 'Backup επικοινωνία (walkie-talkie, δρομείς)',
    titleEn: 'Backup communication (walkie-talkie, runners)',
    detailEl: 'Αν πέσει το δίκτυο/κινητά. Φορτισμένα walkie-talkie στο HCC. Πρωτόκολλο δρομέων.',
    detailEn: 'If network/mobile fails. Charged walkie-talkies at HCC. Runner protocol.',
    category: PlanningCategory.communication,
    isCritical: true,
  ),
  PlanningItem(
    id: 'co_03',
    titleEl: 'Ενημέρωση οικογενειών — πρωτόκολλο & σημείο',
    titleEn: 'Family notification — protocol & location',
    detailEl: 'Πού συγκεντρώνονται οικογένειες; Ποιος τους ενημερώνει (PIO); Τι τους λέμε;',
    detailEn: 'Where do families ga
