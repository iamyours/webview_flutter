// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FlutterWebView.h"
#import "FLTWKNavigationDelegate.h"
#import "JavaScriptChannelHandler.h"
#import "FlutterInstance.h"
#define UIColorFromARGB(argbValue) [UIColor colorWithRed:((float)((argbValue & 0xFF0000) >> 16))/255.0 green:((float)((argbValue & 0xFF00) >> 8))/255.0 blue:((float)(argbValue & 0xFF))/255.0 alpha:((float)((argbValue & 0xFF000000) >> 24))/255.0];
@implementation FLTWebViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  FLTWebViewController* webviewController = [[FLTWebViewController alloc] initWithFrame:frame
                                                                         viewIdentifier:viewId
                                                                              arguments:args
                                                                        binaryMessenger:_messenger];
  return webviewController;
}

@end

@implementation FLTWebViewController {
  WKWebView* _webView;
  int64_t _viewId;
  FlutterMethodChannel* _channel;
  NSString* _currentUrl;
  // The set of registered JavaScript channel names.
  NSMutableSet* _javaScriptChannelNames;
  FLTWKNavigationDelegate* _navigationDelegate;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if (self = [super init]) {
    _viewId = viewId;

    NSString* channelName = [NSString stringWithFormat:@"plugins.flutter.io/webview_%lld", viewId];
     
    _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
     
    _javaScriptChannelNames = [[NSMutableSet alloc] init];

    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    if ([args[@"javascriptChannelNames"] isKindOfClass:[NSArray class]]) {
      NSArray* javaScriptChannelNames = args[@"javascriptChannelNames"];
      [_javaScriptChannelNames addObjectsFromArray:javaScriptChannelNames];
      [self registerJavaScriptChannels:_javaScriptChannelNames controller:userContentController];
    }

    NSDictionary<NSString*, id>* settings = args[@"settings"];

    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    [self updateAutoMediaPlaybackPolicy:args[@"autoMediaPlaybackPolicy"]
                        inConfiguration:configuration];

    _webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
      _webView.backgroundColor = UIColor.redColor;
    _navigationDelegate = [[FLTWKNavigationDelegate alloc] initWithChannel:_channel];
    _webView.navigationDelegate = _navigationDelegate;
      [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    __weak __typeof__(self) weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [weakSelf onMethodCall:call result:result];
    }];
      NSMutableDictionary *channels = [FlutterInstance get].channels;
      NSString *key =[NSString stringWithFormat:@"%lld",_viewId];
      [channels setObject:_channel forKey:key];
    [self applySettings:settings];
    // TODO(amirh): return an error if apply settings failed once it's possible to do so.
    // https://github.com/flutter/flutter/issues/36228
    NSString* initialUrl = args[@"initialUrl"];
      NSNumber* bgColor = args[@"backgroundColor"];
      if([bgColor isKindOfClass:[NSNumber class]]){
          int color = bgColor.intValue;
          [_webView setOpaque:false];
          _webView.backgroundColor = UIColor.clearColor;
          _webView.scrollView.backgroundColor = UIColorFromARGB(color);
      }
    if ([initialUrl isKindOfClass:[NSString class]]) {
      [self loadUrl:initialUrl];
    }
  }
  return self;
}
#pragma mark - 监听加载进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == _webView) {
            int progress =(int)(_webView.estimatedProgress*100);
            [_channel invokeMethod:@"onProgressChanged" arguments: [NSNumber numberWithInt:progress]];
        }
    }
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [FlutterInstance removeChannel:_viewId];
    NSLog(@"delloc...");
}

- (UIView*)view {
  return _webView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"updateSettings"]) {
    [self onUpdateSettings:call result:result];
  } else if ([[call method] isEqualToString:@"loadUrl"]) {
    [self onLoadUrl:call result:result];
  } else if ([[call method] isEqualToString:@"canGoBack"]) {
    [self onCanGoBack:call result:result];
  } else if ([[call method] isEqualToString:@"canGoForward"]) {
    [self onCanGoForward:call result:result];
  } else if ([[call method] isEqualToString:@"goBack"]) {
    [self onGoBack:call result:result];
  } else if ([[call method] isEqualToString:@"goForward"]) {
    [self onGoForward:call result:result];
  } else if ([[call method] isEqualToString:@"reload"]) {
    [self onReload:call result:result];
  } else if ([[call method] isEqualToString:@"currentUrl"]) {
    [self onCurrentUrl:call result:result];
  } else if ([[call method] isEqualToString:@"evaluateJavascript"]) {
    [self onEvaluateJavaScript:call result:result];
  } else if ([[call method] isEqualToString:@"addJavascriptChannels"]) {
    [self onAddJavaScriptChannels:call result:result];
  } else if ([[call method] isEqualToString:@"removeJavascriptChannels"]) {
    [self onRemoveJavaScriptChannels:call result:result];
  } else if ([[call method] isEqualToString:@"clearCache"]) {
    [self clearCache:result];
  } else if ([[call method] isEqualToString:@"getTitle"]) {
    [self onGetTitle:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)onUpdateSettings:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* error = [self applySettings:[call arguments]];
  if (error == nil) {
    result(nil);
    return;
  }
  result([FlutterError errorWithCode:@"updateSettings_failed" message:error details:nil]);
}

