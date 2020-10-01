//
//  AuthorizationManager.m
//  LFLiveKitDemo
//
//  Created by Patrick Aubin on 9/22/20.
//  Copyright © 2020 admin. All rights reserved.
//

#import "AuthorizationManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>


@implementation AuthorizationManager

+ (BOOL)checkAuthorizations {
    return [AuthorizationManager isCameraAuthorized] == kAllowedAndDisabled &&
    [AuthorizationManager isMicrophoneAuthorized] == kAllowedAndDisabled;
}

+ (SwitchState)isCameraAuthorized {
    NSString *mediaType2 = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus2 = [AVCaptureDevice authorizationStatusForMediaType:mediaType2];
    if(authStatus2 == AVAuthorizationStatusDenied ||
       authStatus2 == AVAuthorizationStatusRestricted) {
        return kDisallowedAndDisabled;
    } else if (authStatus2 == AVAuthorizationStatusNotDetermined) {
        return kUnknownAndEnabled;
    }
    return kAllowedAndDisabled;
}

+ (SwitchState)isMicrophoneAuthorized {
    NSString *mediaType = AVMediaTypeAudio;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusDenied ||
       authStatus == AVAuthorizationStatusRestricted) {
        return kDisallowedAndDisabled;
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        return kUnknownAndEnabled;
    }
    return kAllowedAndDisabled;
}

+ (SwitchState)isNotificationsAuthorized {
    __block SwitchState authorized = kUnknownAndEnabled;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
            authorized = kDisallowedAndDisabled;
        } else if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
            authorized = kUnknownAndEnabled;
        } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            authorized = kAllowedAndDisabled;
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return authorized;
}

@end
