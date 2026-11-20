import 'package:permission_handler/permission_handler.dart';

enum MicPermissionResult { granted, denied, permanentlyDenied }

class MicPermissionService {
  const MicPermissionService();

  Future<MicPermissionResult> requestMicrophone() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return MicPermissionResult.granted;
    if (status.isPermanentlyDenied) return MicPermissionResult.permanentlyDenied;
    return MicPermissionResult.denied;
  }
}
