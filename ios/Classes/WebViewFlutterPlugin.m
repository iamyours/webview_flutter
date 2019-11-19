// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "WebViewFlutterPlugin.h"
#import "FLTCookieManager.h"
#import "FlutterWebView.h"
#import "FlutterNSURLProtocol.h"
#import "NSURLProtocol+WKWebView.h"
@implementation FLTWebViewFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FLTWebViewFactory* webviewFactory =
      [[FLTWebViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:webviewFactory withId:@"plugins.flutter.io/webview"];
    [NSURLProtocol registerClass:[FlutterNSURLProtocol class]];
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
  [FLTCookieManager registerWithRegistrar:registrar];
}

@end
