import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../MainLayout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Start Date Picker
                      Text(
                        'Start: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                endDate.isAfter(
                                  startDate.add(Duration(days: 91)),
                                )
                                ? startDate.add(Duration(days: 91))
                                : endDate,
                          );
                          if (picked != null && picked != startDate) {
                            // ✅ ตรวจว่าระยะเกิน 91 วันไหม แล้วขยับ endDate ถ้าจำเป็น
                            DateTime adjustedEnd = endDate;
                            final maxRange = Duration(days: 91);
                            if (endDate.difference(picked) > maxRange) {
                              adjustedEnd = picked.add(maxRange);
                            }

                            _onDateRangeChanged(picked, adjustedEnd);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ),

                      SizedBox(width: 16),
                      // End Date Picker
                      Text(
                        'End: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(
                              start: startDate,
                              end: endDate,
                            ),
                            firstDate: DateTime.now().subtract(
                              Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );

                          if (picked != null) {
                            DateTime newStart = picked.start;
                            DateTime newEnd = picked.end;

                            final maxRange = Duration(days: 91);

                            // ถ้าระยะเกิน 91 วัน ให้ขยับ endDate ใหม่เป็น startDate + 91 วัน
                            if (newEnd.difference(newStart) > maxRange) {
                              newEnd = newStart.add(maxRange);
                            }

                            _onDateRangeChanged(newStart, newEnd);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ),
                    ],
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
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.blue.shade100,
                                width: 2,
                              ),
                            ),
                            child: ExpansionTile(
                              key: Key('$pnr-$page'), // ✅ เพิ่มตรงนี้
                              title: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatDate(list.first.pnrDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              initiallyExpanded: expanded,
                              onExpansionChanged: (e) {
                                setState(() {
                                  expandedPNRs[pnr] = e;
                                  if (e) detailJobs = list;
                                });
                              },
                              children: list.map((job) {
                                return ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PNR: ${job.pnr}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pickup: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            // <--- ให้ขยายและห่อข้อความ
                                            child: Text(
                                              '${job.pickup}  (${formatDate(job.pickupDate)})',
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dropoff: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${job.dropoff}  (${formatDate(job.dropoffDate)})',
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Pax: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('${job.pax}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
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
                            ? () => setState(() {
                                page--;
                                expandedPNRs
                                    .clear(); // ✅ พับทุก PNR เมื่อเปลี่ยนหน้า
                              })
                            : null,
                        child: const Text('Prev'),
                      ),
                      Text('$page / $totalPages'),
                      TextButton(
                        onPressed: page < totalPages
                            ? () => setState(() {
                                page++;
                                expandedPNRs
                                    .clear(); // ✅ พับทุก PNR เมื่อเปลี่ยนหน้า
                              })
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
