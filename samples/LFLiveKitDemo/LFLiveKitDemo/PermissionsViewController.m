//
//  PermissionsViewController.m
//  LFLiveKitDemo
//
//  Created by Patrick Aubin on 9/21/20.
//  Copyright © 2020 admin. All rights reserved.
//

#import "PermissionsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>
#import "AuthorizationManager.h"


@interface PermissionsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UISwitch *enableCameraButton;
@property (weak, nonatomic) IBOutlet UISwitch *enableMicrophoneButton;
@property (weak, nonatomic) IBOutlet UISwitch *enablePushNotifications;

@end

@implementation PermissionsViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self checkContinueButton];
}

- (IBAction)toggleCameraPermissions:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
      // do your logic
    } else if(authStatus == AVAuthorizationStatusDenied){
      // denied
    } else if(authStatus == AVAuthorizationStatusRestricted){
      // restricted, normally won't happen
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
      // not determined?!
      [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if(granted){
            NSLog(@"Granted access to %@", mediaType);
        } else {
            NSLog(@"Not granted access to %@", mediaType);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkContinueButton];
        });
      }];
    } else {
      // impossible, unknown authorization status
    }
}

- (IBAction)enableMicrophonPermissions:(id)sender {
    NSString *mediaType = AVMediaTypeAudio;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
      // do your logic
    } else if(authStatus == AVAuthorizationStatusDenied){
      // denied
    } else if(authStatus == AVAuthorizationStatusRestricted){
      // restricted, normally won't happen
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
      // not determined?!
      [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if(granted){
            NSLog(@"Granted access to %@", mediaType);
        } else {
            NSLog(@"Not granted access to %@", mediaType);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkContinueButton];
        });
      }];
    } else {
      // impossible, unknown authorization status
    }
}

- (IBAction)enablePushNotifications:(id)sender {
    UNUserNotificationCenter *current = UNUserNotificationCenter.currentNotificationCenter;
    [current requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkContinueButton];
        });
    }];
}

- (IBAction)continueButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"dismissing permissions view");
    }];
}

- (void)checkContinueButton {
    [self processSwitch:self.enableCameraButton switchState:[AuthorizationManager isCameraAuthorized]];
    [self processSwitch:self.enableMicrophoneButton switchState:[AuthorizationManager isMicrophoneAuthorized]];
    [self processSwitch:self.enablePushNotifications switchState:[AuthorizationManager isNotificationsAuthorized]];
    self.continueButton.enabled = [AuthorizationManager isCameraAuthorized] == kAllowedAndDisabled &&
        [AuthorizationManager isMicrophoneAuthorized] == kAllowedAndDisabled;
}

- (void)processSwitch:(UISwitch *)permissionsSwitch switchState:(SwitchState)switchState  {
    if (switchState == kAllowedAndDisabled) {
        [permissionsSwitch setOn:YES animated:YES];
        permissionsSwitch.enabled = NO;
    } else if (switchState == kDisallowedAndDisabled) {
        [permissionsSwitch setOn:NO animated:YES];
        permissionsSwitch.enabled = NO;
    } else {
        [permissionsSwitch setOn:NO animated:YES];
        permissionsSwitch.enabled = YES;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