- (void)onLoadUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
  if (![self loadRequest:[call arguments]]) {
    result([FlutterError
        errorWithCode:@"loadUrl_failed"
              message:@"Failed parsing the URL"
              details:[NSString stringWithFormat:@"Request was: '%@'", [call arguments]]]);
  } else {
    result(nil);
  }
}

- (void)onCanGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
  BOOL canGoBack = [_webView canGoBack];
  result([NSNumber numberWithBool:canGoBack]);
}

- (void)onCanGoForward:(FlutterMethodCall*)call result:(FlutterResult)result {
  BOOL canGoForward = [_webView canGoForward];
  result([NSNumber numberWithBool:canGoForward]);
}

- (void)onGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
  [_webView goBack];
  result(nil);
}

- (void)onGoForward:(FlutterMethodCall*)call result:(FlutterResult)result {
  [_webView goForward];
  result(nil);
}

- (void)onReload:(FlutterMethodCall*)call result:(FlutterResult)result {
  [_webView reload];
  result(nil);
}

- (void)onCurrentUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
  _currentUrl = [[_webView URL] absoluteString];
  result(_currentUrl);
}

- (void)onEvaluateJavaScript:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* jsString = [call arguments];
  if (!jsString) {
    result([FlutterError errorWithCode:@"evaluateJavaScript_failed"
                               message:@"JavaScript String cannot be null"
                               details:nil]);
    return;
  }
  [_webView evaluateJavaScript:jsString
             completionHandler:^(_Nullable id evaluateResult, NSError* _Nullable error) {
               if (error) {
                 result([FlutterError
                     errorWithCode:@"evaluateJavaScript_failed"
                           message:@"Failed evaluating JavaScript"
                           details:[NSString stringWithFormat:@"JavaScript string was: '%@'\n%@",
                                                              jsString, error]]);
               } else {
                 result([NSString stringWithFormat:@"%@", evaluateResult]);
               }
             }];
}

- (void)onAddJavaScriptChannels:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSArray* channelNames = [call arguments];
  NSSet* channelNamesSet = [[NSSet alloc] initWithArray:channelNames];
  [_javaScriptChannelNames addObjectsFromArray:channelNames];
  [self registerJavaScriptChannels:channelNamesSet
                        controller:_webView.configuration.userContentController];
  result(nil);
}

- (void)onRemoveJavaScriptChannels:(FlutterMethodCall*)call result:(FlutterResult)result {
  // WkWebView does not support removing a single user script, so instead we remove all
  // user scripts, all message handlers. And re-register channels that shouldn't be removed.
  [_webView.configuration.userContentController removeAllUserScripts];
  for (NSString* channelName in _javaScriptChannelNames) {
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:channelName];
  }

  NSArray* channelNamesToRemove = [call arguments];
  for (NSString* channelName in channelNamesToRemove) {
    [_javaScriptChannelNames removeObject:channelName];
  }

  [self registerJavaScriptChannels:_javaScriptChannelNames
                        controller:_webView.configuration.userContentController];
  result(nil);
}

- (void)clearCache:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    NSSet* cacheDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
    NSDate* dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [dataStore removeDataOfTypes:cacheDataTypes
                   modifiedSince:dateFrom
               completionHandler:^{
                 result(nil);
               }];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cache is not supported for Flutter WebViews prior to iOS 9.");
  }
}

- (void)onGetTitle:(FlutterResult)result {
  NSString* title = _webView.title;
  result(title);
}

