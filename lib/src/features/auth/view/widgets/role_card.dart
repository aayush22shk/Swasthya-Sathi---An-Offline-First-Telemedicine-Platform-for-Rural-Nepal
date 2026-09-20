import 'package:flutter/material.dart';
import '../../models/user_role.dart';

class RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedBorderColor = Color(0xFF00A389);
    const selectedAccentColor = Color(0xFF00A389);
    const selectedBgColor = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: selectedBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? selectedBorderColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: selectedBorderColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRoleAvatar(role, isSelected),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'I am a:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role.displayName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? selectedAccentColor
                                  : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? selectedAccentColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? selectedAccentColor
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Text(
                    role.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...role.bulletPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 5,
                              color: selectedAccentColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleAvatar(UserRole role, bool isSelected) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (role) {
      case UserRole.patient:
        icon = Icons.personal_injury_rounded;
        iconColor = const Color(0xFF00A389);
        bgColor = const Color(0xFFE6F7F4);
        break;
      case UserRole.doctor:
        icon = Icons.medical_services_rounded;
        iconColor = const Color(0xFF0072FF);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case UserRole.healthSpecialist:
        icon = Icons.healing_rounded;
        iconColor = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? iconColor.withValues(alpha: 0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 30,
          color: iconColor,
        ),
      ),
    );
  }
}
