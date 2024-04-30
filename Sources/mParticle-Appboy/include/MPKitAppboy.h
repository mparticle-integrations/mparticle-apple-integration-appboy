#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
    #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle.h"
    #import "mParticle_Apple_SDK-Swift.h"
#endif

#if defined(__has_include) && __has_include(<BrazeKit/BrazeKit-Swift.h>)
    #import <BrazeKit/BrazeKit-Swift.h>
#else
    #import BrazeKit-Swift.h
#endif


@interface MPKitAppboy : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

#if TARGET_OS_IOS
+ (void)setInAppMessageControllerDelegate:(nonnull id)delegate;
+ (void)setShouldDisableNotificationHandling:(BOOL)isDisabled;
#endif
+ (void)setURLDelegate:(nonnull id)delegate;
+ (void)setBrazeInstance:(nonnull id)instance;
+ (void)setBrazeLocationProvider:(nonnull id)instance;
+ (void)setBrazeTrackingPropertyAllowList:(nonnull NSSet<BRZTrackingProperty*> *)allowList;
@end
