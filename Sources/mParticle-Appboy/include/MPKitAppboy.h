#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

@class Appboy;

typedef void(^BrazeConfigurationBlock)(Appboy *_Nonnull brazeInstance) NS_SWIFT_NAME(BrazeConfigurationHandler);

@interface MPKitAppboy : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

@property (class, strong, nonatomic, nullable) NSDictionary *brazeOptions;

+ (void)configureBrazeInstanceWithBlock:(nonnull BrazeConfigurationBlock)configurationBlock
    NS_SWIFT_NAME(configureBrazeInstance(configurationHandler:));

+ (void)setInAppMessageControllerDelegate:(nonnull id)delegate
    DEPRECATED_MSG_ATTRIBUTE("Configure with a block instead");
+ (void)setURLDelegate:(nonnull id)delegate;

@end
