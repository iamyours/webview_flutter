// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../platform_interface.dart';

/// A [WebViewPlatformController] that uses a method channel to control the webview.
class MethodChannelWebViewPlatform implements WebViewPlatformController {
  MethodChannelWebViewPlatform(int id, this._platformCallbacksHandler)
      : assert(_platformCallbacksHandler != null),
        _channel = MethodChannel('plugins.flutter.io/webview_$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final WebViewPlatformCallbacksHandler _platformCallbacksHandler;

  final MethodChannel _channel;

  static const MethodChannel _cookieManagerChannel = MethodChannel('plugins.flutter.io/cookie_manager');

  Future<dynamic> _onMethodCall(MethodCall call) async {
    print("method:${call.method}");
    switch (call.method) {
      case 'javascriptChannelMessage':
        final String channel = call.arguments['channel'];
        final String message = call.arguments['message'];
        _platformCallbacksHandler.onJavaScriptChannelMessage(channel, message);
        return true;
      case 'navigationRequest':
        return _platformCallbacksHandler.onNavigationRequest(
          url: call.arguments['url'],
          isForMainFrame: call.arguments['isForMainFrame'],
        );
      case 'onPageFinished':
        _platformCallbacksHandler.onPageFinished(call.arguments['url']);
        return null;
      case 'onProgressChanged':
        int progress = call.arguments;
        _platformCallbacksHandler.onProgressChanged(progress);
        return null;
      case 'shouldInterceptRequest':
        String url = call.arguments;
        var response = await _platformCallbacksHandler.shouldInterceptRequest(url);
        if(response!=null){
          return {"data":response.data,"mineType":response.mineType,"encoding":response.encoding};
        }
        return null;
    }
    throw MissingPluginException('${call.method} was invoked but has no handler');
  }

  @override
  Future<void> loadUrl(
    String url,
    Map<String, String> headers,
  ) async {
    assert(url != null);
    return _channel.invokeMethod<void>('loadUrl', <String, dynamic>{
      'url': url,
      'headers': headers,
    });
  }

  @override
  Future<String> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  @override
  Future<bool> canGoBack() => _channel.invokeMethod<bool>("canGoBack");

  @override
  Future<bool> canGoForward() => _channel.invokeMethod<bool>("canGoForward");

  @override
  Future<void> goBack() => _channel.invokeMethod<void>("goBack");

  @override
  Future<void> goForward() => _channel.invokeMethod<void>("goForward");

  @override
  Future<void> reload() => _channel.invokeMethod<void>("reload");

  @override
  Future<void> clearCache() => _channel.invokeMethod<void>("clearCache");

  @override
  Future<void> updateSettings(WebSettings settings) {
    final Map<String, dynamic> updatesMap = _webSettingsToMap(settings);
    if (updatesMap.isEmpty) {
      return null;
    }
    return _channel.invokeMethod<void>('updateSettings', updatesMap);
  }

  @override
  Future<String> evaluateJavascript(String javascriptString) {
    return _channel.invokeMethod<String>('evaluateJavascript', javascriptString);
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>('addJavascriptChannels', javascriptChannelNames.toList());
  }

  @override
  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>('removeJavascriptChannels', javascriptChannelNames.toList());
  }

  @override
  Future<String> getTitle() => _channel.invokeMethod<String>("getTitle");

  /// Method channel implementation for [WebViewPlatform.clearCookies].
  static Future<bool> clearCookies() {
    return _cookieManagerChannel.invokeMethod<bool>('clearCookies').then<bool>((dynamic result) => result);
  }

  static Map<String, dynamic> _webSettingsToMap(WebSettings settings) {
    final Map<String, dynamic> map = <String, dynamic>{};
    void _addIfNonNull(String key, dynamic value) {
      if (value == null) {
        return;
      }
      map[key] = value;
    }

    void _addSettingIfPresent<T>(String key, WebSetting<T> setting) {
      if (!setting.isPresent) {
        return;
      }
      map[key] = setting.value;
    }

    _addIfNonNull('jsMode', settings.javascriptMode?.index);
    _addIfNonNull('hasNavigationDelegate', settings.hasNavigationDelegate);
    _addIfNonNull('debuggingEnabled', settings.debuggingEnabled);
    _addSettingIfPresent('userAgent', settings.userAgent);
    return map;
  }

  /// Converts a [CreationParams] object to a map as expected by `platform_views` channel.
  ///
  /// This is used for the `creationParams` argument of the platform views created by
  /// [AndroidWebViewBuilder] and [CupertinoWebViewBuilder].
  static Map<String, dynamic> creationParamsToMap(CreationParams creationParams) {
    return <String, dynamic>{
      'initialUrl': creationParams.initialUrl,
      'settings': _webSettingsToMap(creationParams.webSettings),
      'javascriptChannelNames': creationParams.javascriptChannelNames.toList(),
      'userAgent': creationParams.userAgent,
      'autoMediaPlaybackPolicy': creationParams.autoMediaPlaybackPolicy.index,
    };
  }
}
