import 'package:flutter/material.dart';
import 'package:counter_app/note_test/note_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotiPage extends StatelessWidget {
  const NotiPage({super.key});

  Future<void> _requestNotificationPermission() async {
    // 请求通知权限
    final status = await Permission.notification.request();
    print('通知权限状态: $status');

    if (status.isGranted) {
      NoteService.instance.showNotification(title: '测试', body: '测试成功');
    } else {
      print('通知权限被拒绝');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _requestNotificationPermission,
        child: Text('测试通知'),
      ),
    );
  }
}
