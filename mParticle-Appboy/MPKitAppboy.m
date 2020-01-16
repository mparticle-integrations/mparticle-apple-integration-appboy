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
    #if TARGET_OS_IOS == 1
        #import <Appboy_iOS_SDK/Appboy-iOS-SDK-umbrella.h>
    #elif TARGET_OS_TV == 1
        #import "AppboyKit.h"
    #endif
#endif

static NSString *const eabAPIKey = @"apiKey";
static NSString *const eabOptions = @"options";
static NSString *const hostConfigKey = @"host";
static NSString *const userIdTypeKey = @"userIdentificationType";

// The possible values for userIdentificationType
static NSString *const userIdValueOther = @"Other";
static NSString *const userIdValueCustomerId = @"CustomerId";
static NSString *const userIdValueFacebook = @"Facebook";
static NSString *const userIdValueTwitter = @"Twitter";
static NSString *const userIdValueGoogle = @"Google";
static NSString *const userIdValueMicrosoft = @"Microsoft";
static NSString *const userIdValueYahoo = @"Yahoo";
static NSString *const userIdValueEmail = @"Email";
static NSString *const userIdValueAlias = @"Alias";
static NSString *const userIdValueMPID = @"MPID";

// User Attribute key with reserved functionality for Braze kit
static NSString *const brazeUserAttributeDob = @"dob";

__weak static id<ABKInAppMessageControllerDelegate> inAppMessageControllerDelegate = nil;

@interface MPKitAppboy() {
    Appboy *appboyInstance;
    BOOL collectIDFA;
    BOOL forwardScreenViews;
}

@property (nonatomic) NSString *host;
@property (nonatomic) MPUserIdentity userIdType;

@end


@implementation MPKitAppboy

+ (NSNumber *)kitCode {
    return @28;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Appboy" className:@"MPKitAppboy"];
    [MParticle registerExtension:kitRegister];
}

+ (void)setInAppMessageControllerDelegate:(id)delegate {
    inAppMessageControllerDelegate = (id<ABKInAppMessageControllerDelegate>)delegate;
}

