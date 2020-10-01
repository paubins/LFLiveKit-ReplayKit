//
//  ViewController.m
//  LFLiveKitDemo
//
//  Created by admin on 16/8/30.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <LFLiveKit.h>
#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "PermissionsViewController.h"
#import "AuthorizationManager.h"

inline static NSString *formatedSpeed(float bytes, float elapsed_milli) {
    if (elapsed_milli <= 0) {
        return @"N/A";
    }
    if (bytes <= 0) {
        return @"0 KB/s";
    }
    float bytes_per_sec = ((float)bytes) * 1000.f /  elapsed_milli;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000 / 1000];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}


@interface ViewController () <LFLiveSessionDelegate, RPBroadcastControllerDelegate, RPBroadcastActivityViewControllerDelegate>
@property (nonatomic, strong) LFLiveSession *session;
@property (nonatomic, strong) UIView *testView;
@property (weak, nonatomic) IBOutlet UITextField *streamLocationTextField;
@property (weak, nonatomic) IBOutlet UIButton *startStreamButton;
@property (weak, nonatomic) IBOutlet UIButton *viewStream;
@property (nonatomic, strong) RPBroadcastController *broadcastController;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *streamActivityLoader;
@property (weak, nonatomic) IBOutlet RPSystemBroadcastPickerView *broadcastButton;
@property (strong, nonatomic) PermissionsViewController *permissionsViewController;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkStreamLink];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![AuthorizationManager checkAuthorizations]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        self.permissionsViewController = [sb instantiateViewControllerWithIdentifier:@"PermissionsViewController"];
        self.permissionsViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:self.permissionsViewController animated:YES completion:^{
            NSLog(@"shown permissions");
        }];
    }
}

#pragma mark -- Getter Setter
- (LFLiveSession *)session {
    if (_session == nil) {
        
        LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_High];
        audioConfiguration.numberOfChannels = 1;
        LFLiveVideoConfiguration *videoConfiguration;
        
        videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High2 outputImageOrientation:UIInterfaceOrientationLandscapeRight];
        
        videoConfiguration.autorotate = YES;
        
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.paubins"];
        NSString *shouldMirror = [userDefaults valueForKey:@"shouldMirror"];
        if (shouldMirror == nil) {
            [userDefaults setValue:@"0" forKey:@"shouldMirror"];
        } else if ([shouldMirror isEqualToString:@"1"]) {
            videoConfiguration.mirror = YES;
        } else {
            videoConfiguration.mirror = NO;
        }
        
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration captureType:LFLiveInputMaskAll];
        
        _session.delegate = self;
        _session.showDebugInfo = YES;
        
    }
    return _session;
}


- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    switch (state) {
        case LFLiveReady:
            NSLog(@"未连接");
            break;
        case LFLivePending:
            NSLog(@"连接中");
            break;
        case LFLiveStart:
            NSLog(@"已连接");
            break;
        case LFLiveError:
            NSLog(@"连接错误");
            break;
        case LFLiveStop:
            NSLog(@"未连接");
            break;
        default:
            break;
    }
}

- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    NSString *speed = formatedSpeed(debugInfo.currentBandwidth, debugInfo.elapsedMilli);
    NSLog(@"speed:%@", speed);
}

- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"errorCode: %lu", (unsigned long)errorCode);
}

- (IBAction)startStream:(id)sender {
    NSString *streamURL = @"rtmp://live-sfo.twitch.tv/app/live_548605499_G0ldfV1VLQqHQHdjYzOgI4NXJTEIIj";
    self.streamLocationTextField.hidden = NO;
    [self.streamActivityLoader startAnimating];
    [self startLive];
}

- (void)perpare:(NSString *)streamURL {
    LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
    // /直播推流地址
    stream.url = streamURL;
    self.streamLocationTextField.text = stream.url;
    [self.session startLive:stream];
    [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
}

- (void)statrButtonClick:(UIButton *)sender {
    if ([[RPScreenRecorder sharedRecorder] isRecording]) {
        NSLog(@"Recording, stop record");
        if (@available(iOS 11.0, *)) {
            [self.session stopLive];
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"stopCaptureWithHandler:%@", error.localizedDescription);
                } else {
                    NSLog(@"CaptureWithHandlerStoped");
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    } else {
        if (@available(iOS 11.0, *)) {
            NSLog(@"start Recording");
            [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
//                NSLog(@"bufferTyped:%ld", (long)bufferType);
                switch (bufferType) {
                    case RPSampleBufferTypeVideo:
                        [self.session pushVideoBuffer:sampleBuffer];
                        break;
                    case RPSampleBufferTypeAudioMic:
                        [self.session pushAudioBuffer:sampleBuffer];
                        break;
                        
                    default:
                        break;
                }
                if (error) {
                    NSLog(@"startCaptureWithHandler:error:%@", error.localizedDescription);
                }
            } completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"completionHandler:error:%@", error.localizedDescription);
                }
            }];
        } else {
            // Fallback on earlier versions
        }
        
    }
}



