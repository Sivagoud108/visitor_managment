import 'package:flutter/material.dart';

import '../models/visitor.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final VisitorStatus status;

  MaterialColor get _color {
    switch (status) {
      case VisitorStatus.registered:
        return Colors.blue;
      case VisitorStatus.checkedIn:
        return Colors.green;
      case VisitorStatus.checkedOut:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      backgroundColor: _color.shade50,
      side: BorderSide(color: _color.shade200),
      labelStyle: TextStyle(
        color: _color.shade800,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
