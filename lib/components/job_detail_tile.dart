import 'package:flutter/material.dart';
import '../screens/joblist_screen.dart'; // ต้อง import Job model

class JobDetailTile extends StatelessWidget {
  final Job job;
  final String Function(String) formatDate;

  const JobDetailTile({
    required this.job,
    required this.formatDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PNR: ${job.pnr}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          _buildRow('Pickup:', '${job.pickup} (${formatDate(job.pickupDate)})'),
          SizedBox(height: 4),
          _buildRow(
              'Dropoff:', '${job.dropoff} (${formatDate(job.dropoffDate)})'),
          SizedBox(height: 4),
          _buildRow('Pax:', '${job.pax}'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 4),
        Expanded(child: Text(value, softWrap: true)),
      ],
    );
  }
}
