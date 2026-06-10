import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _i = DatabaseService._();
  factory DatabaseService() => _i;
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'gsoilflow.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await _createTables(db);
        await _seedMachines(db);
      },
    );
  }

  // ── Tables ──────────────────────────────────────────────────────────────
  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      is_logged_in INTEGER DEFAULT 0)''');

    await db.execute('''CREATE TABLE machine_families(
      code TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT DEFAULT "⚙️")''');

    await db.execute('''CREATE TABLE machine_subfamilies(
      code TEXT PRIMARY KEY,
      parent_code TEXT NOT NULL,
      name TEXT NOT NULL,
      icon TEXT DEFAULT "🔧")''');

    await db.execute('''CREATE TABLE machines(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subfamily_code TEXT NOT NULL,
      name TEXT NOT NULL)''');

    await db.execute('''CREATE TABLE shifts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      start_time TEXT,
      start_counter REAL,
      start_photo TEXT,
      end_time TEXT,
      end_counter REAL,
      end_photo TEXT,
      status TEXT DEFAULT "open")''');

    await db.execute('''CREATE TABLE operations(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shift_id INTEGER NOT NULL,
      family_name TEXT,
      subfamily_name TEXT,
      machine_id INTEGER,
      machine_name TEXT,
      quantity REAL,
      compteur_vol REAL,
      photo_path TEXT,
      timestamp TEXT DEFAULT (datetime("now","localtime")))''');
  }

  // ── Seed machines ────────────────────────────────────────────────────────
  Future<void> _seedMachines(Database db) async {
    final batch = db.batch();

    // Familles
    for (var f in _families) {
      batch.insert('machine_families', f, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // Sous-familles
    for (var sf in _subfamilies) {
      batch.insert('machine_subfamilies', sf, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // Machines
    for (var m in _machines) {
      batch.insert('machines', m, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  String _hash(String pwd) =>
      sha256.convert(utf8.encode(pwd)).toString();

  Future<bool> registerUser(String username, String password) async {
    try {
      final d = await db;
      await d.insert('users', {'username': username, 'password': _hash(password)});
      return true;
    } catch (_) { return false; }
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final d    = await db;
    final rows = await d.query('users',
        where: 'username=? AND password=?',
        whereArgs: [username, _hash(password)]);
    if (rows.isEmpty) return null;
    await d.update('users', {'is_logged_in': 1}, where: 'username=?', whereArgs: [username]);
    return rows.first;
  }

  Future<void> logoutUser(String username) async {
    final d = await db;
    await d.update('users', {'is_logged_in': 0}, where: 'username=?', whereArgs: [username]);
  }

  // ── Machines ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFamilies() async {
    final d = await db;
    return d.query('machine_families', orderBy: 'name');
  }

  Future<List<Map<String, dynamic>>> getSubfamilies(String familyCode) async {
    final d = await db;
    return d.query('machine_subfamilies',
        where: 'parent_code=?', whereArgs: [familyCode], orderBy: 'name');
  }

  Future<List<Map<String, dynamic>>> getMachines(String subfamilyCode) async {
    final d = await db;
    return d.query('machines',
        where: 'subfamily_code=?', whereArgs: [subfamilyCode], orderBy: 'name');
  }

  Future<List<Map<String, dynamic>>> searchMachines(String query) async {
    final d = await db;
    return d.rawQuery('''
      SELECT m.*, s.name as subfamily_name, f.name as family_name
      FROM machines m
      JOIN machine_subfamilies s ON m.subfamily_code = s.code
      JOIN machine_families f ON s.parent_code = f.code
      WHERE m.name LIKE ?
      ORDER BY m.name
    ''', ['%$query%']);
  }

  // ── Shifts ────────────────────────────────────────────────────────────────
  Future<int> startShift(String username, double counter, String photo) async {
    final d = await db;
    return d.insert('shifts', {
      'username': username,
      'start_time': DateTime.now().toIso8601String(),
      'start_counter': counter,
      'start_photo': photo,
      'status': 'open',
    });
  }

  Future<void> endShift(int shiftId, double counter, String photo) async {
    final d = await db;
    await d.update('shifts', {
      'end_time': DateTime.now().toIso8601String(),
      'end_counter': counter,
      'end_photo': photo,
      'status': 'closed',
    }, where: 'id=?', whereArgs: [shiftId]);
  }

  Future<Map<String, dynamic>?> getShift(int shiftId) async {
    final d    = await db;
    final rows = await d.query('shifts', where: 'id=?', whereArgs: [shiftId]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getOpenShift(String username) async {
    final d    = await db;
    final rows = await d.query('shifts',
        where: 'username=? AND status="open"',
        whereArgs: [username],
        orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  // ── Operations ────────────────────────────────────────────────────────────
  Future<void> addOperation({
    required int    shiftId,
    required String familyName,
    required String subfamilyName,
    required int    machineId,
    required String machineName,
    required double quantity,
    required double compteurVol,
    required String photoPath,
  }) async {
    final d = await db;
    await d.insert('operations', {
      'shift_id':       shiftId,
      'family_name':    familyName,
      'subfamily_name': subfamilyName,
      'machine_id':     machineId,
      'machine_name':   machineName,
      'quantity':       quantity,
      'compteur_vol':   compteurVol,
      'photo_path':     photoPath,
    });
  }

  Future<List<Map<String, dynamic>>> getShiftOperations(int shiftId) async {
    final d = await db;
    return d.query('operations', where: 'shift_id=?', whereArgs: [shiftId], orderBy: 'timestamp');
  }

  Future<Map<String, dynamic>> getShiftStats(int shiftId) async {
    final d    = await db;
    final rows = await d.rawQuery('''
      SELECT COUNT(*) as nb_ops, COALESCE(SUM(quantity),0) as total_qty
      FROM operations WHERE shift_id=?
    ''', [shiftId]);
    return rows.first;
  }

  // ── Import Excel ──────────────────────────────────────────────────────────
  Future<int> importFromExcel(Map<String, Map<String, List<String>>> data) async {
    final d     = await db;
    final batch = d.batch();
    int count   = 0;
    for (final familyName in data.keys) {
      final fCode = familyName.toUpperCase().replaceAll(' ', '_').substring(0, familyName.length.clamp(0, 20));
      batch.insert('machine_families', {'code': fCode, 'name': familyName, 'icon': '⚙️'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      final subfamilies = data[familyName]!;
      for (final sfName in subfamilies.keys) {
        final sfCode = '${fCode}_${sfName.toUpperCase().replaceAll(' ', '_')}'.substring(0,
            (fCode.length + sfName.length + 1).clamp(0, 30));
        batch.insert('machine_subfamilies',
            {'code': sfCode, 'parent_code': fCode, 'name': sfName, 'icon': '🔧'},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final mName in subfamilies[sfName]!) {
          if (mName.trim().isEmpty) continue;
          batch.insert('machines', {'subfamily_code': sfCode, 'name': mName.trim()},
              conflictAlgorithm: ConflictAlgorithm.ignore);
          count++;
        }
      }
    }
    await batch.commit(noResult: true);
    return count;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DONNÉES MACHINES (depuis Excel fourni)
// ═══════════════════════════════════════════════════════════════════════════
final _families = [
  {'code': 'HEAVY_MACHINES',  'name': 'Engins Lourds',         'icon': '🏗️'},
  {'code': 'RENT_MACHINES',   'name': 'Machines de Location',  'icon': '🔑'},
  {'code': 'CARS',            'name': 'Véhicules',             'icon': '🚗'},
  {'code': 'GENERATORS',      'name': 'Groupes Électrogènes',  'icon': '⚡'},
  {'code': 'DEPARTMENTS',     'name': 'Départements',          'icon': '🏭'},
];

final _subfamilies = [
  {'code':'HM_SKID',      'parent_code':'HEAVY_MACHINES', 'name':'Skid / Bobcat',         'icon':'🟡'},
  {'code':'HM_LOADER',    'parent_code':'HEAVY_MACHINES', 'name':'Chargeur (Loader)',      'icon':'🚜'},
  {'code':'HM_CRANE',     'parent_code':'HEAVY_MACHINES', 'name':'Grue (Crane)',           'icon':'🏗️'},
  {'code':'HM_EXCAVATOR', 'parent_code':'HEAVY_MACHINES', 'name':'Excavatrice',            'icon':'⛏️'},
  {'code':'HM_FORKLIFT',  'parent_code':'HEAVY_MACHINES', 'name':'Chariot Élévateur',     'icon':'🍴'},
  {'code':'HM_GRAPIN',    'parent_code':'HEAVY_MACHINES', 'name':'Grappin',               'icon':'🦾'},
  {'code':'HM_STACKER',   'parent_code':'HEAVY_MACHINES', 'name':'Stackeur (Stacker)',    'icon':'📦'},
  {'code':'HM_TRUCK',     'parent_code':'HEAVY_MACHINES', 'name':'Camion / Véhicule',     'icon':'🚛'},
  {'code':'HM_MANLIFT',   'parent_code':'HEAVY_MACHINES', 'name':'Nacelle (Man Lift)',    'icon':'🔝'},
  {'code':'RM_FORKLIFT',  'parent_code':'RENT_MACHINES',  'name':'Chariot Élévateur Loc.','icon':'🍴'},
  {'code':'RM_STACKER',   'parent_code':'RENT_MACHINES',  'name':'Stackeur Loc.',         'icon':'📦'},
  {'code':'RM_MANLIFT',   'parent_code':'RENT_MACHINES',  'name':'Nacelle Loc.',          'icon':'🔝'},
  {'code':'RM_LOADER',    'parent_code':'RENT_MACHINES',  'name':'Chargeur Loc.',         'icon':'🚜'},
  {'code':'CAR_VEHICLE',  'parent_code':'CARS',           'name':'Véhicule Léger',        'icon':'🚗'},
  {'code':'GEN_GENERATOR','parent_code':'GENERATORS',     'name':'Groupe Électrogène',    'icon':'⚡'},
  {'code':'GEN_PUMP',     'parent_code':'GENERATORS',     'name':'Pompe Diesel',          'icon':'💧'},
  {'code':'DEPT_RM',      'parent_code':'DEPARTMENTS',    'name':'RM (Recyclage Matière)','icon':'♻️'},
  {'code':'DEPT_FIL',     'parent_code':'DEPARTMENTS',    'name':'Filière Mécanique',     'icon':'⚙️'},
  {'code':'DEPT_HEAVY',   'parent_code':'DEPARTMENTS',    'name':'Engins Lourds Dept.',   'icon':'🏗️'},
  {'code':'DEPT_WTP',     'parent_code':'DEPARTMENTS',    'name':'WTP',                   'icon':'💧'},
  {'code':'DEPT_CCM',     'parent_code':'DEPARTMENTS',    'name':'CCM',                   'icon':'🏭'},
  {'code':'DEPT_OTHER',   'parent_code':'DEPARTMENTS',    'name':'Autres Départements',   'icon':'🏢'},
];

final _machines = [
  // Skid / Bobcat
  for (var n in ['BCT-01 BCTAZNDGCHDA11111 - S590','BCT-02 BCTB1E6DJHDA17446 - S450',
    'BCT-03 CAT0216BCCD300364 - BOBCAT','BCT-04 CAT0236DVSEN00711 - BOBCAT',
    'BCT-05 HAKO 143322301713 - BOBCAT','BCT-06 CAT0226BTDXZ02396 - BOBCAT',
    'BCT-07 CAT0226BPDXZ02397 - BOBCAT','BCT-08 CAT0226BADXZ02343 - BOBCAT',
    'BCT-10 CAT0226BHDXZ02653 - BOBCAT','BCT-11 CAT0226BEDXZ02654 - BOBCAT',
    'BCT-216 CAT0216BEJXM02600 - BOBCAT','BM-01 CAT0236DLF9C01319 - BOBCAT',
    'BM-02 CAT0236DVF9C01317 - BOBCAT','BM-03 CAT0236DVF9C01348 - BOBCAT',
    'BM-04 CAT0236DKF9C01345 - BOBCAT','BM-05 CAT0236DTF9C01343 - BOBCAT',
    'BM-06 CAT0236DAF9C01349 - BOBCAT','BM-07 CAT0236DPF9C01344 - BOBCAT',
    'BM-08 CAT0236DAF9C01318 - BOBCAT','BM-09 CAT0236DJF9C01315 - BOBCAT',
    'BM-10 CAT0236DCF9C01311 - BOBCAT','BM-11 CAT0236DKF9C01314 - BOBCAT',
    'BM-12 CAT0236DPF9C01313 - BOBCAT','BM-13 CAT0226BVDXZ02339 - BOBCAT'])
    {'subfamily_code': 'HM_SKID', 'name': n},

  // Chargeurs
  for (var n in ['C01 S3E00201 - CAT 988','C02 S3E00202 - CAT 988','C03 S3E00203 - CAT 988',
    'C04 S3E00204 - CAT 988','CAT0980LPD8Z10395 - PERT','CAT 983D - 89G197',
    'LDR-02 CAT0986KTNL800264','LDR-03 CAT0973DVLCP00296 - CAT 973',
    'LDR-04 CAT0962HVMAL00591 - CAT 962','LDR-05 CAT0980LTD8Z10413',
    'LDR-06 CAT00444TL7M00332 - RETRO','LDR-07 CAT0962HVMAL00590 - CAT 962',
    'LDR-08 CAT0980LKD8Z10396','LDR-09 CAT0980HHPF800677',
    'LDR-10 CAT0444FCLYL00334','LDR-11 CAT0980LLD8Z10406',
    'LDR-20 CAT0444FHLYL00453 - RETRO','LDR-283 CAT0980LCD8Z20283',
    'LDR-286 CAT0980LLD8Z20286','LDR-950 CAT00950HM5K04716',
    'LDR-966 CAT0966LTFSL10310','LDR-973 CAT0973DVLCP00292',
    'LDR-980-12','LDR-980-13'])
    {'subfamily_code': 'HM_LOADER', 'name': n},

  // Grues
  for (var n in ['CRN-01 NMB96304212176804 - MERCEDES','CRN-02 NMB96304212176799 - MERCEDES',
    'CRN-03 NMB96304212177585 - MERCEDES','CRN-04 NMB94331712175141 - MERCEDES',
    'CRN-05 NMB94036512175546 - MERCEDES','CRN-06 NMB96304212177569 - MERCEDES',
    'CRN-07 NMB94036512176571 - MERCEDES','CRN-20 NMOMKXTP6MJU92928 - FORD',
    'CRN-220 WMGKB5173HZHF0390 - DEMAG'])
    {'subfamily_code': 'HM_CRANE', 'name': n},

  // Excavatrices
  for (var n in ['BROKK 400 rev.B3 981427','EXC-02 CAT0349DTGAX10229',
    'EXC-03 CAT0336DVHBH00224','EXC-04 CAT0336DVHBH00272',
    'EXC-05 CAT0320DHGDP01056','EXC-06 CAT0349DVYAE10072',
    'EXC-07 CAT 320D DHGDP00960','EXC-08 CAT0336DPHBH10083',
    'EXC-09 CAT00336KMZR30258','EXC-10 CAT00336CMZR30290',
    'EXC-11 CAT00350KWDP30129','EXC-12 CAT00350TWDP30130',
    'EXC-330 CAT0330DTSZK1366','EXC-345 CAT00345TKEF00401'])
    {'subfamily_code': 'HM_EXCAVATOR', 'name': n},

  // Chariots élévateurs
  for (var n in ['CY1 - TRCCY35DPS02408 - CEYLIFT','CY2 - TRCCY35DPS02407 - CEYLIFT',
    'CY3 - TRCCY100DPS0015 - CEYLIFT','CY4 - TRCCY100DPS0016 - CEYLIFT',
    'FL-01 J008E01568V - 32T','FL-02 H008E01631P - 32T','FL-03 C236E01626R - 20T',
    'FL-04 J019E02746N - 16T','FL-05 C236E01627R - 20T','FL-06 C236E01628R - 20T',
    'FL-07 H019E01508J - 16T','FL-09 J006V03764J - 7T','FL-10 K006E02307R - 7T',
    'FL-11 K006E02303R - 7T','FL-12 K006E02305R - 7T','FL-13 U005B03511R - 5T',
    'FL-14 U005B03523R - 5T','FL-15 K006E02306R - 7T','FL-17 P177B04280P - 3.5T',
    'FL-18 K006E02304R - 7T','FL-19 U005B03596R - 5T','FL-21 R005B02017K - 5T',
    'FL-22 U005B03524R - 5T','FL-23 P177B06843S - 3.5T','FL-24 U005B03512R - 5T',
    'FL-25 K160B08765P - 1.6T HYSTER','FL-27 L177B37408K - 3.5T',
    'FL-28 J008E01616W - 32T','FL-29 J008E01622W - 32T','FL-30 J008E01555V - 32T',
    'FL-31 P177B12801W - 3.5T','FL-32 R177B03328X - 3.5T',
    'FL-33 HHKHB103CK0001194 - 3T HYUNDAI',
    'TIR-01 TSCHE3T6987 - 3T','TIR-02 TSCHE3T7247 - 3T'])
    {'subfamily_code': 'HM_FORKLIFT', 'name': n},

  // Grappins
  for (var n in ['GRP-01 835.5.3101 - SENNEBOGEN','GRP-03 835-0-2320 - SENNEBOGEN',
    'GRP-05 835-0-2318 - SENNEBOGEN','GRP-06 835-00-2094 - SENNEBOGEN',
    'GRP-07 835-00-2026 - SENNEBOGEN','GRP-08 WLHZ1049CZK073135 - LIEBHERR 924',
    'GRP-10 835-0-2321 - SENNEBOGEN','GRP-11 835-00-2048 - SENNEBOGEN',
    'GRP-12 WLHZ1006KZK071272 - LIEBHERR 934','GRP-13 WLHZ1071LZK038032 - LIEBHERR 904',
    'GRP-14 WLHZ1006HZK029323 - LIEBHERR 934','GRP-15 WLHZ1006LZK064160 - LIEBHERR 934',
    'GRP-16 835-0-3073 - SENNEBOGEN','GRP-17 WLHZ1006LZK070730 - LIEBHERR 934',
    'GRP-18 WLHZ1049EZK074221 - LIEBHERR 924','GRP-19 WLHZ1049JZK073593 - LIEBHERR 924',
    'GRP-35 WLHZ1049CZK071263 - LIEBHERR','GRP-350 350410 5283 - FUCHS',
    'GRP-36 - LIEBHERR 924','GRP-360 360410 5862 - FUCHS',
    'GRP-830 830.0.309 - SENNEBOGEN','GRP-95 835-5-3095 - SENNEBOGEN',
    'GRP-T01 WLHZ1049TZK073282 - LIEBHERR 924','GRP-T05 WLHZ1049EZK074607 - LIEBHERR 924',
    'GRP-T07 - LIEBHERR 924','GRP-T11 WLHZ1049TZK062164 - LIEBHERR 934',
    'LIEBHERR S19','LIEBHERR T02',
    'PRESSE MOBILE-01 VV9G3G139DA100003','PRESSE MOBILE-02 VV9G3G139DA100002'])
    {'subfamily_code': 'HM_GRAPIN', 'name': n},

  // Stackeurs
  for (var n in ['KC-01 550503044 - KALMAR','KC-02 550503043 - KALMAR',
    'KC-03 H11602029 DRU450-62S5 - KALMAR','KC-04 H11602038 DRU450-62S5 - KALMAR'])
    {'subfamily_code': 'HM_STACKER', 'name': n},

  // Camions
  for (var n in ['HSE-01 WMA18SZZXMP153737 - MAN','HSE-02 B9BM958478NB279409 - MERCEDES AXOR',
    'TR-01 WMA03WZZ1DM625553 - MAN 1940','TR-02 WMA03WZZ2DM625531 - MAN 1940',
    'TR-03 WMA39WZZ6DM628024 - MAN 4140 20T','TR-04 WMA39WZZ3DM628000 - MAN 4140',
    'TR-05 WMA26WZZ1DM628453 - MAN 3336 15T','TR-06 NMOLKXTP6LDR93194 - FORD HSE',
    'TR-08 NMOLKXTR6LFP96830 - FORD CITERNE','TR-09 NMOKKXTP6KFU94546 - FORD CAMION',
    'TR-10 NM0KKXTP6KFM94729 - FORD CAMION','TR-11 NMOLKXTP6LFE98909 - FORD VIDANGE',
    'TR-12 NMOMKXTP6MDU90993 - FORD','V-01 NMC833PDFLK100012',
    'V-02 NMC833PDFLK100013','V-03 NMC833PDFLK100014',
    'LJ11KCBC7E9009137 - CAMION JAC','NISSAN N400 LJNOKA539DX114976',
    'S01 NP9HS2240J3002202','MERCEDES SPRINTER LOGISTIQUE'])
    {'subfamily_code': 'HM_TRUCK', 'name': n},

  // Nacelles
  for (var n in ['MAN LIFT-01 300238810 - JLG 800A',
    'MAN LIFT-02 300197711 - JLG 1200SJ','MAN LIFT-03 300237156 - JLG 1850'])
    {'subfamily_code': 'HM_MANLIFT', 'name': n},

  // Location
  for (var n in ['KALMAR - Location','LINDE - Location','SOKOMA - Location',
    'DOOSAN - Location','SARENS 1792 - Location','SARENS 5627 - Location',
    'SARENS 6235 - Location','DEUTRUCK - Location','ENGIN PLUS FL - Location'])
    {'subfamily_code': 'RM_FORKLIFT', 'name': n},
  {'subfamily_code': 'RM_STACKER', 'name': 'CATRAM STACKER - Location'},
  {'subfamily_code': 'RM_STACKER', 'name': 'HYSTER STACKER - Location'},
  {'subfamily_code': 'RM_MANLIFT', 'name': 'FARISIA - Location'},
  {'subfamily_code': 'RM_LOADER',  'name': 'ENGIN PLUS XGMA - Location'},

  // Véhicules légers
  for (var n in ['00025-416-31','00218-118-29','00268-320-31','00310-321-29','00314-321-18',
    '00342-119-29','00396-320-31','00674-322-31','00675-322-31','00691-322-31',
    '00813-321-31','00814-321-31','00815-321-31','00821-321-31','00884-322-31',
    '00897-321-31','00908-321-31','00974-321-31','01121-322-31','01149-322-31',
    '01299-320-31','01956-317-31','02169-322-16','02359-324-31','02472-319-31',
    '02612-119-29','02621-319-31','02963-324-31','03294-324-31','06090-315-31',
    '06289-00-14','06301-315-31','0885-322-31','17733-118-31','18862-119-31',
    '22255-119-31','22774-118-31','22811-118-31','22930-118-31','23504-119-31',
    '23505-119-31','23525-119-31','249081-00-16','26193-119-31','26439-119-31','23597-119-31'])
    {'subfamily_code': 'CAR_VEHICLE', 'name': n},

  // Groupes électrogènes
  for (var n in ['GN-01  65 KVA - 4BTA5.9-G2','GN-02  180 KVA - 6CTA8.3-G2',
    'GN-03  35 KVA - 3029DF120','GN-04  110 KVA - 6BT5.9-G2','GN-05  15 KVA - 403A-15G',
    'GN-06  180 KVA - 6CTA8.3-G2','GN-07  350 KVA - NTA855-G18','GN-08  180 KVA - 6CTA8.3-G2',
    'GN-09  110 KVA - 2506/1500','GN-10  100 KVA - DD21925','GN-11  15 KVA - U03A-15G1',
    'GN-12  15 KVA - U03A-15G1','GN-13  11 KVA','GN-14  11 KVA','GN-16  35 KVA - 2490/1500',
    'GN-17  75 KVA - 2634/1500','GN-18  200 KVA - 4196/1500','GN-19  200 KVA - 4196/1500',
    'GN-20  200 KVA - P086TI','GN-21  200 KVA - 6CTA8.3-G2','GN-22  110 KVA - 6BT5.9-G2',
    'GN-23  200 KVA - 6CTA8.3-G2','GN-24  200 KVA - 6CTA8.3-G2','GN-25  200 KVA - P086TI',
    'GN-26  APD 43C - 4BTA3.9-G2','GN-27  APD 66C - 4BTA3.9-G2','GN-28  74 KVA - RS51276',
    'GN-29  35 KVA - INT35','GN-30  66 KVA','GN-31  500 KVA - Q5X15-G8',
    'GN-32  450 KVA - NTAA855-G7','GN-33  480 KVA - P158LE','GN-34  700 KVA - UTA-28-G5',
    'GN-35  600 KVA - P222LF','GN-36  350 KVA - QSL9-G5','GN-37  1650 KVA - KTA50-G8',
    'GN-38  1650 KVA - KTA50-G9','GN-39  1650 KVA - KTA50-G10','GN-40  1650 KVA - KTA50-G11',
    'GN-41  1425 KVA - S12R-PTA','GN-42  1850 KVA - S16R-PTA','GN-43  2000 KVA - S16R2-PTAW',
    'GN-44  2250 KVA - S16R2-PTAW','GN-45  1250 KVA - S12R-PTA','GN-46  1850 KVA - S16R-PTA2',
    'GN-47  1100 KVA - S12M-PTA','GN-48  1100 KVA - S12M-PTA','GN-49  2500 KVA - QSK60-G4',
    'GN-50  1500 KVA','GN-51  1015 KVA - DP222CC','GN-52  2500 KVA - S16R2-PTAW',
    'GN-53  1425 KVA - S12R-PTA','GN-54  2500 KVA - S16R2-PTAW','GN-55  180 KVA - 6CTA8.3-G2',
    'GN-56  2100 KVA - S16R-PTAA2','GN-57  1750 KVA - S12R-PTAA2',
    'GN-58  2250 KVA - S16R-PTAA2','GN-59  2250 KVA - S16R-PTA2','GN-60  3000 KVA - C3000 D5',
    'GN-61  500 KVA','GN-62  5 KVA','GN-63  5 KVA','GN-64  5 KVA','GN-65  5 KVA',
    'GN-102  425 KVA','GN-103  35 KVA','GN-104  1000 KVA','GN-105  1000 KVA',
    'GN-LIGHT-106','GN-LIGHT-107','GN-108  150 KVA','GN-109  220 KVA','GN-110  220 KVA',
    'GN-111','GN-112','GN-113','GN-114','GN-115','GN-116','GN-117  35 KVA',
    'GN-119  35 KVA','GN-120  35 KVA','GN-SOUDURE 01','GN-SOUDURE 02','GN-SOUDURE 03',
    'KARMADJ GEN 01','KARMADJ GEN 02','GEN PRIVÉ','GEN 35 KVA','GEN 118',
    'FORD GEN-01','FORD GEN-02'])
    {'subfamily_code': 'GEN_GENERATOR', 'name': n},

  // Pompes diesel
  for (var n in ['DP-01 DK 51280','DP-02 233221800','DP-03 F4GE0457A','DP-04 15408042',
    'DP-05 15408041','DP-06 15408002','DP-07 B600-01278083','DP-08 22DWD226C',
    'DP-09 1841129','DP-10 Y210905576','DP-11 4045TF252','DP-12 4045TF254',
    'DP-13 04.2088/2320028','DP-14 41240741','DP-15 78338746','DP-16 78575056',
    'DP-17 6068TF252','DP-18 4045TF254','DP-19 41337636','DP-20 93086951',
    'DP-21 93074948','DP-22 93082802','DP-23 93082801','DP-24 93110631',
    'DP-25 93110630','DP-26 PE4045E027719','DP-27 1791123044923',
    'COMPRESSEUR HARSCO','ARABA N°01 MELTSHOP 1','ARABA N°02 MELTSHOP 1',
    'ARABA N°03 MELTSHOP 2','ARABA N°04 MELTSHOP 3'])
    {'subfamily_code': 'GEN_PUMP', 'name': n},

  // Départements
  for (var n in ['RM1','RM2','RM3']) {'subfamily_code': 'DEPT_RM',    'name': n},
  {'subfamily_code': 'DEPT_FIL',   'name': 'Filière Mécanique'},
  {'subfamily_code': 'DEPT_HEAVY', 'name': 'Engins Lourds'},
  {'subfamily_code': 'DEPT_WTP',   'name': 'WTP'},
  for (var n in ['CCM 1','CCM 2','CCM 3']) {'subfamily_code': 'DEPT_CCM', 'name': n},
  for (var n in ['SHREDDER','SPIRAL PIPE','ATELIER HYDRAULIQUE','ATELIER CONSTRUCTION',
    'SMP 01','SMP 02','SMP 03','PELLETISATION','DRI','FTP','FTP-02',
    'FABRIQUE DE CHAUX','HSM'])
    {'subfamily_code': 'DEPT_OTHER', 'name': n},
];
