//
//  ViewController.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import "ViewController.h"
#import "LeapObjectiveC.h"
#import "RawImageView.h"

@implementation ViewController
{
    LeapController *controller;
    
    int _secondsLeftForTrainingToStart;
    
    NSTimer* _threeSecondsTimer;
    BOOL _paused;
    int _downtime;
    time_t _lastHit;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    
    _secondsLeftForTrainingToStart = 4;
    _paused = TRUE;
    _downtime = 2;
    _lastHit = Nil;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)addGesture:(id)sender {
    if (![self.gestureName.stringValue  isEqual: @""])
    {
        _threeSecondsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                               target:self
                               selector:@selector(startTrainingTimer)
                               userInfo:nil
                               repeats:YES];
    }
}

- (void)startTrainingTimer {
    _secondsLeftForTrainingToStart--;
    self.trainingAlert.stringValue = [[NSString alloc] initWithFormat:@"Training will start in %d seconds!", _secondsLeftForTrainingToStart];
    [self.trainingAlert setHidden:FALSE];
    if ( _secondsLeftForTrainingToStart == 0 ) {
        [_threeSecondsTimer invalidate];
        _secondsLeftForTrainingToStart = 3;
         [self.trainingAlert setHidden:TRUE];
    }

}


#pragma mark - Leap Controller Callbacks

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController setPolicy:LEAP_POLICY_IMAGES];
    [aController.config save];
    
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
    
//    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
//          [frame id], [frame timestamp], [[frame hands] count],
//          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);
//    
    self.testLabel.stringValue = [[NSString alloc] initWithFormat:@"%lld", [frame id]];
    [self updateImageFromFrame:frame];


//    if (_paused) { return; }
//    time_t now = (time_t) [[NSDate date] timeIntervalSince1970];
//    if (now - _lastHit < _downtime) { return; }
//    
//    if (_recordableFrame(frame, _minRecordingVelocity, _maxRecordingVelocity)) {
//        
//    }
    
}


- (void)updateImageFromFrame:(LeapFrame *)frame
{
    if (frame.images.count > 0) {
        LeapImage *image = [frame.images objectAtIndex:0];
        
        NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                             pixelsWide:image.width
                                                             pixelsHigh:image.height
                                                             bitsPerSample:8
                                                             samplesPerPixel:1
                                                             hasAlpha:NO
                                                             isPlanar:NO
                                                             colorSpaceName:NSCalibratedWhiteColorSpace
                                                             bitmapFormat:0
                                                             bytesPerRow:image.width
                                                             bitsPerPixel:8];
        
        NSImage *nsimage = [[NSImage alloc] initWithSize:NSMakeSize(image.width, image.height)];
        
        unsigned char * bmpData = [imgRep bitmapData];
        memcpy(bmpData, image.data, image.width * image.height);
        
        [nsimage addRepresentation:imgRep];
        
        [self.lImageView setImage:nsimage];

    }
    
}

@end
