import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoadingPage extends StatelessWidget {
  final String loadingMessage;

  LoadingPage({required this.loadingMessage});

  Future<bool> checkVersion () async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    List<String> versionParts = packageInfo.version.split('.');

    int minorVersion = int.parse(versionParts[1]);
    int patchVersion = int.parse(versionParts[2]);

    if (minorVersion >= 19 || patchVersion >= 1) {
      return true;
    } else {
      return false;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F6B)),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Center(
              child:  Text(
                loadingMessage,
                style: const TextStyle(
                  color: Color(0xFF005F6B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}