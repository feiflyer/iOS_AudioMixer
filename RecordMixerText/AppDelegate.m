//
//  AppDelegate.m
//  RecordMixerText
//
//  Created by XingTu on 2019/1/28.
//  Copyright © 2019 IXingTu. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
     NSError *error = nil;
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    // our default category -- we change this for conversion and playback appropriately
    [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
//    XThrowIfError((OSStatus)error.code, "couldn't set audio category");
    
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
//    XThrowIfError((OSStatus)error.code, "couldn't set IOBufferDuration");
    
    double hwSampleRate = 44100.0;
    [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
//    XThrowIfError((OSStatus)error.code, "couldn't set preferred sample rate");
    
//    // add interruption handler
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleInterruption:)
//                                                 name:AVAudioSessionInterruptionNotification
//                                               object:sessionInstance];
//
//    // we don't do anything special in the route change notification
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleRouteChange:)
//                                                 name:AVAudioSessionRouteChangeNotification
//                                               object:sessionInstance];
    
    // activate the audio session
    [sessionInstance setActive:YES error:&error];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
