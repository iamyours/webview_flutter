# WebView for flutter

Base on [webview_flutter](https://pub.dev/packages/webview_flutter), add some new features.
- backgroundColor
- onProgressChanged
- shouldInterceptRequest: intercept request and load resource from local.
- onScroll: listen webview scroll.

### how to use
```
dependencies:
  iwebview_flutter: ^latest version
```

``` dart
WebView(
      initialUrl: "https://www.google.com",
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: true,
      onProgressChanged: (int p){//0-100
        setState(() {
          progress = p/100.0;
        });
      },
      onScroll(int x,int y){

      },
      backgroundColor: Colors.red,
      shouldInterceptRequest: (String url) async {//replace google logo
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
```


