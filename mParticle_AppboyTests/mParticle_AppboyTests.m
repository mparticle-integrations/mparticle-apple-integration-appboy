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
    
    NSDictionary *testOptionsDictionary = @{ABKDisableAutomaticLocationCollectionKey:@(NO),
                                            ABKSDKFlavorKey:@6
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
                                       @"ABKCollectIDFA":@"true"
                                       };
    
    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    NSDictionary *testOptionsDictionary = @{ABKDisableAutomaticLocationCollectionKey:@(NO),
                                            ABKSDKFlavorKey:@6,
                                            ABKIDFADelegateKey: appBoy,
                                            @"ABKRquestProcessingPolicy": @(1),
                                            @"ABKFlushInterval":@(2),
                                            @"ABKSessionTimeout":@(3),
                                            @"ABKMinimumTriggerTimeInterval":@(4)
                                            };
    
    NSDictionary *optionsDictionary = [appBoy optionsDictionary];
    XCTAssertEqualObjects(optionsDictionary, testOptionsDictionary);
}

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

@end
