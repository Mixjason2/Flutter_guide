import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../MainLayout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../components/date_picker_row.dart';
import '../components/job_group_card.dart';
import '../components/pagination_control.dart';

class Job {
  final String pnrDate;
  final String pickup;
  final String dropoff;
  final String pickupDate;
  final String dropoffDate;
  final bool isCancel;
  final bool isConfirmed;
  final bool isNew;
  final int adultQty;
  final int childQty;
  final int childShareQty;
  final int infantQty;
  final String pnr;

  Job({
    required this.pickup,
    required this.dropoff,
    required this.pnrDate,
    required this.pickupDate,
    required this.dropoffDate,
    required this.isCancel,
    required this.isConfirmed,
    required this.isNew,
    required this.adultQty,
    required this.childQty,
    required this.childShareQty,
    required this.infantQty,
    required this.pnr,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      pickup: json['Pickup'],
      dropoff: json['Dropoff'],
      pnrDate: json['PNRDate'],
      pickupDate: json['PickupDate'],
      dropoffDate: json['DropoffDate'],
      isCancel: json['IsCancel'] ?? false,
      isConfirmed: json['IsConfirmed'] ?? false,
      isNew: json['isNew'] ?? false,
      adultQty: json['AdultQty'] ?? 0,
      childQty: json['ChildQty'] ?? 0,
      childShareQty: json['ChildShareQty'] ?? 0,
      infantQty: json['InfantQty'] ?? 0,
      pnr: json['PNR'] ?? '',
    );
  }

  int get pax => adultQty + childQty + childShareQty + infantQty;
}

final storage = FlutterSecureStorage();

// เก็บ token
Future<void> saveToken(String token) async {
  await storage.write(key: 'auth_token', value: token);
}

// อ่าน token
Future<String?> readToken() async {
  return await storage.read(key: 'auth_token');
}

// ลบ token
Future<void> deleteToken() async {
  await storage.delete(key: 'auth_token');
}

class JobsListPage extends StatefulWidget {
  @override
  _JobsListPageState createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  List<Job> jobs = [];
  bool loading = false;
  String? error;

  // เริ่มต้น login: startDate = พรุ่งนี้, endDate = พรุ่งนี้ + 30 วัน
  DateTime startDate = DateTime.now().add(Duration(days: 1));
  DateTime endDate = DateTime.now().add(Duration(days: 31));

  bool showConfirmedOnly = false;
  bool showPendingOnly = false;
  bool showNewOnly = false;
  bool showAllFilteredJobs = false;

  int page = 1;
  final int pageSize = 6;
  Map<String, bool> expandedPNRs = {};
  List<Job>? detailJobs;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await readToken(); // ดึง token จาก storage

      if (token == null) {
        setState(() {
          error = 'No token found. Please login.';
          loading = false;
        });
        print('[LOG] No token found');
        return;
      }

      final requestBody = jsonEncode({
        'token': token,
        'startdate': startDate.toIso8601String().split('T')[0],
        'enddate': endDate.toIso8601String().split('T')[0],
      });
      print('[LOG] Request body: $requestBody');
      final res = await http.post(
        Uri.parse('https://operation.dth.travel:7082/api/guide/job'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('[LOG] Response status: ${res.statusCode}');
      print('[LOG] Response body: ${res.body}');

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        jobs = data.map((e) => Job.fromJson(e)).toList();
        print('[LOG] Jobs loaded: ${jobs.length}');
      } else {
        error = 'Error ${res.statusCode}';
        print('[LOG] Error: $error');
      }
    } catch (e) {
      error = e.toString();
      print('[LOG] Exception: $e');
    }

    setState(() => loading = false);
  }

  Map<String, List<Job>> get groupedByPNRDate {
    final grp = <String, List<Job>>{};
    final filtered = jobs.where((job) {
      if (job.isCancel) return false;

      // แปลง String เป็น DateTime เพื่อเทียบช่วงวันที่
      final pdDate = DateTime.tryParse(job.pickupDate) ?? DateTime(1970);
      final ddDate = DateTime.tryParse(job.dropoffDate) ?? DateTime(1970);

      return (pdDate.isAfter(startDate.subtract(Duration(days: 1))) &&
          ddDate.isBefore(endDate.add(Duration(days: 1))));
    }).toList();

    for (var job in filtered) {
      grp[job.pnrDate] ??= [];
      grp[job.pnrDate]!.add(job);
    }

    final filteredGrp = grp
      ..removeWhere((pnr, list) {
        if (showNewOnly) return !list.any((e) => e.isNew);
        if (showConfirmedOnly) return !list.any((e) => e.isConfirmed);
        if (showPendingOnly)
          return !list.any((e) => !e.isConfirmed && !e.isCancel);
        return false;
      });

    return Map.fromEntries(
      filteredGrp.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  List<MapEntry<String, List<Job>>> get pagedGroups {
    final groups = groupedByPNRDate.entries.toList();
    if ((showConfirmedOnly || showPendingOnly || showNewOnly) &&
        showAllFilteredJobs) {
      return groups;
    }
    final start = (page - 1) * pageSize;
    return groups.skip(start).take(pageSize).toList();
  }

  void _onDateRangeChanged(DateTime newStart, DateTime newEnd) {
    // จำกัดช่วงระหว่าง startDate กับ endDate ไม่เกิน 91 วัน
    final maxRange = Duration(days: 91);
    if (newEnd.isBefore(newStart)) {
      // ถ้า endDate < startDate ให้ขยับ startDate ไปเท่ากับ endDate
      newStart = newEnd;
    }
    if (newEnd.difference(newStart).inDays > 91) {
      // ถ้าเลือก endDate ไปข้างหน้ามากกว่า 91 วัน ให้ขยับ startDate ไปข้างหน้าด้วย
      newStart = newEnd.subtract(maxRange);
    }
    setState(() {
      startDate = newStart;
      endDate = newEnd;
      page = 1;
    });
    fetchJobs();
  }

  String formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      // Example: 15/Jul/2025
      return "${dt.day.toString().padLeft(2, '0')}/${_monthShort(dt.month)}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _monthShort(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (groupedByPNRDate.length / pageSize).ceil();

    return MainLayout(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: DatePickerRow(
                    startDate: startDate,
                    endDate: endDate,
                    onDateRangeChanged: _onDateRangeChanged,
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: pagedGroups.map((entry) {
                      final pnr = entry.key;
                      final list = entry.value;
                      final expanded = expandedPNRs[pnr] ?? false;
                      return Center(
                        child: Container(
                          width: 500,
                          child: JobGroupCard(
                            pnr: pnr,
                            jobs: list,
                            expanded: expanded,
                            onExpansionChanged: (e) {
                              setState(() {
                                expandedPNRs[pnr] = e;
                                if (e) detailJobs = list;
                              });
                            },
                            formatDate: formatDate,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (!(showConfirmedOnly || showNewOnly || showPendingOnly))
                  PaginationControl(
                    currentPage: page,
                    totalPages: totalPages,
                    onPrev: () => setState(() {
                      page--;
                      expandedPNRs.clear();
                    }),
                    onNext: () => setState(() {
                      page++;
                      expandedPNRs.clear();
                    }),
                  ),
                if ((showConfirmedOnly || showNewOnly || showPendingOnly))
                  TextButton(
                    child: Text(
                      showAllFilteredJobs ? 'Show less' : 'Load more',
                    ),
                    onPressed: () => setState(
                      () => showAllFilteredJobs = !showAllFilteredJobs,
                    ),
                  ),
              ],
            ),
    );
  }
}
