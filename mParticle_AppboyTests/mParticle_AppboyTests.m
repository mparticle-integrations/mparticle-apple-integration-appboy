//
//  mParticle_AppboyTests.m
//  mParticle_AppboyTests
//
//  Created by Brandon Stalnaker on 9/20/18.
//  Copyright © 2018 mParticle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPKitAppboy.h"
#if TARGET_OS_IOS == 1
#import <Appboy_iOS_SDK/Appboy-iOS-SDK-umbrella.h>
#elif TARGET_OS_TV == 1
#import "AppboyKit.h"
#endif

@interface MPKitAppboy ()

@property (nonatomic) MPUserIdentity userIdType;

- (NSMutableDictionary<NSString *, NSNumber *> *)optionsDictionary;
+ (id<ABKInAppMessageControllerDelegate>)inAppMessageControllerDelegate;

@end

@interface mParticle_AppboyTests : XCTestCase

@end

@implementation mParticle_AppboyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartwithSimpleConfig {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
    
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42
                                       };
    
    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    NSDictionary *testOptionsDictionary = @{ABKEnableAutomaticLocationCollectionKey:@(YES),
                                            ABKSDKFlavorKey:@7
                                       };
    
    NSDictionary *optionsDictionary = [appBoy optionsDictionary];
    XCTAssertEqualObjects(optionsDictionary, testOptionsDictionary);
}

- (void)testStartwithAdvancedConfig {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
    
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"ABKCollectIDFA":@"true",
                                       @"userIdentificationType":@"CustomerId"
                                       };
    
    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    NSDictionary *testOptionsDictionary = @{ABKEnableAutomaticLocationCollectionKey:@(YES),
                                            ABKSDKFlavorKey:@7,
                                            ABKIDFADelegateKey: appBoy,
                                            @"ABKRquestProcessingPolicy": @(1),
                                            @"ABKFlushInterval":@(2),
                                            @"ABKSessionTimeout":@(3),
                                            @"ABKMinimumTriggerTimeInterval":@(4)
                                            };
    
    NSDictionary *optionsDictionary = [appBoy optionsDictionary];
    XCTAssertEqualObjects(optionsDictionary, testOptionsDictionary);
}

//- (void)testEndpointOverride {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride2 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"http://foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"http://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"http://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"http://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride3 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride4 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com/baz",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride5 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com/baz/baz",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverrideNilHost {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://original.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://original.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://original.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}

- (void)testSetMessageDelegate {
    id<ABKInAppMessageControllerDelegate> delegate = (id)[NSObject new];
    
    XCTAssertNil([MPKitAppboy inAppMessageControllerDelegate]);
    
    [MPKitAppboy setInAppMessageControllerDelegate:delegate];
    
    XCTAssertEqualObjects([MPKitAppboy inAppMessageControllerDelegate], delegate);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertEqualObjects([MPKitAppboy inAppMessageControllerDelegate], delegate);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testWeakMessageDelegate {
    id<ABKInAppMessageControllerDelegate> delegate = (id)[NSObject new];
    
    [MPKitAppboy setInAppMessageControllerDelegate:delegate];
    
    delegate = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertNil([MPKitAppboy inAppMessageControllerDelegate]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testUserIdCustomerId {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];

    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"ABKCollectIDFA":@"true",
                                       @"userIdentificationType":@"CustomerId"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.userIdType, MPUserIdentityCustomerId);
}

- (void)testUserIdMPID {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];

    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"ABKCollectIDFA":@"true",
                                       @"userIdentificationType":@"MPID"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.userIdType, MPUserIdentityOther4);
}

@end
