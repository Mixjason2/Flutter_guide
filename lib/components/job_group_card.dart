import 'package:flutter/material.dart';
import '../screens/joblist_screen.dart'; // ต้อง import Job model
import 'job_detail_tile.dart';

class JobGroupCard extends StatelessWidget {
  final String pnr;
  final List<Job> jobs;
  final bool expanded;
  final void Function(bool) onExpansionChanged;
  final String Function(String) formatDate;

  const JobGroupCard({
    required this.pnr,
    required this.jobs,
    required this.expanded,
    required this.onExpansionChanged,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.shade100, width: 2),
          ),
          child: Stack(
            children: [
              ExpansionTile(
                key: Key('$pnr'),
                title: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatDate(jobs.first.pnrDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: const Color.fromARGB(255, 7, 51, 87),
                      ),
                    ),
                  ),
                ),
                initiallyExpanded: expanded,
                onExpansionChanged: onExpansionChanged,
                trailing: SizedBox.shrink(), // <-- ตรงนี้คือเอาลูกศรออก
                children: jobs
                    .map(
                      (job) => JobDetailTile(job: job, formatDate: formatDate),
                    )
                    .toList(),
              ),

              // ปุ่ม info วางที่มุมขวาบน
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.blue.shade700),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('PNR: $pnr'),
                        content: Text(
                          'แสดงรายละเอียดเพิ่มเติมที่คุณต้องการตรงนี้ได้เลย',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('ปิด'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