#pragma mark -
#pragma mark Extension

- (void)startLive {
// 如果需要mic，需要打开x此项
    [[RPScreenRecorder sharedRecorder] setMicrophoneEnabled:YES];
    
    if (![RPScreenRecorder sharedRecorder].isRecording) {
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"RPBroadcast err %@", [error localizedDescription]);
            }
            broadcastActivityViewController.delegate = self;
            broadcastActivityViewController.modalPresentationStyle = UIModalPresentationPopover;
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                broadcastActivityViewController.popoverPresentationController.sourceRect = self.testView.frame;
                broadcastActivityViewController.popoverPresentationController.sourceView = self.testView;
            }
            [self presentViewController:broadcastActivityViewController animated:YES completion:nil];
        }];
    } else {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop Live?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self stopLive];
        }];
        UIAlertAction *cancle = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:ok];
        [alert addAction:cancle];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}
- (void)stopLive {
    [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"finishBroadcastWithHandler:%@", error.localizedDescription);
        }
        
    }];
}
- (IBAction)openStream:(id)sender {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.paubins"];
    NSString *streamToken = [userDefaults valueForKey:@"streamToken"];
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:]];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [NSString stringWithFormat:@"https://wideshotapp.com/hls/%@/index.m3u8", streamToken];
    
    [self.viewStream setTitle:@"Copied!" forState:UIControlStateNormal];
    
    if (self.timer == nil) {
        [NSTimer scheduledTimerWithTimeInterval:2.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.viewStream setTitle:@"Copy Stream Link" forState:UIControlStateNormal];
                self.timer = nil;
            });
        }];
    }
}

- (void)checkStreamLink {
    [self.streamActivityLoader startAnimating];
    [self checkStream:^(BOOL isStreaming){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.paubins"];
            if (isStreaming) {
                self.viewStream.hidden = NO;
            } else {
                self.viewStream.hidden = YES;
                [self.streamActivityLoader stopAnimating];
                [userDefaults setValue:nil forKey:@"streamToken"];
            }
        });
    }];
}

- (IBAction)mirrorToggled:(id)sender {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.paubins"];
    
    if([sender isOn]){
        NSLog(@"Switch is ON");
        [userDefaults setValue:@"1" forKey:@"shouldMirror"];
    } else{
        NSLog(@"Switch is OFF");
        [userDefaults setValue:@"0" forKey:@"shouldMirror"];
    }
}

- (void)checkStream:(void (^)(BOOL))completionBlock {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.paubins"];
    
    NSString *userID = [userDefaults valueForKey:@"userID"];
    if (!userID) {
        return;
    }
    
    NSError *error;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"https://www.wideshotapp.com/checkStream"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [request setHTTPMethod:@"POST"];
    
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys:
                             userID, @"userID",
                         nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSError *newError;
            NSMutableDictionary *innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&newError];
            if ([innerJson[@"streaming"] isEqualToString:@"false"]) {
                completionBlock(NO);
            } else {
                completionBlock(YES);
            }
        }
    }];

    [postDataTask resume];
}


#pragma mark - Broadcasting
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *) broadcastActivityViewController
       didFinishWithBroadcastController:(RPBroadcastController *)broadcastController
                                  error:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.streamLocationTextField.hidden = YES;
        [self.streamActivityLoader stopAnimating];
    });

    
    [broadcastActivityViewController dismissViewControllerAnimated:YES
                                                        completion:nil];
    NSLog(@"BundleID %@", broadcastController.broadcastExtensionBundleID);
    self.broadcastController = broadcastController;
    self.broadcastController.delegate = self;
    if (error) {
        NSLog(@"BAC: %@ didFinishWBC: %@, err: %@",
              broadcastActivityViewController,
              broadcastController,
              error);
        return;
    }

    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"-----start success----");
            // 这里可以添加camerPreview
        } else {
            NSLog(@"startBroadcast:%@",error.localizedDescription);
        }
    }];
    
}


// Watch for service info from broadcast service
- (void)broadcastController:(RPBroadcastController *)broadcastController
       didUpdateServiceInfo:(NSDictionary <NSString *, NSObject <NSCoding> *> *)serviceInfo {
    NSLog(@"didUpdateServiceInfo: %@", serviceInfo);
    
    
}

// Broadcast service encountered an error
- (void)broadcastController:(RPBroadcastController *)broadcastController
         didFinishWithError:(NSError *)error {
    NSLog(@"didFinishWithError: %@", error);
}

- (void)broadcastController:(RPBroadcastController *)broadcastController didUpdateBroadcastURL:(NSURL *)broadcastURL {
    NSLog(@"---didUpdateBroadcastURL: %@",broadcastURL);
}

@end
