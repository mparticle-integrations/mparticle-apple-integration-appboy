#import "MPKitAppboy.h"

#if SWIFT_PACKAGE
    #ifdef TARGET_OS_IOS
        @import BrazeKitCompat;
        @import BrazeUICompat;
    #else
        @import BrazeKitCompat;
    #endif
#else
    #ifdef TARGET_OS_IOS
        @import BrazeKitCompat;
        @import BrazeUICompat;
    #else
        @import BrazeKitCompat;
    #endif
#endif

static NSString *const eabAPIKey = @"apiKey";
static NSString *const eabOptions = @"options";
static NSString *const hostConfigKey = @"host";
static NSString *const userIdTypeKey = @"userIdentificationType";
static NSString *const emailIdTypeKey = @"emailIdentificationType";
static NSString *const enableTypeDetectionKey = @"enableTypeDetection";

// The possible values for userIdentificationType
static NSString *const userIdValueOther = @"Other";
static NSString *const userIdValueOther2 = @"Other2";
static NSString *const userIdValueOther3 = @"Other3";
static NSString *const userIdValueOther4 = @"Other4";
static NSString *const userIdValueOther5 = @"Other5";
static NSString *const userIdValueOther6 = @"Other6";
static NSString *const userIdValueOther7 = @"Other7";
static NSString *const userIdValueOther8 = @"Other8";
static NSString *const userIdValueOther9 = @"Other9";
static NSString *const userIdValueOther10 = @"Other10";
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

#ifdef TARGET_OS_IOS
__weak static id<BrazeInAppMessageUIDelegate> inAppMessageControllerDelegate = nil;
#endif
__weak static id<BrazeDelegate> urlDelegate = nil;

@interface MPKitAppboy() {
    Braze *appboyInstance;
    BOOL collectIDFA;
    BOOL forwardScreenViews;
}

@property (nonatomic) NSString *host;
@property (nonatomic) BOOL enableTypeDetection;

@end


@implementation MPKitAppboy

+ (NSNumber *)kitCode {
    return @28;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Appboy" className:@"MPKitAppboy"];
    [MParticle registerExtension:kitRegister];
}

#ifdef TARGET_OS_IOS
+ (void)setInAppMessageControllerDelegate:(id)delegate {
    inAppMessageControllerDelegate = (id<BrazeInAppMessageUIDelegate>)delegate;
}

+ (id<BrazeInAppMessageUIDelegate>)inAppMessageControllerDelegate {
    return inAppMessageControllerDelegate;
}
#endif

+ (void)setURLDelegate:(id)delegate {
    urlDelegate = (id<BrazeDelegate>)delegate;
}

