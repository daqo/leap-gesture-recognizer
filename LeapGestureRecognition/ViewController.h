//
//  ViewController.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextField *testLabel;
@property (weak) IBOutlet NSImageView *lImageView;
@property (weak) IBOutlet NSTextField *gestureName;
@property (weak) IBOutlet NSTextField *yawLeftGestureStatus;
@property (weak) IBOutlet NSTextField *yawRightGestureStatus;
@property (weak) IBOutlet NSTextField *hoverGestureStatus;
@property (weak) IBOutlet NSTextField *upGestureStatus;
@property (weak) IBOutlet NSTextField *downGestureStatus;
@property (weak) IBOutlet NSTextField *forwardGestureStatus;
@property (weak) IBOutlet NSTextField *backGestureStatus;
@property (weak) IBOutlet NSTextField *trainingAlert;

@end

