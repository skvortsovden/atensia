import 'package:flutter/material.dart';

const kCheckboxRowRadius = BorderRadius.all(Radius.circular(14));

class CheckboxRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const CheckboxRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: checked,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: kCheckboxRowRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: checked ? const Color(0xFFE8E8E8) : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: kCheckboxRowRadius,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: checked ? Colors.black : Colors.transparent,
                    border: Border.all(
                      color: checked ? Colors.transparent : Colors.black,
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