// Returns nil when successful, or an error message when one or more keys are unknown.
- (NSString*)applySettings:(NSDictionary<NSString*, id>*)settings {
  NSMutableArray<NSString*>* unknownKeys = [[NSMutableArray alloc] init];
  for (NSString* key in settings) {
    if ([key isEqualToString:@"jsMode"]) {
      NSNumber* mode = settings[key];
      [self updateJsMode:mode];
    } else if ([key isEqualToString:@"hasNavigationDelegate"]) {
      NSNumber* hasDartNavigationDelegate = settings[key];
      _navigationDelegate.hasDartNavigationDelegate = [hasDartNavigationDelegate boolValue];
    } else if ([key isEqualToString:@"debuggingEnabled"]) {
      // no-op debugging is always enabled on iOS.
    } else if ([key isEqualToString:@"userAgent"]) {
      NSString* userAgent = settings[key];
      [self updateUserAgent:[userAgent isEqual:[NSNull null]] ? nil : userAgent];
    } else {
      [unknownKeys addObject:key];
    }
  }
  if ([unknownKeys count] == 0) {
    return nil;
  }
  return [NSString stringWithFormat:@"webview_flutter: unknown setting keys: {%@}",
                                    [unknownKeys componentsJoinedByString:@", "]];
}

- (void)updateJsMode:(NSNumber*)mode {
  WKPreferences* preferences = [[_webView configuration] preferences];
  switch ([mode integerValue]) {
    case 0:  // disabled
      [preferences setJavaScriptEnabled:NO];
      break;
    case 1:  // unrestricted
      [preferences setJavaScriptEnabled:YES];
      break;
    default:
      NSLog(@"webview_flutter: unknown JavaScript mode: %@", mode);
  }
}

- (void)updateAutoMediaPlaybackPolicy:(NSNumber*)policy
                      inConfiguration:(WKWebViewConfiguration*)configuration {
  switch ([policy integerValue]) {
    case 0:  // require_user_action_for_all_media_types
      if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
      } else {
        configuration.mediaPlaybackRequiresUserAction = true;
      }
      break;
    case 1:  // always_allow
      if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
      } else {
        configuration.mediaPlaybackRequiresUserAction = false;
      }
      break;
    default:
      NSLog(@"webview_flutter: unknown auto media playback policy: %@", policy);
  }
}

- (bool)loadRequest:(NSDictionary<NSString*, id>*)request {
  if (!request) {
    return false;
  }

  NSString* url = request[@"url"];
  if ([url isKindOfClass:[NSString class]]) {
    id headers = request[@"headers"];
    if ([headers isKindOfClass:[NSDictionary class]]) {
      return [self loadUrl:url withHeaders:headers];
    } else {
      return [self loadUrl:url];
    }
  }

  return false;
}

- (bool)loadUrl:(NSString*)url {
  return [self loadUrl:url withHeaders:[NSMutableDictionary dictionary]];
}

- (bool)loadUrl:(NSString*)url withHeaders:(NSDictionary<NSString*, NSString*>*)headers {
  NSURL* nsUrl = [NSURL URLWithString:url];
  if (!nsUrl) {
    return false;
  }
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
    NSString *vid = [NSString stringWithFormat:@"%lld",_viewId];
    [headers setValue:vid forKey:@"flutter_view_id"];
  [request setAllHTTPHeaderFields:headers];
    [_webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        NSString *fixAgent = [NSString stringWithFormat:@"%@#%d",result,_viewId];
        [_webView setCustomUserAgent:fixAgent];
    }];
//    [_webView setCustomUserAgent:@"test"];
  [_webView loadRequest:request];
  return true;
}

- (void)registerJavaScriptChannels:(NSSet*)channelNames
                        controller:(WKUserContentController*)userContentController {
  for (NSString* channelName in channelNames) {
    FLTJavaScriptChannel* channel =
        [[FLTJavaScriptChannel alloc] initWithMethodChannel:_channel
                                      javaScriptChannelName:channelName];
    [userContentController addScriptMessageHandler:channel name:channelName];
    NSString* wrapperSource = [NSString
        stringWithFormat:@"window.%@ = webkit.messageHandlers.%@;", channelName, channelName];
    WKUserScript* wrapperScript =
        [[WKUserScript alloc] initWithSource:wrapperSource
                               injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                            forMainFrameOnly:NO];
    [userContentController addUserScript:wrapperScript];
  }
}

- (void)updateUserAgent:(NSString*)userAgent {
  if (@available(iOS 9.0, *)) {
    [_webView setCustomUserAgent:userAgent];
  } else {
    NSLog(@"Updating UserAgent is not supported for Flutter WebViews prior to iOS 9.");
  }
}

@end
