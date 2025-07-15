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
    super.key,
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
          child: ExpansionTile(
            key: Key('$pnr'),
            title: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatDate(jobs.first.pnrDate),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            initiallyExpanded: expanded,
            onExpansionChanged: onExpansionChanged,
            children: jobs
                .map((job) =>
                    JobDetailTile(job: job, formatDate: formatDate))
                .toList(),
          ),
        ),
      ),
    );
  }
}
