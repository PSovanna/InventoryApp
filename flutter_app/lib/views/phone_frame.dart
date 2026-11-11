import 'package:flutter/material.dart';

/// Keeps every route, dialog and snackbar inside the same phone viewport.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFE8EDF2),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 410,
            height: 864,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF252A32),
              borderRadius: BorderRadius.circular(52),
              border: Border.all(color: const Color(0xFF626B77), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(390, 844),
                      padding: const EdgeInsets.only(top: 30, bottom: 22),
                      viewPadding: const EdgeInsets.only(top: 30, bottom: 22),
                    ),
                    child: child,
                  ),
                  Positioned(
                    top: 0,
                    left: 120,
                    right: 120,
                    child: IgnorePointer(
                      child: Container(
                        height: 25,
                        decoration: const BoxDecoration(
                          color: Color(0xFF252A32),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 135,
                    right: 135,
                    child: IgnorePointer(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252A32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
