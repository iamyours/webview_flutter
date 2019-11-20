import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

class WebPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _WebPageState();
  }
}

class _WebPageState extends State<WebPage>{
  double progress = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: <Widget>[
          LinearProgressIndicator(
            value: progress,
          ),
          Expanded(
            flex: 1,
            child: WebView(
              initialUrl: "https://www.google.com",
              javascriptMode: JavascriptMode.unrestricted,
              debuggingEnabled: true,
              onProgressChanged: (int p){
                setState(() {
                  progress = p/100.0;
                });
              },
              backgroundColor: Colors.red,
              shouldInterceptRequest: (String url) async {//replace google logo to baidu
                var googleLogo = "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_160x56dp.png";
                print("============url:$url");
                if (url == googleLogo) {
                  ByteData data = await rootBundle.load("assets/baidu.png");
                  Uint8List bytes = Uint8List.view(data.buffer);
                  return Response("image/png", null, bytes);
                }
                return null;
              },
            ),
          )
        ],
      )),
    );
  }
}