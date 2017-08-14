//
//  MPKitAppboy.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitAppboy.h"

#ifdef COCOAPODS
    #if TARGET_OS_IOS == 1
        #if defined(__has_include) && __has_include(<Appboy-iOS-SDK/AppboyKit.h>)
            #import <Appboy-iOS-SDK/AppboyKit.h>
        #elif defined(__has_include) && __has_include(<Appboy_iOS_SDK/AppboyKit.h>)
            #import <Appboy_iOS_SDK/AppboyKit.h>
        #else
            #import "AppboyKit.h"
        #endif
    #elif TARGET_OS_TV == 1
        #if defined(__has_include) && __has_include(<AppboyTVOSKit/AppboyKit.h>)
            #import <AppboyTVOSKit/AppboyKit.h>
        #else
            #import "AppboyKit.h"
        #endif
    #endif
#else
    #import <Appboy_iOS_SDK/Appboy-iOS-SDK-umbrella.h>
#endif


NSString *const eabAPIKey = @"apiKey";
NSString *const eabOptions = @"options";
NSString *const hostConfigKey = @"host";
NSString *const dataCenterLocationConfigKey = @"dataCenterLocation";
NSString *const usDataCenterLocation = @"US";
NSString *const euDataCenterLocation = @"EU";
NSString *const originalHost = @"dev.appboy.com";
NSString *const euHost = @"sdk.api.appboy.eu";

static id<ABKInAppMessageControllerDelegate> inAppMessageControllerDelegate = nil;

@interface MPKitAppboy() <ABKIDFADelegate, ABKAppboyEndpointDelegate> {
    Appboy *appboyInstance;
    BOOL collectIDFA;
    BOOL forwardScreenViews;
}

@property (nonatomic) NSString *host;
@property (nonatomic) NSString *dataCenterLocation;

@end


@implementation MPKitAppboy

+ (NSNumber *)kitCode {
    return @28;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Appboy" className:@"MPKitAppboy" startImmediately:NO];
    [MParticle registerExtension:kitRegister];
}

+ (void)setInAppMessageControllerDelegate:(id)delegate {
    inAppMessageControllerDelegate = (id<ABKInAppMessageControllerDelegate>)delegate;
}

#pragma mark Private methods
- (NSString *)stringRepresentation:(id)value {
    NSString *stringRepresentation = nil;

    if ([value isKindOfClass:[NSString class]]) {
        stringRepresentation = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        stringRepresentation = [(NSNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSDate class]]) {
        stringRepresentation = [MPDateFormatter stringFromDateRFC3339:value];
    } else if ([value isKindOfClass:[NSData class]]) {
        stringRepresentation = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }

    return stringRepresentation;
}

- (NSString *)stripCharacter:(NSString *)character fromString:(NSString *)originalString {
    NSRange range = [originalString rangeOfString:character];

    if (range.location == 0) {
        NSMutableString *strippedString = [originalString mutableCopy];
        [strippedString replaceOccurrencesOfString:character withString:@"" options:NSCaseInsensitiveSearch range:range];
        return [strippedString copy];
    } else {
        return originalString;
    }
}

- (MPKitExecStatus *)logAppboyCustomEvent:(MPEvent *)event eventType:(NSUInteger)eventType {
    void (^logCustomEvent)(void) = ^{
        NSDictionary *transformedEventInfo = [event.info transformValuesToString];

        NSMutableDictionary *eventInfo = [[NSMutableDictionary alloc] initWithCapacity:event.info.count];
        [transformedEventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *strippedKey = [self stripCharacter:@"$" fromString:key];
            eventInfo[strippedKey] = obj;
        }];

        [appboyInstance logCustomEvent:event.name withProperties:eventInfo];

        NSString *eventTypeString = [@(eventType) stringValue];

        for (NSString *key in eventInfo) {
            NSString *eventTypePlusNamePlusKey = [[NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key] lowercaseString];
            NSString *hashValue = [MPIHasher hashString:eventTypePlusNamePlusKey];

            NSDictionary *forwardUserAttributes;

            // Delete from array
            forwardUserAttributes = self.configuration[@"ear"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user removeFromCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }

            // Add to array
            forwardUserAttributes = self.configuration[@"eaa"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user addToCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }

            // Add key/value pair
            forwardUserAttributes = self.configuration[@"eas"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user setCustomAttributeWithKey:forwardUserAttributes[hashValue] andStringValue:eventInfo[key]];
            }
        }
    };

    if ([NSThread isMainThread]) {
        logCustomEvent();
    } else {
        dispatch_async(dispatch_get_main_queue(), logCustomEvent);
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

#pragma mark ABKIDFADelegate
- (BOOL)isAdvertisingTrackingEnabled {
    BOOL advertisingTrackingEnabled = NO;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");

    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }

    return advertisingTrackingEnabled && collectIDFA;
}

