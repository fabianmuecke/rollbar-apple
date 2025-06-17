//
//  RollbarSender.h
//  
//
//  Created by Andrey Kornich on 2022-06-10.
//

#import <Foundation/Foundation.h>

@class RollbarConfig;
@class RollbarPayloadPostReply;

NS_ASSUME_NONNULL_BEGIN

@protocol RollbarCancellable <NSObject>
- (void)cancel;
@end

@interface RollbarSender : NSObject

- (id<RollbarCancellable>)sendPayload:(nonnull NSData *)payload
        usingConfig:(nonnull RollbarConfig *)config
         completion:(void (^)(RollbarPayloadPostReply * _Nullable response))completion;
@end

NS_ASSUME_NONNULL_END