+ (id<ABKInAppMessageControllerDelegate>)inAppMessageControllerDelegate {
    return inAppMessageControllerDelegate;
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
        NSDictionary *transformedEventInfo = [event.customAttributes transformValuesToString];
        
        NSMutableDictionary *eventInfo = [[NSMutableDictionary alloc] initWithCapacity:event.customAttributes.count];
        [transformedEventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *strippedKey = [self stripCharacter:@"$" fromString:key];
            eventInfo[strippedKey] = obj;
        }];
        
        [self->appboyInstance logCustomEvent:event.name withProperties:eventInfo];
        
        NSString *eventTypeString = [@(eventType) stringValue];
        
        for (NSString *key in eventInfo) {
            NSString *eventTypePlusNamePlusKey = [[NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key] lowercaseString];
            NSString *hashValue = [MPIHasher hashString:eventTypePlusNamePlusKey];
            
            NSDictionary *forwardUserAttributes;
            
            // Delete from array
            forwardUserAttributes = self.configuration[@"ear"];
            if (forwardUserAttributes[hashValue]) {
                [self->appboyInstance.user removeFromCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add to array
            forwardUserAttributes = self.configuration[@"eaa"];
            if (forwardUserAttributes[hashValue]) {
                [self->appboyInstance.user addToCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add key/value pair
            forwardUserAttributes = self.configuration[@"eas"];
            if (forwardUserAttributes[hashValue]) {
                [self->appboyInstance.user setCustomAttributeWithKey:forwardUserAttributes[hashValue] andStringValue:eventInfo[key]];
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

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    if (!configuration[eabAPIKey]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    _configuration = configuration;
    _started = NO;
    collectIDFA = NO;
    forwardScreenViews = NO;
    
    _host = configuration[hostConfigKey];
    _userIdType = [self userIdentityForString:configuration[userIdTypeKey]];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id const)providerKitInstance {
    return [self started] ? appboyInstance : nil;
}

- (void)start {
    static dispatch_once_t appboyPredicate;
    
    dispatch_once(&appboyPredicate, ^{
        NSMutableDictionary<NSString *, NSNumber *> *optionsDict = [self optionsDictionary];
        
        [Appboy startWithApiKey:self.configuration[eabAPIKey]
                  inApplication:[UIApplication sharedApplication]
              withLaunchOptions:self.launchOptions
              withAppboyOptions:optionsDict];
        
        if (![Appboy sharedInstance] ) {
            return;
        }
        CFTypeRef appboyRef = CFRetain((__bridge CFTypeRef)[Appboy sharedInstance]);
        self->appboyInstance = (__bridge Appboy *)appboyRef;
        
        if (self->collectIDFA) {
            self->appboyInstance.idfaDelegate = (id)self;
        }
        
#if TARGET_OS_IOS == 1
        if ([MPKitAppboy inAppMessageControllerDelegate]) {
            self->appboyInstance.inAppMessageController.delegate = [MPKitAppboy inAppMessageControllerDelegate];
        }
#endif
        
        self->_started = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (NSMutableDictionary<NSString *, NSNumber *> *)optionsDictionary {
    NSArray <NSString *> *serverKeys = @[@"ABKRequestProcessingPolicyOptionKey", @"ABKFlushIntervalOptionKey", @"ABKSessionTimeoutKey", @"ABKMinimumTriggerTimeIntervalKey"];
    NSArray <NSString *> *appboyKeys = @[ABKRequestProcessingPolicyOptionKey, ABKFlushIntervalOptionKey, ABKSessionTimeoutKey, ABKMinimumTriggerTimeIntervalKey];
    NSMutableDictionary<NSString *, NSNumber *> *optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    
    [serverKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull serverKey, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *optionValue = self.configuration[serverKey];
        
        if (optionValue != nil && (NSNull *)optionValue != [NSNull null]) {
            NSString *appboyKey = appboyKeys[idx];
            NSNumber *numberValue = nil;
            @try {
                numberValue = [numberFormatter numberFromString:optionValue];
            } @catch (NSException *exception) {
                numberValue = nil;
            }
            if (numberValue != nil) {
                optionsDictionary[appboyKey] = numberValue;
            }
        }
    }];
    
    self->collectIDFA = self.configuration[@"ABKCollectIDFA"] && [self.configuration[@"ABKCollectIDFA"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    if (self->collectIDFA) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        optionsDictionary[ABKIDFADelegateKey] = (id)self;
#pragma clang diagnostic pop
    }
    
    if (self.host.length) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        optionsDictionary[ABKEndpointKey] = self.host;
#pragma clang diagnostic pop
    }
    
    if (self.configuration[@"forwardScreenViews"]) {
        self->forwardScreenViews = [self.configuration[@"forwardScreenViews"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    }
    
    if (optionsDictionary.count == 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
    }
    optionsDictionary[ABKSDKFlavorKey] = @(MPARTICLE);
#pragma clang diagnostic pop
    
#if TARGET_OS_IOS == 1
    optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(YES);
    if (self.configuration[@"ABKDisableAutomaticLocationCollectionKey"]) {
        if ([self.configuration[@"ABKDisableAutomaticLocationCollectionKey"] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(NO);
#pragma clang diagnostic pop
        }
    }
#elif TARGET_OS_TVOS == 1
    optionsDictionary[ABKDisableAutomaticLocationCollectionKey] = @(NO);
    if (self.configuration[@"ABKDisableAutomaticLocationCollectionKey"]) {
        if ([self.configuration[@"ABKDisableAutomaticLocationCollectionKey"] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKDisableAutomaticLocationCollectionKey] = @(YES);
#pragma clang diagnostic pop
        }
    }
#endif
    
    return optionsDictionary;
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

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
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
            [self logBaseEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
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
    [appboyInstance registerDeviceToken:deviceToken];
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
    } else if ([key isEqualToString:brazeUserAttributeDob]) {
        // Expected Date Format @"yyyy'-'MM'-'dd"
        NSCalendar *calendar = [NSCalendar currentCalendar];

        NSString *yearString = [value substringToIndex:3];
        NSRange monthRange = NSMakeRange(5, 2);
        NSString *monthString = [value substringWithRange:monthRange];
        NSRange dayRange = NSMakeRange(8, 2);
        NSString *dayString = [value substringWithRange:dayRange];

        NSInteger year = 0;
        NSInteger month = 0;
        NSInteger day = 0;
           
       @try {
           year = [yearString integerValue];
       } @catch (NSException *exception) {
           NSLog(@"mParticle -> Invalid dob year: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", yearString);
           execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
           return execStatus;
       }
        
        @try {
            month = [monthString integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid dob month: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", monthString);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
        
        @try {
            day = [dayString integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid dob day: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", dayString);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
       
       NSDateComponents *birthComponents = [[NSDateComponents alloc] init];
       birthComponents.year = year;
       birthComponents.month = month;
       birthComponents.day = day;
       
       appboyInstance.user.dateOfBirth = [calendar dateFromComponents:birthComponents];
   } else if ([key isEqualToString:mParticleUserAttributeCountry]) {
    appboyInstance.user.country = value;
    } else if ([key isEqualToString:mParticleUserAttributeCity]) {
        appboyInstance.user.homeCity = value;
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
#if TARGET_OS_IOS == 1
        appboyInstance.user.gender = ABKUserGenderOther;
        if ([value isEqualToString:mParticleGenderMale]) {
            appboyInstance.user.gender = ABKUserGenderMale;
        } else if ([value isEqualToString:mParticleGenderFemale]) {
            appboyInstance.user.gender = ABKUserGenderFemale;
        } else if ([value isEqualToString:mParticleGenderNotAvailable]) {
            appboyInstance.user.gender = ABKUserGenderNotApplicable;
        }
#elif TARGET_OS_TV == 1
        appboyInstance.user.gender = [value isEqualToString:mParticleGenderMale] ? ABKUserGenderMale : ABKUserGenderFemale;
#endif
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] || [key isEqualToString:@"$MPUserMobile"]) {
        appboyInstance.user.phone = value;
    } else {
        key = [self stripCharacter:@"$" fromString:key];
        
        [appboyInstance.user setCustomAttributeWithKey:key andStringValue:value];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nonnull NSArray<NSString *> *)values {
    MPKitExecStatus *execStatus;
    
    if (!values) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
    } else {
        [appboyInstance.user setCustomAttributeArrayWithKey:key array:values];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    }
    
    return execStatus;
}

- (nonnull MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request];
}

- (nonnull MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request];
}

- (nonnull MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request];
}

- (nonnull MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request];
}

- (nonnull MPKitExecStatus *)updateUser:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    MPKitExecStatus *execStatus = nil;
    
    if (request.userIdentities) {
        NSMutableDictionary *userIDsCopy = [request.userIdentities copy];
        NSString *userId;
        
        switch (_userIdType) {
            case MPUserIdentityOther:
                if (userIDsCopy[@(MPUserIdentityOther)]) {
                    userId = userIDsCopy[@(MPUserIdentityOther)];
                }
                break;
            case MPUserIdentityCustomerId:
                if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                    userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                }
                break;
            case MPUserIdentityFacebook:
                if (userIDsCopy[@(MPUserIdentityFacebook)]) {
                    userId = userIDsCopy[@(MPUserIdentityFacebook)];
                }
                break;
            case MPUserIdentityTwitter:
                if (userIDsCopy[@(MPUserIdentityTwitter)]) {
                    userId = userIDsCopy[@(MPUserIdentityTwitter)];
                }
                break;
            case MPUserIdentityGoogle:
                if (userIDsCopy[@(MPUserIdentityGoogle)]) {
                    userId = userIDsCopy[@(MPUserIdentityGoogle)];
                }
                break;
            case MPUserIdentityMicrosoft:
                if (userIDsCopy[@(MPUserIdentityMicrosoft)]) {
                    userId = userIDsCopy[@(MPUserIdentityMicrosoft)];
                }
                break;
            case MPUserIdentityYahoo:
                if (userIDsCopy[@(MPUserIdentityYahoo)]) {
                    userId = userIDsCopy[@(MPUserIdentityYahoo)];
                }
                break;
            case MPUserIdentityEmail:
                if (userIDsCopy[@(MPUserIdentityEmail)]) {
                    userId = userIDsCopy[@(MPUserIdentityEmail)];
                }
                break;
            case MPUserIdentityAlias:
                if (userIDsCopy[@(MPUserIdentityAlias)]) {
                    userId = userIDsCopy[@(MPUserIdentityAlias)];
                }
                break;
            case MPUserIdentityOther4:
                if (user != nil) {
                    userId = user.userId.stringValue;
                }
                break;
                
            default:
                if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                    userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                }
                break;
        }
        
        if (userId) {
            void (^changeUser)(void) = ^ {
                [self->appboyInstance changeUser:userId];
            };
            
            if ([NSThread isMainThread]) {
                changeUser();
            } else {
                dispatch_async(dispatch_get_main_queue(), changeUser);
            }
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
        
        if (userIDsCopy[@(MPUserIdentityEmail)]) {
            appboyInstance.user.email = userIDsCopy[@(MPUserIdentityEmail)];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
}

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0)) {
    [appboyInstance userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}
#endif

- (MPUserIdentity)userIdentityForString:(nullable NSString *)userIdString {
    if (userIdString != nil) {
        if ([userIdString isEqualToString:userIdValueOther]) {
            return MPUserIdentityOther;
        } else if ([userIdString isEqualToString:userIdValueCustomerId]) {
            return MPUserIdentityCustomerId;
        } else if ([userIdString isEqualToString:userIdValueFacebook]) {
            return MPUserIdentityFacebook;
        } else if ([userIdString isEqualToString:userIdValueTwitter]) {
            return MPUserIdentityTwitter;
        } else if ([userIdString isEqualToString:userIdValueGoogle]) {
            return MPUserIdentityGoogle;
        } else if ([userIdString isEqualToString:userIdValueMicrosoft]) {
            return MPUserIdentityMicrosoft;
        } else if ([userIdString isEqualToString:userIdValueYahoo]) {
            return MPUserIdentityYahoo;
        } else if ([userIdString isEqualToString:userIdValueEmail]) {
            return MPUserIdentityEmail;
        } else if ([userIdString isEqualToString:userIdValueAlias]) {
            return MPUserIdentityAlias;
        } else if ([userIdString isEqualToString:userIdValueMPID]) {
            return MPUserIdentityOther4;
        }
    }
    
    return MPUserIdentityCustomerId;
}

@end