- (NSString *)advertisingIdentifierString {
    NSString *_advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");

    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];

        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            _advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }

    return _advertiserId;
}

#pragma mark ABKAppboyEndpointDelegate
- (NSString *)getApiEndpoint:(NSString *)appboyApiEndpoint {
    NSString *host = self.host;
    
    if (!host.length) {
        host = euHost;
    }
    
    NSString *endpoint = [appboyApiEndpoint stringByReplacingOccurrencesOfString:originalHost withString:host];
    return endpoint;
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super init];
    if (!self || !configuration[eabAPIKey]) {
        return nil;
    }

    _configuration = configuration;
    _started = startImmediately;
    collectIDFA = NO;
    forwardScreenViews = NO;
    _host = configuration[hostConfigKey];
    _dataCenterLocation = configuration[dataCenterLocationConfigKey];

    if (startImmediately) {
        [self start];
    }

    return self;
}

- (id const)providerKitInstance {
    return [self started] ? appboyInstance : nil;
}

- (void)start {
    static dispatch_once_t appboyPredicate;

    dispatch_once(&appboyPredicate, ^{
        NSArray <NSString *> *serverKeys = @[@"ABKRequestProcessingPolicyOptionKey", @"ABKFlushIntervalOptionKey", @"ABKSessionTimeoutKey", @"ABKMinimumTriggerTimeIntervalKey"];
        NSArray <NSString *> *appboyKeys = @[ABKRequestProcessingPolicyOptionKey, ABKFlushIntervalOptionKey, ABKSessionTimeoutKey, ABKMinimumTriggerTimeIntervalKey];
        NSMutableDictionary<NSString *, NSNumber *> *optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterNoStyle;

        [serverKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull serverKey, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *optionValue = self.configuration[serverKey];

            if (optionValue) {
                NSString *appboyKey = appboyKeys[idx];
                optionsDictionary[appboyKey] = [numberFormatter numberFromString:optionValue];
            }
        }];

        collectIDFA = self.configuration[@"ABKCollectIDFA"] && [self.configuration[@"ABKCollectIDFA"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
        if (collectIDFA) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKIDFADelegateKey] = self;
#pragma clang diagnostic pop
        }
        
        if (self.host.length || (self.dataCenterLocation && [self.dataCenterLocation isEqualToString:euDataCenterLocation])) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKAppboyEndpointDelegateKey] = self;
#pragma clang diagnostic pop
        }

        if (self.configuration[@"forwardScreenViews"]) {
            forwardScreenViews = [self.configuration[@"forwardScreenViews"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
        }

        if (optionsDictionary.count == 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
          optionsDictionary = @{ ABKSDKFlavorKey : @(MPARTICLE) };
        } else {
          optionsDictionary[ABKSDKFlavorKey] = @(MPARTICLE);
#pragma clang diagnostic pop
        }

        [Appboy startWithApiKey:self.configuration[eabAPIKey]
                  inApplication:[UIApplication sharedApplication]
              withLaunchOptions:self.launchOptions
              withAppboyOptions:optionsDictionary];

        CFTypeRef appboyRef = CFRetain((__bridge CFTypeRef)[Appboy sharedInstance]);
        appboyInstance = (__bridge Appboy *)appboyRef;

        if (collectIDFA) {
            appboyInstance.idfaDelegate = self;
        }

        _started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
#if TARGET_OS_IOS == 1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [appboyInstance getActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:^{}];
#pragma clang diagnostic pop

#endif

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    [appboyInstance.user incrementCustomUserAttribute:key by:[value integerValue]];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess forwardCount:0];

    if (commerceEvent.action == MPCommerceEventActionPurchase) {
        NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
        NSDictionary *transactionAttributes = [commerceEvent.transactionAttributes beautifiedDictionaryRepresentation];

        if (transactionAttributes) {
            [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
        }

        NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
        NSArray *keys = @[kMPExpCECheckoutOptions, kMPExpCECheckoutStep, kMPExpCEProductListName, kMPExpCEProductListSource];

        for (NSString *key in keys) {
            if (commerceEventAttributes[key]) {
                baseProductAttributes[key] = commerceEventAttributes[key];
            }
        }

        NSArray *products = commerceEvent.products;
        NSString *currency = commerceEvent.currency ? : @"USD";
        NSMutableDictionary *properties;

        for (MPProduct *product in products) {
            // Add relevant attributes from the commerce event
            properties = [[NSMutableDictionary alloc] init];
            if (baseProductAttributes.count > 0) {
                [properties addEntriesFromDictionary:baseProductAttributes];
            }

            // Add attributes from the product itself
            NSDictionary *productDictionary = [product beautifiedDictionaryRepresentation];
            if (productDictionary) {
                [properties addEntriesFromDictionary:productDictionary];
            }

            // Strips key/values already being passed to Appboy, plus key/values initialized to default values
            keys = @[kMPExpProductSKU, kMPProductCurrency, kMPExpProductUnitPrice, kMPExpProductQuantity, kMPProductAffiliation, kMPExpProductCategory, kMPExpProductName];
            [properties removeObjectsForKeys:keys];

            [appboyInstance logPurchase:product.sku
                             inCurrency:currency
                                atPrice:[NSDecimalNumber decimalNumberWithDecimal:[product.price decimalValue]]
                           withQuantity:[product.quantity integerValue]
                          andProperties:properties];

            [execStatus incrementForwardCount];
        }
    } else {
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];

        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }

    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    return [self logAppboyCustomEvent:event eventType:event.type];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus = nil;

    if (forwardScreenViews) {
        execStatus = [self logAppboyCustomEvent:event eventType:0];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeCannotExecute];
    }

    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
