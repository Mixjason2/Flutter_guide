import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../MainLayout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Job {
  final String pnrDate;
  final String pickupDate;
  final String dropoffDate;
  final bool isCancel;
  final bool isConfirmed;
  final bool isNew;

  Job({
    required this.pnrDate,
    required this.pickupDate,
    required this.dropoffDate,
    required this.isCancel,
    required this.isConfirmed,
    required this.isNew,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      pnrDate: json['PNRDate'],
      pickupDate: json['PickupDate'],
      dropoffDate: json['DropoffDate'],
      isCancel: json['IsCancel'] ?? false,
      isConfirmed: json['IsConfirmed'] ?? false,
      isNew: json['isNew'] ?? false,
    );
  }
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

  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

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
        return;
      }

      final res = await http.post(
        Uri.parse('https://operation.dth.travel:7082/api/guide/job'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'startdate': startDate.toIso8601String().split('T')[0],
          'enddate': endDate.toIso8601String().split('T')[0],
        }),
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        jobs = data.map((e) => Job.fromJson(e)).toList();
      } else {
        error = 'Error ${res.statusCode}';
      }
    } catch (e) {
      error = e.toString();
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
    setState(() {
      startDate = newStart;
      endDate = newEnd;
      page = 1;
    });
    fetchJobs();
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
                Expanded(
                  child: ListView(
                    children: pagedGroups.map((entry) {
                      final pnr = entry.key;
                      final list = entry.value;
                      final expanded = expandedPNRs[pnr] ?? false;
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Text(pnr),
                          initiallyExpanded: expanded,
                          onExpansionChanged: (e) {
                            setState(() {
                              expandedPNRs[pnr] = e;
                              if (e) detailJobs = list;
                            });
                          },
                          children: list.map((job) {
                            return ListTile(
                              title: Text(
                                '${job.pickupDate} → ${job.dropoffDate}',
                              ),
                              subtitle: Text(
                                'Confirmed: ${job.isConfirmed}, New: ${job.isNew}',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (!(showConfirmedOnly || showNewOnly || showPendingOnly))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: page > 1
                            ? () => setState(() => page--)
                            : null,
                        child: const Text('Prev'),
                      ),
                      Text('$page / $totalPages'),
                      TextButton(
                        onPressed: page < totalPages
                            ? () => setState(() => page++)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
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
