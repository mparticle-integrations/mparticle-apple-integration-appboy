@import mParticle_Apple_SDK;
@import mParticle_Appboy;
@import XCTest;
@import OCMock;
#if TARGET_OS_IOS
    @import BrazeKitCompat;
    @import BrazeUI;
#else
    @import BrazeKitCompat;
#endif

@interface MPKitAppboy ()

- (Braze *)appboyInstance;
- (void)setAppboyInstance:(Braze *)instance;
- (NSMutableDictionary<NSString *, NSNumber *> *)optionsDictionary;
+ (id<BrazeInAppMessageUIDelegate>)inAppMessageControllerDelegate;
- (void)setEnableTypeDetection:(BOOL)enableTypeDetection;

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
    id<BrazeInAppMessageUIDelegate> delegate = (id)[NSObject new];
    
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
    id<BrazeInAppMessageUIDelegate> delegate = (id)[NSObject new];
    
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
                                       @"userIdentificationType":@"CustomerId"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.configuration[@"userIdentificationType"], @"CustomerId");
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
                                       @"userIdentificationType":@"MPID"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.configuration[@"userIdentificationType"], @"MPID");
}

//- (void)testlogCommerceEvent {
//    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
//
//    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
//    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
//    id mockClient = OCMPartialMock(testClient);
//    [kit setAppboyInstance:mockClient];
//
//    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);
//
//    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
//
//    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
//    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
//    attributes.transactionId = @"foo-transaction-id";
//    attributes.revenue = @13.00;
//    attributes.tax = @3;
//    attributes.shipping = @-3;
//
//    event.transactionAttributes = attributes;
//
//    [[mockClient expect] logPurchase:@"1131331343"
//                          inCurrency:@"USD"
//                             atPrice:[[NSDecimalNumber alloc] initWithString:@"13"]
//                        withQuantity:[[NSNumber numberWithInteger:1] longLongValue]
//                       andProperties:@{@"Shipping Amount" : @-3,
//                                       @"Total Amount" : @13.00,
//                                       @"Total Product Amount" : @"13",
//                                       @"Tax Amount" : @3,
//                                       @"Transaction Id" : @"foo-transaction-id"
//                       }];
//
//    MPKitExecStatus *execStatus = [kit logBaseEvent:event];
//
//    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
//
//    [mockClient verify];
//
//    [mockClient stopMocking];
//}
//
//- (void)testTypeDetection {
//    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
//
//    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
//    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
//    id mockClient = OCMPartialMock(testClient);
//    [kit setAppboyInstance:mockClient];
//
//    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);
//
//
//    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
//    event.customAttributes = @{@"foo":@"5.0", @"bar": @"true", @"baz": @"abc", @"qux": @"-3", @"quux": @"1970-01-01T00:00:00Z"};
//
//    [kit setEnableTypeDetection:YES];
//    [[mockClient expect] logCustomEvent:event.name withProperties:@{@"foo":@5.0, @"bar": @YES, @"baz":@"abc", @"qux": @-3, @"quux": [NSDate dateWithTimeIntervalSince1970:0]}];
//
//    MPKitExecStatus *execStatus = [kit logBaseEvent:event];
//
//    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
//
//    [mockClient verify];
//
//    [mockClient stopMocking];
//}
//
//
//- (void)testTypeDetectionDisable {
//    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
//
//    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
//    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
//    id mockClient = OCMPartialMock(testClient);
//    [kit setAppboyInstance:mockClient];
//
//    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);
//
//
//    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
//    event.customAttributes = @{@"foo":@"5.0", @"bar": @"true", @"baz": @"abc", @"quz": @"-3", @"qux": @"1970-01-01T00:00:00Z"};
//
//    [kit setEnableTypeDetection:NO];
//    [[mockClient expect] logCustomEvent:event.name withProperties:event.customAttributes];
//
//    MPKitExecStatus *execStatus = [kit logBaseEvent:event];
//
//    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
//
//    [mockClient verify];
//
//    [mockClient stopMocking];
//}

- (void)testEventWithEmptyProperties {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);


    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
    event.customAttributes = @{};

    [kit setEnableTypeDetection:NO];
    [[mockClient expect] logCustomEvent:event.name];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

@end
