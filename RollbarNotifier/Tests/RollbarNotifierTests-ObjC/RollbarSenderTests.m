//
//  RollbarSenderTests.m
//  
//
//  Created by Andrey Kornich on 2022-06-14.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+RollbarNotifierTest.h"

#import "../../Sources/RollbarNotifier/RollbarSender.h"
#import "../../Sources/RollbarNotifier/RollbarPayloadFactory.h"

@import RollbarNotifier;

@interface RollbarSenderTests : XCTestCase

@end

@implementation RollbarSenderTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma mark - tests of live-sending of different payload types

- (void)testSendingCrashReport {

    RollbarPayload *payload = [self getPayload_CrashReport];
    [self sendAndAssertPayload:payload];
}

- (void)testSendingMessage {
    
    RollbarPayload *payload = [self getPayload_Message];
    [self sendAndAssertPayload:payload];
}

- (void)testSendingError {

    RollbarPayload *payload = [self getPayload_Error];
    [self sendAndAssertPayload:payload];
}

- (void)testSendingException {
    
    RollbarPayload *payload = [self getPayload_Exception];
    [self sendAndAssertPayload:payload];
}

- (RollbarPayloadPostReply *)sendData:(NSData *)payloadData using:(RollbarSender *)sender {
    __block RollbarPayloadPostReply *reply = nil;
    __block BOOL finished = NO;
    [sender sendPayload:payloadData usingConfig:[self getConfig_Live_Default] completion:^(RollbarPayloadPostReply * _Nullable response) {
        reply = response;
        finished = YES;
    }];
    while (!finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    return reply;
}

- (void)sendAndAssertPayload:(RollbarPayload *)payload {
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];

    RollbarPayloadPostReply * reply = [self sendData:payloadData using:sender];
    XCTAssertNotNil(reply);
}

#pragma mark - performance tests

- (void)testPerformanceRollbarSenderInstantiation{

    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        RollbarSender *sender = [RollbarSender new];
    }];
}

- (void)testPerformanceSendingCrashReport {
    
    RollbarPayload *payload = [self getPayload_CrashReport];
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self sendData:payloadData using:sender];
    }];
}

- (void)testPerformanceSendingMessage {
    
    RollbarPayload *payload = [self getPayload_Message];
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self sendData:payloadData using:sender];
    }];
}

- (void)testPerformanceSendingError {
    
    RollbarPayload *payload = [self getPayload_Error];
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self sendData:payloadData using:sender];
    }];
}

- (void)testPerformanceSendingException {
    
    RollbarPayload *payload = [self getPayload_Exception];
    //[self measureSendingPerformanceOfPayload:payload];
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self sendData:payloadData using:sender];
    }];
}

- (void)measureSendingPerformanceOfPayload:(RollbarPayload *)payload {
    
    NSData *payloadData = [payload serializeToJSONData];
    RollbarSender *sender = [RollbarSender new];
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self sendData:payloadData using:sender];
    }];
}
@end