#if TARGET_OS_IOS == 1
    [appboyInstance registerApplication:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult fetchResult) {}];
#endif

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [appboyInstance.user unsetCustomAttributeWithKey:key];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
#if TARGET_OS_IOS == 1
    [appboyInstance registerPushToken:[NSString stringWithFormat:@"%@", deviceToken]];
#endif

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    MPKitReturnCode returnCode;

    if (optOut) {
        [appboyInstance.user setEmailNotificationSubscriptionType:ABKUnsubscribed];
        returnCode = MPKitReturnCodeSuccess;
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:returnCode];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;

    if (!value) {
        [appboyInstance.user unsetCustomAttributeWithKey:key];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        return execStatus;
    }

    value = [self stringRepresentation:value];
    if (!value) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
        return execStatus;
    }

    if ([key isEqualToString:mParticleUserAttributeFirstName]) {
        appboyInstance.user.firstName = value;
    } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
        appboyInstance.user.lastName = value;
    } else if ([key isEqualToString:mParticleUserAttributeAge]) {
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:now];
        NSInteger age = 0;

        @try {
            age = [value integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid age: %@", value);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }

        NSDateComponents *birthComponents = [[NSDateComponents alloc] init];
        birthComponents.year = dateComponents.year - age;
        birthComponents.month = 01;
        birthComponents.day = 01;

        appboyInstance.user.dateOfBirth = [calendar dateFromComponents:birthComponents];
    } else if ([key isEqualToString:mParticleUserAttributeCountry]) {
        appboyInstance.user.country = value;
    } else if ([key isEqualToString:mParticleUserAttributeCity]) {
        appboyInstance.user.homeCity = value;
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        appboyInstance.user.gender = [value isEqualToString:mParticleGenderMale] ? ABKUserGenderMale : ABKUserGenderFemale;
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] || [key isEqualToString:@"$MPUserMobile"]) {
        appboyInstance.user.phone = value;
    } else {
        key = [self stripCharacter:@"$" fromString:key];

        [appboyInstance.user setCustomAttributeWithKey:key andStringValue:value];
    }

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus = nil;

    switch (identityType) {
        case MPUserIdentityCustomerId: {
            void (^changeUser)(void) = ^ {
                [appboyInstance changeUser:identityString];
            };

            if ([NSThread isMainThread]) {
                changeUser();
            } else {
                dispatch_async(dispatch_get_main_queue(), changeUser);
            }
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
            break;

        case MPUserIdentityEmail:
            appboyInstance.user.email = identityString;
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
            break;

        default:
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeUnavailable];
            break;
    }

    return execStatus;
}

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response {
    [appboyInstance userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{}];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}
#endif

@end
