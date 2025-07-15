import 'package:flutter/material.dart';

class DatePickerRow extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime newStart, DateTime newEnd) onDateRangeChanged;

  const DatePickerRow({
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Start: ', style: TextStyle(fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2000),
                lastDate: endDate.isAfter(startDate.add(Duration(days: 91)))
                    ? startDate.add(Duration(days: 91))
                    : endDate,
              );
              if (picked != null && picked != startDate) {
                DateTime adjustedEnd = endDate;
                final maxRange = Duration(days: 91);
                if (endDate.difference(picked) > maxRange) {
                  adjustedEnd = picked.add(maxRange);
                }
                onDateRangeChanged(picked, adjustedEnd);
              }
            },
            child: _buildDateBox(startDate),
          ),
          SizedBox(width: 16),
          Text('End: ', style: TextStyle(fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: startDate.add(Duration(days: 91)),
              );
              if (picked != null && picked != endDate) {
                onDateRangeChanged(startDate, picked);
              }
            },
            child: _buildDateBox(endDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(DateTime date) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        style: TextStyle(color: Colors.blue.shade900),
      ),
    );
  }
}
