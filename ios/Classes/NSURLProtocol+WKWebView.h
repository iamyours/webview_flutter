//
//  NSURLProtocol+WKWebView.h
//  Pods-Runner
//
//  Created by yanxx on 2019/11/18.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (WKWebVIew)

+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;


@end
