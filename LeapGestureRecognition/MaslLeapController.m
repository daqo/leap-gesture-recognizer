//
//  MaslLeapController.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import "MaslLeapController.h"

@implementation MaslLeapController
{
    LeapController *controller;
}


- (void)run
{
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    NSLog(@"running");
}

#pragma mark - MaslLeapController Callbacks

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification
{
    //Note: not dispatched when running in a debugger.
    NSLog(@"Disconnected");
}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];
    
    LeapFrame *frame = [aController frame:0];
    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
          [frame id], [frame timestamp], [[frame hands] count],
          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);
}
@end