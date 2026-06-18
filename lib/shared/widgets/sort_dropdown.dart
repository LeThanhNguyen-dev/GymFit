import 'package:flutter/material.dart';

class SortDropdown extends StatelessWidget {
  const SortDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<SortOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Sort',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(value: o.key, child: Text(o.label)),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class SortOption {
  const SortOption(this.key, this.label);
  final String key;
  final String label;
}
