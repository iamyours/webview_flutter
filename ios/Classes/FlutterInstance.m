//
//  FlutterInstance.m
//  Pods-Runner
//
//  Created by yanxx on 2019/11/19.
//

#import "FlutterInstance.h"

@implementation FlutterInstance

static FlutterInstance *instance = nil;
+(FlutterInstance *)get
{
    @synchronized(self)
    {
        if(instance==nil)
        {
            instance= [FlutterInstance new];
            instance.channels = [NSMutableDictionary dictionary];
        }
    }
    return instance;
}
+(FlutterMethodChannel*)channelWithAgent:(NSString*)agent{
    NSRange range = [agent rangeOfString:@"#" options:NSBackwardsSearch];
    NSLog(@"range:%d,%d",range.length,range.location);
    NSString *key = [agent substringFromIndex:range.location+1];
    NSLog(@"key:%@",key);
    NSDictionary *channels = [self get].channels;
    FlutterMethodChannel *channel = (FlutterMethodChannel*)[channels objectForKey:key];
    return channel;
}
+(void)removeChannel:(int64_t)viewId{
    NSMutableDictionary *channels = [self get].channels;
    NSString *key = [NSString stringWithFormat:@"%lld",viewId];
    [channels removeObjectForKey:key];
}
@end
