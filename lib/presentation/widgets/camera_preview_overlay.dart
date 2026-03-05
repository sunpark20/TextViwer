import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/facial_gesture_provider.dart';

/// 우하단 원형 카메라 미리보기 오버레이
///
/// - 탭하면 100×100 원형 미리보기 열고 닫기
/// - 감지 활성 시 녹색 테두리, 비활성 시 회색
/// - 깜빡임 카운트 배지 표시
class CameraPreviewOverlay extends StatelessWidget {
  const CameraPreviewOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FacialGestureProvider>(
      builder: (context, gesture, _) {
        if (!gesture.isInitialized) return const SizedBox.shrink();

        return Positioned(
          right: 16,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 깜빡임 카운트 배지
              if (gesture.isActive && gesture.blinkCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gesture.blinkCount}/3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // 카메라 미리보기 또는 토글 버튼
              GestureDetector(
                onTap: gesture.togglePreview,
                onLongPress: gesture.toggleDetection,
                child: gesture.showPreview
                    ? _buildPreview(gesture)
                    : _buildToggleButton(gesture),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(FacialGestureProvider gesture) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: gesture.isActive ? Colors.green : Colors.grey,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: gesture.cameraController != null &&
                gesture.cameraController!.value.isInitialized
            ? CameraPreview(gesture.cameraController!)
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white54),
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton(FacialGestureProvider gesture) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gesture.isActive
            ? Colors.green.withOpacity(0.85)
            : Colors.grey.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        gesture.isActive ? Icons.face : Icons.face_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
