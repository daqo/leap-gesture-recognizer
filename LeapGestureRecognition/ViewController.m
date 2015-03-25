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
    
    
    BOOL _recording;
    NSMutableArray* _gesture;
    int _frameCount;
    
    
    BOOL _paused;
    int _downtime;
    time_t _lastHit;
    
    int _minRecordingVelocity;
    int _maxRecordingVelocity;
    
    NSMutableArray* _renderableGesture;
    int _recordedPoseFrames;
    
    BOOL _recordingPose;
    int _minGestureFrames;
    int _minPoseFrames;
    
    NSString* _trainingGesture;
    NSMutableDictionary* _gestures;
    int _trainingGestures;
    
    NSMutableDictionary* _poses;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    
    _recording = FALSE;
    _gesture = [NSMutableArray array];
    _frameCount = 0;
    
    _secondsLeftForTrainingToStart = 4;
    _paused = TRUE;
    _downtime = 2;
    _lastHit = 0;
    
    _minRecordingVelocity = 300;
    _maxRecordingVelocity = 30;
    
    _renderableGesture = [NSMutableArray array];
    _recordedPoseFrames = 0;
    
    _recordingPose = FALSE;
    _minGestureFrames = 5;
    _minPoseFrames = 75;
    
    _trainingGesture= Nil;
    _gestures = [NSMutableDictionary dictionary];
    _trainingGestures = 1; //DAVE change this in the final implementation
    
    _poses = [NSMutableDictionary dictionary];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)addGesture:(id)sender {
    if (![self.gestureName.stringValue isEqual: @""])
    {
        _trainingGesture = self.gestureName.stringValue;
        [_gestures setObject:[NSMutableArray array] forKey:_trainingGesture];
        //fire('gesture-created', gestureName, skipTraining);
        NSLog(@"gesture-created");
        _paused = TRUE;
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
        _secondsLeftForTrainingToStart = 4;
        [self.trainingAlert setHidden:TRUE];
        [self startTraining:self.gestureName.stringValue];
    }

}

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


    if (_paused) { return; }
    time_t now = (time_t) [[NSDate date] timeIntervalSince1970];
    if (now - _lastHit < _downtime) { return; }
    
    if ([self recordableFrame:frame]) {
        if (!_recording) {
            
            _recording = TRUE;
            _frameCount = 0;
            _gesture = [NSMutableArray array]; //DAVE what type should _gesture be?
            _renderableGesture = [NSMutableArray array]; //DAVE what type should _renderableGesture be?
            _recordedPoseFrames = 0;
            //fire('started-recording');
            NSLog(@"started-recording");
        }
        
        _frameCount++;
        [self recordFrame:frame withPreviousFrame:[aController frame:1]];
        [self recordRenderableFrame:frame withPreviousFrame:[aController frame:1]];
    } else if (_recording) {
        _recording = FALSE;
        //fire('stopped-recording');
        NSLog(@"stopped-recording");
        
        if (_recordingPose || _frameCount >= _minGestureFrames) {
            //fire('gesture-detected', _gesture, _frameCount);
            NSLog(@"gesture-detected");
            NSString *gestureName = _trainingGesture;
            if (gestureName) {
                [self saveTrainingGesture:gestureName withGestureInfo:_gesture withIsPosed:_recordingPose];
            } else {
                [self recognize:_gesture withFrameCount:_frameCount]; //DAVE what's the criteria for this?
            }
            _lastHit = (time_t) [[NSDate date] timeIntervalSince1970];
            _recordingPose = FALSE; //DAVE when does _recordingPose become TRUE?
        }
    }
}

- (BOOL)recordableFrame:(LeapFrame*) frame {
    NSArray *hands = [frame hands];
    BOOL poseRecordable = FALSE;

    for(int i = 0; i < [hands count]; i++) {
        LeapHand *hand = hands[i];
        LeapVector* palmVelocity = hand.palmVelocity;
        float palmVelocityValue = fmax(fabs(palmVelocity.x), fmax(fabs(palmVelocity.y), fabs(palmVelocity.z)));
        /*
         * We return true if there is a hand moving above the minimum recording velocity
         */
        if (palmVelocityValue >= _minRecordingVelocity) { return true; }
        if (palmVelocityValue <= _maxRecordingVelocity) { poseRecordable = TRUE; break; }
        NSArray *fingers = [hand fingers];
        for (int j = 0; j < [fingers count]; j++) {
            LeapFinger *finger = fingers[j];
            LeapVector* tipVelocity = finger.tipVelocity;
            float tipVelocityValue = fmax(fabs(tipVelocity.x), fmax(fabs(tipVelocity.y), fabs(tipVelocity.z)));
            /*
             * Or if there's a finger tip moving above the minimum recording velocity
             */
            if (tipVelocityValue >= _minRecordingVelocity) { return true; }
            if (tipVelocityValue <= _maxRecordingVelocity) { poseRecordable = TRUE; break; }
        }
    }
    
    if (poseRecordable) {
        _recordedPoseFrames++;
        if (_recordedPoseFrames >= _minPoseFrames) {
            _recordingPose = TRUE;
            return TRUE;
        }
    } else {
        _recordedPoseFrames = 0;
    }
    return FALSE; //DAVE: check this line
}

- (void)recordFrame:(LeapFrame*)frame withPreviousFrame:(LeapFrame*)prevFrame {
    NSArray *hands = frame.hands;
    
    for (int i = 0; i < [hands count]; i++) {
        LeapHand* hand = hands[i];
        [self recordVector:hand.stabilizedPalmPosition];
        NSArray* fingers = hand.fingers;
        
        for (int j = 0; j < [fingers count];  j++) {
            LeapFinger* finger = fingers[j];
            [self recordVector:finger.stabilizedTipPosition];
        };
    };
}

- (void)startTraining:(NSString*)gestureName {
    _paused = FALSE;
    //fire('training-started', gestureName);
    NSLog(@"training-started");
}

- (void)recordRenderableFrame:(LeapFrame*)frame withPreviousFrame:(LeapFrame*)prevFrame {
    NSLog(@"recordRenderableFrame needs to be implemented.");
}

- (void)saveTrainingGesture:(NSString*)gestureName withGestureInfo:(NSMutableArray*)gesture withIsPosed:(BOOL)isPose {
    NSMutableArray* contents = [_gestures objectForKey:gestureName];
    [contents addObject:_gesture];
    if ([contents count] == _trainingGestures) {
        [_gestures setObject:contents forKey:gestureName]; //DAVE use distribute method here!!
        [_poses setObject:[NSNumber numberWithBool:isPose] forKey:gestureName];
        _trainingGesture = Nil;
        [self trainAlgorithm:gestureName withTrainingData:contents];
        
    }
}


- (void)trainAlgorithm:(NSString*)gestureName withTrainingData:(NSMutableArray*)data {
    
}

- (void)recognize:(NSMutableArray*)gesture withFrameCount:(int)framecCount {
    
}

- (void)recordValue:(float)value {
    NSNumber *num =[NSNumber numberWithFloat:value];
    [_gesture addObject:num];
}

- (void)recordVector:(LeapVector*) vector {
    [self recordValue:vector.x];
    [self recordValue:vector.y];
    [self recordValue:vector.z];
}
    
/////////
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
