//
//  AuthorizationManager.h
//  LFLiveKitDemo
//
//  Created by Patrick Aubin on 9/22/20.
//  Copyright © 2020 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kAllowedAndDisabled,
    kUnknownAndEnabled,
    kDisallowedAndDisabled
} SwitchState;

@interface AuthorizationManager : NSObject

+ (BOOL)checkAuthorizations;
+ (SwitchState)isCameraAuthorized;
+ (SwitchState)isMicrophoneAuthorized;
+ (SwitchState)isNotificationsAuthorized;

@end

NS_ASSUME_NONNULL_END
