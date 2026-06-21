import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: leading != null ? 12 : 0,
            vertical: 10,
          ),
          alignment: leading != null ? null : Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.idleBall.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.idleBall : AppColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: leading != null
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              if (leading != null)
                Expanded(child: _buildText())
              else
                _buildText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
