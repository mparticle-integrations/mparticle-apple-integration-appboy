//
//  MPKitAppboy.h
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

#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

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


@interface MPKitAppboy : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

+ (void)setInAppMessageControllerDelegate:(nonnull id<ABKInAppMessageControllerDelegate>)delegate;

@end
