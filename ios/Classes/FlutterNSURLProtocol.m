//
//  FlutterNSURLProtocol.m
//  Pods-Runner
//
//  Created by yanxx on 2019/11/18.
//
#import <Foundation/Foundation.h>
#import "FlutterNSURLProtocol.h"
#import <UIKit/UIKit.h>
#import "FlutterInstance.h"
#import <Flutter/Flutter.h>
static NSString*const sourUrl  = @"https://m.baidu.com/static/index/plus/plus_logo.png";
static NSString*const sourIconUrl  = @"https://m.baidu.com/static/index/plus/plus_logo_web.png";
static NSString*const localUrl = @"http://mecrm.qa.medlinker.net/public/image?id=57026794&certType=workCertPicUrl&time=1484625241";
static NSString* const KFlutterNSURLProtocolKey = @"KFlutterNSURLProtocol";
@interface FlutterNSURLProtocol ()<NSURLSessionDelegate>
@property (nonnull,strong) NSURLSessionDataTask *task;

@end
@implementation FlutterNSURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
//    NSLog(@"request.URL.absoluteString = %@",[request.URL.absoluteString substringToIndex:10]);
    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame ))
    {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:KFlutterNSURLProtocolKey inRequest:request])
            return NO;
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
//    NSLog(@"client:%@",[]);
    //request截取重定向
    if ([request.URL.absoluteString isEqualToString:sourUrl])
    {
        NSURL* url1 = [NSURL URLWithString:localUrl];
        mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
    }

    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //    NSObject *t = [[self request] valueForKey:@"key1"];
    //    NSLog(@"test:%@",t);
    //给我们处理过的请求设置一个标识符, 防止无限循环,
    [NSURLProtocol setProperty:@YES forKey:KFlutterNSURLProtocolKey inRequest:mutableReqeust];
   
    //这里最好加上缓存判断，加载本地离线文件， 这个直接简单的例子。
    
//    dispatch_sync(dispatch_get_main_queue(), ^{
//
//    });
    NSString *agent = [mutableReqeust valueForHTTPHeaderField:@"User-Agent"];
    
    
    FlutterMethodChannel *channel = [FlutterInstance channelWithAgent:agent];
    NSString *url = mutableReqeust.URL.absoluteString;
    NSLog(@"===========agent:%@",agent);
    if(channel==nil){
        NSLog(@"===========channel null:%@",agent);
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.task = [session dataTaskWithRequest:self.request];
        [self.task resume];
        return;
    }
    [channel invokeMethod:@"shouldInterceptRequest" arguments:url result:^(id  _Nullable result) {
        if(result!=nil){
            
            NSDictionary *dic = (NSDictionary *)result;
            FlutterStandardTypedData *fData = (FlutterStandardTypedData *)[dic valueForKey:@"data"];
            NSString *mineType = dic[@"mineType"];
            NSString *encoding = dic[@"encoding"];
            if([encoding isEqual:[NSNull null]])encoding = nil;
            NSData *data = [fData data];
//            NSData *data =[NSData da];
            NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:mineType expectedContentLength:data.length textEncodingName:encoding];
                    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
                    [self.client URLProtocol:self didLoadData:data];
                    [self.client URLProtocolDidFinishLoading:self];
        }else{
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
                    self.task = [session dataTaskWithRequest:self.request];
                    [self.task resume];
        }
    }];
}
- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task  cancel];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.client URLProtocolDidFinishLoading:self];
}

@end
