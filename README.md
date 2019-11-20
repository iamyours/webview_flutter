# WebView for flutter

基于flutter官方WebView开发，新增`backgroundColor`属性,`onProgressChanged`,`shouldInterceptRequest`方法。
使用方法：
引入库
```
dependencies:
  iwebview_flutter: ^0.1.1
```

添加拦截监听
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
      backgroundColor: Colors.red,
      shouldInterceptRequest: (String url) async {//替换google logo
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