+ (id<BrazeDelegate>)urlDelegate {
    return urlDelegate;
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

- (Braze *)appboyInstance {
    return self->appboyInstance;
}

- (void)setAppboyInstance:(Braze *)instance {
    self->appboyInstance = instance;
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
        
        NSDictionary *detectedEventInfo = eventInfo;
        if (self->_enableTypeDetection) {
            detectedEventInfo = [self simplifiedDictionary:eventInfo];
        }

        // Appboy expects that the properties are non empty when present.
        if (detectedEventInfo && detectedEventInfo.count > 0) {
            [self->appboyInstance logCustomEvent:event.name properties:detectedEventInfo];
        } else {
            [self->appboyInstance logCustomEvent:event.name];
        }
        
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
                [self setUserAttribute:forwardUserAttributes[hashValue] value:eventInfo[key]];
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

    collectIDFA = NO;
    forwardScreenViews = NO;
    
    _host = configuration[hostConfigKey];
    _enableTypeDetection = [configuration[enableTypeDetectionKey] boolValue];
    
    //If Braze is already initialized, immediately "start" the kit, this
    //is here for:
    // 1. Apps that initialize Braze prior to mParticle, and/or
    // 2. Apps that initialize mParticle too late, causing the SDK to miss
    //    the launch notification which would otherwise trigger start().
    if (self->appboyInstance) {
        NSLog(@"mParticle -> Warning: Braze SDK initialized outside of mParticle kit, this will mean Braze settings within the mParticle dashboard such as API key, endpoint URL, flush interval and others will not be respected.");
        [self start];
    } else {
        _started = NO;
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id const)providerKitInstance {
    return [self started] ? appboyInstance : nil;
}

- (void)start {
    if (!self->appboyInstance) {
        NSDictionary *optionsDict = [self optionsDictionary];
        BRZConfiguration *configuration = [[BRZConfiguration alloc] initWithApiKey:self.configuration[eabAPIKey] endpoint:optionsDict[ABKEndpointKey]];
        configuration.api.requestPolicy = ((NSNumber *)optionsDict[ABKRequestProcessingPolicyOptionKey]).intValue;
        configuration.api.flushInterval = ((NSNumber *)optionsDict[ABKFlushIntervalOptionKey]).doubleValue;
        configuration.sessionTimeout = ((NSNumber *)optionsDict[ABKSessionTimeoutKey]).doubleValue;
        configuration.triggerMinimumTimeInterval = ((NSNumber *)optionsDict[ABKMinimumTriggerTimeIntervalKey]).doubleValue;
        configuration.location.automaticLocationCollection = optionsDict[ABKEnableAutomaticLocationCollectionKey];
        [configuration.api addSDKMetadata:@[BRZSDKMetadata.mparticle]];
        configuration.api.sdkFlavor = ((NSNumber *)optionsDict[ABKSDKFlavorKey]).intValue;
        
        self->appboyInstance = [[Braze alloc] initWithConfiguration:configuration];
    }
    
    if (!self->appboyInstance) {
        return;
    }
    
    if (self->collectIDFA) {
        [self->appboyInstance setIdentifierForAdvertiser:[self advertisingIdentifierString]];
        [self->appboyInstance setAdTrackingEnabled:[self isAdvertisingTrackingEnabled]];
    }
    
#ifdef TARGET_OS_IOS
    if ([MPKitAppboy inAppMessageControllerDelegate]) {
        BrazeInAppMessageUI *inAppMessageUI = [[BrazeInAppMessageUI alloc] init];
        inAppMessageUI.delegate = [MPKitAppboy inAppMessageControllerDelegate];
    }
#endif
    
    self->_started = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (NSMutableDictionary<NSString *, NSObject *> *)optionsDictionary {
    NSArray <NSString *> *serverKeys = @[@"ABKRequestProcessingPolicyOptionKey", @"ABKFlushIntervalOptionKey", @"ABKSessionTimeoutKey", @"ABKMinimumTriggerTimeIntervalKey"];
    NSArray <NSString *> *appboyKeys = @[ABKRequestProcessingPolicyOptionKey, ABKFlushIntervalOptionKey, ABKSessionTimeoutKey, ABKMinimumTriggerTimeIntervalKey];
    NSMutableDictionary<NSString *, NSObject *> *optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
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
    
#ifdef TARGET_OS_IOS
    optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(YES);
    if (self.configuration[@"ABKDisableAutomaticLocationCollectionKey"]) {
        if ([self.configuration[@"ABKDisableAutomaticLocationCollectionKey"] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(NO);
#pragma clang diagnostic pop
        }
    }
#endif
    
    if ([MPKitAppboy urlDelegate]) {
        optionsDictionary[ABKURLDelegateKey] = (NSObject *)[MPKitAppboy urlDelegate];
    }
    
    return optionsDictionary;
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
    
    NSDictionary *detectedEventInfo = commerceEvent.customAttributes;
    if (self->_enableTypeDetection) {
        detectedEventInfo = [self simplifiedDictionary:commerceEvent.customAttributes];
    }
    
    if (commerceEvent.action == MPCommerceEventActionPurchase) {
        NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
        NSDictionary *transactionAttributes = [self simplifiedDictionary:[commerceEvent.transactionAttributes beautifiedDictionaryRepresentation]];
        
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
                               currency:currency
                                  price:[product.price doubleValue]
                               quantity:[product.quantity integerValue]
                             properties:properties];
            
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
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];

#ifdef TARGET_OS_IOS
    if (![appboyInstance.notifications handleBackgroundNotificationWithUserInfo:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult fetchResult) {}]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
    }
#endif
    
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [appboyInstance.user unsetCustomAttributeWithKey:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
#ifdef TARGET_OS_IOS
    [appboyInstance.notifications registerDeviceToken:deviceToken];
#endif
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    MPKitReturnCode returnCode;
    
    if (optOut) {
        [appboyInstance.user setEmailSubscriptionState:BRZUserSubscriptionStateSubscribed];
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
        [appboyInstance.user setFirstName:value];
    } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
        [appboyInstance.user setLastName:value];
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
        
        [appboyInstance.user setDateOfBirth:[calendar dateFromComponents:birthComponents]];
    } else if ([key isEqualToString:brazeUserAttributeDob]) {
        // Expected Date Format @"yyyy'-'MM'-'dd"
        NSCalendar *calendar = [NSCalendar currentCalendar];

        NSString *yearString = [value substringToIndex:4];
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
       
       [appboyInstance.user setDateOfBirth:[calendar dateFromComponents:birthComponents]];
   } else if ([key isEqualToString:mParticleUserAttributeCountry]) {
    [appboyInstance.user setCountry:value];
    } else if ([key isEqualToString:mParticleUserAttributeCity]) {
        [appboyInstance.user setHomeCity:value];
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        [appboyInstance.user setGender:BRZUserGender.other];
        if ([value isEqualToString:mParticleGenderMale]) {
            [appboyInstance.user setGender:BRZUserGender.male];
        } else if ([value isEqualToString:mParticleGenderFemale]) {
            [appboyInstance.user setGender:BRZUserGender.female];
        } else if ([value isEqualToString:mParticleGenderNotAvailable]) {
            [appboyInstance.user setGender:BRZUserGender.notApplicable];
        }
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] || [key isEqualToString:@"$MPUserMobile"]) {
        [appboyInstance.user setPhoneNumber:value];
    } else if ([key isEqualToString:mParticleUserAttributeZip]){
        [appboyInstance.user setCustomAttributeWithKey:@"Zip" stringValue:value];
    } else {
        key = [self stripCharacter:@"$" fromString:key];
        
        if (!_enableTypeDetection) {
            [appboyInstance.user setCustomAttributeWithKey:key stringValue:value];
        } else {
            NSDictionary *tempConversionDictionary = @{key: value};
            tempConversionDictionary = [self simplifiedDictionary:tempConversionDictionary];
            id obj = tempConversionDictionary[key];
            if ([obj isKindOfClass:[NSString class]]) {
                [appboyInstance.user setCustomAttributeWithKey:key stringValue:obj];
            } else if ([obj isKindOfClass:[NSNumber class]]) {
                if ([self isBoolNumber:obj]) {
                    [appboyInstance.user setCustomAttributeWithKey:key boolValue:((NSNumber *)obj).boolValue];
                } else if ([self isInteger:value]) {
                    [appboyInstance.user setCustomAttributeWithKey:key intValue:((NSNumber *)obj).intValue];
                } else if ([self isFloat:value]) {
                    [appboyInstance.user setCustomAttributeWithKey:key doubleValue:((NSNumber *)obj).doubleValue];
                }
            } else if ([obj isKindOfClass:[NSDate class]]) {
                [appboyInstance.user setCustomAttributeWithKey:key dateValue:obj];
            }
        }
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
        
        if (_configuration[userIdTypeKey]) {
            NSString *userIdKey = _configuration[userIdTypeKey];
            if ([userIdKey isEqualToString:userIdValueOther]) {
                if (userIDsCopy[@(MPUserIdentityOther)]) {
                    userId = userIDsCopy[@(MPUserIdentityOther)];
                }
            } else if ([userIdKey isEqualToString:userIdValueOther2]) {
                    if (userIDsCopy[@(MPUserIdentityOther2)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther2)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther3]) {
                    if (userIDsCopy[@(MPUserIdentityOther3)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther3)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther4]) {
                    if (userIDsCopy[@(MPUserIdentityOther4)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther4)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther5]) {
                    if (userIDsCopy[@(MPUserIdentityOther5)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther5)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther6]) {
                    if (userIDsCopy[@(MPUserIdentityOther6)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther6)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther7]) {
                    if (userIDsCopy[@(MPUserIdentityOther7)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther7)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther8]) {
                    if (userIDsCopy[@(MPUserIdentityOther8)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther8)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther9]) {
                    if (userIDsCopy[@(MPUserIdentityOther9)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther9)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther10]) {
                    if (userIDsCopy[@(MPUserIdentityOther10)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther10)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueCustomerId]) {
                    if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                        userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueFacebook]) {
                    if (userIDsCopy[@(MPUserIdentityFacebook)]) {
                        userId = userIDsCopy[@(MPUserIdentityFacebook)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueTwitter]) {
                    if (userIDsCopy[@(MPUserIdentityTwitter)]) {
                        userId = userIDsCopy[@(MPUserIdentityTwitter)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueGoogle]) {
                    if (userIDsCopy[@(MPUserIdentityGoogle)]) {
                        userId = userIDsCopy[@(MPUserIdentityGoogle)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueMicrosoft]) {
                    if (userIDsCopy[@(MPUserIdentityMicrosoft)]) {
                        userId = userIDsCopy[@(MPUserIdentityMicrosoft)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueYahoo]) {
                    if (userIDsCopy[@(MPUserIdentityYahoo)]) {
                        userId = userIDsCopy[@(MPUserIdentityYahoo)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueEmail]) {
                    if (userIDsCopy[@(MPUserIdentityEmail)]) {
                        userId = userIDsCopy[@(MPUserIdentityEmail)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueAlias]) {
                    if (userIDsCopy[@(MPUserIdentityAlias)]) {
                        userId = userIDsCopy[@(MPUserIdentityAlias)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueMPID]) {
                    if (user != nil) {
                        userId = user.userId.stringValue;
                    }
            } else {
                    if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                        userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                    }
            }
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
        
        NSString *userEmail;
        
        if (_configuration[emailIdTypeKey]) {
            NSString *emailIdKey = _configuration[emailIdTypeKey];
            if ([emailIdKey isEqualToString:userIdValueOther]) {
                if (userIDsCopy[@(MPUserIdentityOther)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther2]) {
                if (userIDsCopy[@(MPUserIdentityOther2)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther2)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther3]) {
                if (userIDsCopy[@(MPUserIdentityOther3)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther3)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther4]) {
                if (userIDsCopy[@(MPUserIdentityOther4)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther4)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther5]) {
                if (userIDsCopy[@(MPUserIdentityOther5)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther5)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther6]) {
                if (userIDsCopy[@(MPUserIdentityOther6)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther6)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther7]) {
                if (userIDsCopy[@(MPUserIdentityOther7)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther7)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther8]) {
                if (userIDsCopy[@(MPUserIdentityOther8)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther8)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther9]) {
                if (userIDsCopy[@(MPUserIdentityOther9)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther9)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther10]) {
                if (userIDsCopy[@(MPUserIdentityOther10)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther10)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueEmail]) {
                if (userIDsCopy[@(MPUserIdentityEmail)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityEmail)];
                }
            } else {
                if (userIDsCopy[@(MPUserIdentityEmail)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityEmail)];
                }
            }
        }
        
        if (userEmail) {
            [appboyInstance.user setEmail:userEmail];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
}

#ifdef TARGET_OS_IOS
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0)) {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];

    if (![appboyInstance.notifications handleUserNotificationWithResponse:response withCompletionHandler:^{}]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
    }
    
    return execStatus;
}
#endif

- (NSMutableDictionary *)simplifiedDictionary:(NSDictionary *)originalDictionary {
    __block NSMutableDictionary *transformedDictionary = [[NSMutableDictionary alloc] init];
    
    [originalDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)value;
            NSDate *dateValue = [MPDateFormatter dateFromStringRFC3339:stringValue];
            if (dateValue) {
                transformedDictionary[key] = dateValue;
            } else if ([self isInteger:stringValue]) {
                transformedDictionary[key] = [NSNumber numberWithInteger:[stringValue integerValue]];
            } else if ([self isFloat:stringValue]) {
                transformedDictionary[key] = [NSNumber numberWithFloat:[stringValue floatValue]];
            } else if ([stringValue caseInsensitiveCompare:@"true"] == NSOrderedSame) {
                transformedDictionary[key] = @YES;
            } else if ([stringValue caseInsensitiveCompare:@"false"] == NSOrderedSame) {
                transformedDictionary[key] = @NO;
            }
            else {
                transformedDictionary[key] = stringValue;
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            transformedDictionary[key] = (NSNumber *)value;
        } else if ([value isKindOfClass:[NSDate class]]) {
            transformedDictionary[key] = (NSDate *)value;
        }
    }];
    
    return transformedDictionary;
}

- (BOOL) isInteger:(NSString *)string {
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    if([string hasPrefix:@"-"]) {
        NSString *absoluteString = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSRange r = [absoluteString rangeOfCharacterFromSet: nonNumbers];
        
        return r.location == NSNotFound && absoluteString.length > 0;
    } else {
        NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
        
        return r.location == NSNotFound && string.length > 0;
    }
}

- (BOOL) isFloat:(NSString *)string {
    NSArray *numList = [string componentsSeparatedByString:@"."];
    
    if (numList.count == 2) {
        if ([self isInteger:numList[0]] && [self isInteger:numList[1]]) {
            return true;
        }
    }
    
    return false;
}

- (BOOL) isBoolNumber:(NSNumber *)num {
   CFTypeID boolID = CFBooleanGetTypeID();
   CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num));
   return numID == boolID;
}

- (void)setEnableTypeDetection:(BOOL)enableTypeDetection {
    _enableTypeDetection = enableTypeDetection;
}

@end
