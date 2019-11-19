//
//  FlutterInstance.h
//  Pods-Runner
//
//  Created by yanxx on 2019/11/19.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

@interface FlutterInstance : NSObject
@property(nonatomic,retain)NSMutableDictionary *channels;
+(FlutterInstance*)get;
+(FlutterMethodChannel*)channelWithAgent:(NSString*)agent;
+(void)removeChannel:(int64_t)viewId;
@end

NS_ASSUME_NONNULL_END
