#import "RollbarSender.h"
#import "RollbarConfig.h"
#import "RollbarDestination.h"
#import "RollbarProxy.h"
#import "RollbarDeveloperOptions.h"
#import "RollbarPayloadPostReply.h"
#import "RollbarNotifierFiles.h"
#import "RollbarInternalLogging.h"

@interface NSURLSessionDataTask (RollbarCancellable) <RollbarCancellable>
@end

@implementation NSURLSessionDataTask (RollbarCancellable)
// No additional implementation needed; NSURLSessionDataTask already implements -cancel
@end

@implementation RollbarSender

- (id<RollbarCancellable>)sendPayload:(nonnull NSData *)payload
                                      usingConfig:(nonnull RollbarConfig *)config
                                       completion:(void (^)(RollbarPayloadPostReply * _Nullable response))completion
{
    if (config.developerOptions.transmit) {
        return [self transmitPayload:payload
                toDestination:config.destination
        usingDeveloperOptions:config.developerOptions
         andHttpProxySettings:config.httpProxy
        andHttpsProxySettings:config.httpsProxy
                   completion:completion];
    } else {
        completion([RollbarPayloadPostReply greenReply]);
        return nil;
    }
}

- (id<RollbarCancellable>)transmitPayload:(nonnull NSData *)payload
          toDestination:(nonnull RollbarDestination  *)destination
  usingDeveloperOptions:(nullable RollbarDeveloperOptions *)developerOptions
   andHttpProxySettings:(nullable RollbarProxy *)httpProxySettings
  andHttpsProxySettings:(nullable RollbarProxy *)httpsProxySettings
             completion:(void (^)(RollbarPayloadPostReply * _Nullable response))completion
{
    NSAssert(payload, @"The payload must be initialized!");
    NSAssert(destination, @"The destination must be initialized!");
    NSAssert(destination.endpoint, @"The destination endpoint must be initialized!");
    NSAssert(destination.accessToken, @"The destination access token must be initialized!");

    developerOptions = developerOptions ?: [RollbarDeveloperOptions new];
    httpProxySettings = httpProxySettings ?: [RollbarProxy new];
    httpsProxySettings = httpsProxySettings ?: [RollbarProxy new];

    return [self postPayload:payload
        toDestination:destination
usingDeveloperOptions:developerOptions
 andHttpProxySettings:httpProxySettings
andHttpsProxySettings:httpsProxySettings
           completion:^(NSHTTPURLResponse *response) {
        completion([RollbarPayloadPostReply replyFromHttpResponse:response]);
    }];
}

- (id<RollbarCancellable>)  postPayload:(nonnull NSData *)payload
        toDestination:(nonnull RollbarDestination  *)destination
usingDeveloperOptions:(nonnull RollbarDeveloperOptions *)developerOptions
 andHttpProxySettings:(nonnull RollbarProxy *)httpProxySettings
andHttpsProxySettings:(nonnull RollbarProxy *)httpsProxySettings
           completion:(void (^)(NSHTTPURLResponse * _Nullable response))completion
{
    NSThread *callingThread = [NSThread currentThread];
    NSURL *url = [NSURL URLWithString:destination.endpoint];
    if (url == nil) {
        RBLog(@"The destination endpoint URL is malformed: %@", destination.endpoint);
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:destination.accessToken forHTTPHeaderField:@"X-Rollbar-Access-Token"];
    [request setHTTPBody:payload];

    NSURLSession *session = [NSURLSession sharedSession];

    if (httpProxySettings.enabled || httpsProxySettings.enabled) {
        NSDictionary *connectionProxyDictionary = @{
            @"HTTPEnable"   : [NSNumber numberWithBool:httpProxySettings.enabled],
            @"HTTPProxy"    : httpProxySettings.proxyUrl,
            @"HTTPPort"     : [NSNumber numberWithUnsignedInteger:httpProxySettings.proxyPort],
            @"HTTPSEnable"  : [NSNumber numberWithBool:httpsProxySettings.enabled],
            @"HTTPSProxy"   : httpsProxySettings.proxyUrl,
            @"HTTPSPort"    : [NSNumber numberWithUnsignedInteger:httpsProxySettings.proxyPort]
        };

        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfig.connectionProxyDictionary = connectionProxyDictionary;
        session = [NSURLSession sessionWithConfiguration:sessionConfig];
    }

    RBLog(@"\tSending payload...");
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = [self checkPayloadResponse:response error:error];
        if (completion) {
            NSDictionary *args = @{ 
                @"response": httpResponse ?: [NSNull null], 
                @"completion": [completion copy] 
            };
            [self performSelector:@selector(callCompletionOnOriginalThread:)
                         onThread:callingThread
                       withObject:args
                    waitUntilDone:NO];
        }
    }];

    [dataTask resume];
    return dataTask;
}

- (void)callCompletionOnOriginalThread:(NSDictionary *)args {
    NSHTTPURLResponse *response = args[@"response"];
    void (^completion)(NSHTTPURLResponse *) = args[@"completion"];
    if ([response isKindOfClass:[NSNull class]]) {
        response = nil;
    }
    if (completion) {
        completion(response);
    }
}

- (nullable NSHTTPURLResponse *)checkPayloadResponse:(NSURLResponse *)response error:(NSError *)error {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    if (httpResponse.statusCode == 200) {
        RBLog(@"\tOK response from Rollbar");
    } else {
        RBLog(@"\tThere was a problem reporting to Rollbar:");
        RBLog(@"\t\tError: %@", [error localizedDescription]);
        RBLog(@"\t\tResponse: %d", httpResponse.statusCode);
    }

    return httpResponse;
}

@end
