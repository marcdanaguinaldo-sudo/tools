import 'package:flutter/material.dart';

/// Non-intrusive Help & Tutorial overlay for first-time users.
/// Guides camera alignment (distance, surface, lighting) and 3D gesture controls.
class HelpTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const HelpTutorialOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Color(0xFFF59E0B), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "AR Scanning & 3D Guide",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onDismiss,
                  tooltip: 'Close Help',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Sections
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSectionHeader("1. Camera Alignment (Optimal AR Scan)"),
                  _buildTipCard(
                    icon: Icons.straighten,
                    title: "Optimal Distance: 30–50 cm",
                    body:
                        "Keep the tool fully framed in the reticle. Avoid extreme close-ups or angles.",
                  ),
                  _buildTipCard(
                    icon: Icons.wb_sunny_outlined,
                    title: "Good Lighting & Contrast",
                    body:
                        "Place knives and bowls on a flat matte cutting board or countertop with clear edges.",
                  ),
                  _buildTipCard(
                    icon: Icons.pan_tool_outlined,
                    title: "Hold Still for 3 Frames",
                    body:
                        "Our Detection Gate waits for 3 consecutive matching frames to prevent false alerts.",
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader("2. Interactive 3D Viewer Controls"),
                  _buildTipCard(
                    icon: Icons.swipe,
                    title: "Drag Left / Right to Orbit",
                    body:
                        "Rotate the 3D cutting board or bowl 360° to view blade angle and grip clearances.",
                  ),
                  _buildTipCard(
                    icon: Icons.play_circle_outline,
                    title: "Step-by-Step Playback",
                    body:
                        "Tap Play/Pause or scrub Next/Prev to study Bolster Grip, Claw Defense, and Slicing.",
                  ),
                  _buildTipCard(
                    icon: Icons.security,
                    title: "Ergonomic Safety Warnings",
                    body:
                        "Look for highlighted yellow bolster pinch points and red hazard zones.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onDismiss,
              child: const Text(
                "Got it, Start Scanning",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTipCard(
      {required IconData icon, required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
