import 'package:flutter/material.dart';
import '../theme.dart';

class MBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<MBottomNavItem> items;
  const MBottomNav({super.key, required this.selectedIndex, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == selectedIndex;
            final item = items[i];
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: active ? ptitRedSoft : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            size: 16,
                            color: active ? ptitRed : textMuted,
                          ),
                        ),
                        if (item.badge != null && item.badge! > 0)
                          Positioned(
                            right: -4,
                            top: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: ptitRed,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                item.badge! > 9 ? '9+' : '${item.badge}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 3),
                      Text(item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: active ? ptitRed : textMuted,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class MBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  /// Optional badge count, vd notification unread count.
  final int? badge;
  const MBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}
