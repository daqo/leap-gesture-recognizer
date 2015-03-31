//
//  ViewController.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <math.h>
#import <float.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextField *testLabel;
@property (weak) IBOutlet NSTextField *gestureName;
@property (weak) IBOutlet NSTextField *yawLeftGestureStatus;
@property (weak) IBOutlet NSTextField *yawRightGestureStatus;
@property (weak) IBOutlet NSTextField *hoverGestureStatus;
@property (weak) IBOutlet NSTextField *upGestureStatus;
@property (weak) IBOutlet NSTextField *downGestureStatus;
@property (weak) IBOutlet NSTextField *forwardGestureStatus;
@property (weak) IBOutlet NSTextField *backGestureStatus;
@property (weak) IBOutlet NSTextField *trainingAlert;
@property (weak) IBOutlet NSButton *makeANewGestureButton;
@property (weak) IBOutlet NSTextField *isTrackingPaused;
@property (weak) IBOutlet NSTextField *trainingGestureStatus;
@property (weak) IBOutlet NSView *frameView;
@property (weak) IBOutlet NSTextField *gestureType;


@end

