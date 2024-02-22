import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'config_messaging.dart';

class SubscriptionToNews extends StatefulWidget {
  final String username;
  final String tenantId;
  const SubscriptionToNews(
      {super.key, required this.username, required this.tenantId});

  @override
  SubscriptionToNewsState createState() => SubscriptionToNewsState();
}

class SubscriptionToNewsState extends State<SubscriptionToNews> {
  late String _token;
  bool isSwitched = false;
  bool isTestSwitched = false;

  Future<void> sendUserToken() async {
    final url = Uri.parse('http://10.0.2.2:8080/userToken');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'username': widget.username,
      'deviceToken': {
        'id': _token,
        'platform': Platform.isAndroid ? 2 : 1,
        'TenantNotificationConfig': {
          'tenantId': widget.tenantId,
          'category': ['news']
        }
      }
    });
    final response = await http.put(url, headers: headers, body: body);
    if (response.statusCode == 204) {
      debugPrint('Status Code: ${response.statusCode}');
      throw Exception('Failed to send userToken');
    } else {
      throw Exception('Failed to send userToken');
    }
  }

  Future<void> removeUserToken() async {
    final url = Uri.parse('http://10.0.2.2:8080/userToken');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'username': widget.username,
      'deviceToken': {
        'id': _token,
        'platform': Platform.isAndroid ? 2 : 1,
        'TenantNotificationConfig': {
          'tenantId': widget.tenantId,
          'category': [""]
        }
      }
    });
    final response = await http.put(url, headers: headers, body: body);
    if (response.statusCode == 204) {
      debugPrint('Status Code: ${response.statusCode}');
      throw Exception('Failed to send userToken');
    } else {
      throw Exception('Failed to send userToken');
    }
  }

  void getUserToken() async {
    final headers = {'X-firebaseToken': _token};
    try {
      String username = widget.username;
      String tenantId = widget.tenantId;
      String url = 'http://10.0.2.2:8080/userToken/$username/tenant/$tenantId';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> userToken = json.decode(response.body);
        List<dynamic> categoryList =
            userToken['deviceToken']['tenantNotificationConfig']['category'];
        bool isSubscribed = categoryList.contains('news');
        setState(() {
          isSwitched = isSubscribed;
        });
      } else {
        setState(() {
          isSwitched = false;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _token = token!;
        getUserToken();
      });
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      setState(() {
        _token = token;
      });
      sendUserToken();
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification!.android;

        if (notification != null && android != null) {
          flNotPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                  android: AndroidNotificationDetails(chanel.id, chanel.name,
                      channelDescription: chanel.description,
                      importance: Importance.high,
                      color: Colors.blue,
                      playSound: true,
                      icon: '@mipmap/ic_launcher')));
        }
      } on Exception catch (_) {}
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification!.android;

      if (notification != null && android != null) {
        showAboutDialog(
            context: context,
            applicationName: notification.title,
            applicationIcon: const Icon(Icons.notification_add),
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('${notification.body}')],
                ),
              )
            ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subscribe to news',
              style: TextStyle(fontSize: 16),
            ),
            Switch(
              value: isSwitched,
              onChanged: (value) {
                setState(() {
                  isSwitched = value;
                  if (isSwitched) {
                    sendUserToken();
                  } else {
                    removeUserToken();
                  }
                });
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isSwitched
              ? 'You have subscribed to the news'
              : 'You are not subscribed to the news ',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
