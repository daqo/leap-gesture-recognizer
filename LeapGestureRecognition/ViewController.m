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
#import "GeometricTemplateMatcher.h"

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
    int _requiredTrainingGesturesCount;
    
    NSMutableDictionary* _poses;
    GeometricTemplateMatcher* _learner;
    
    float _hitThreshold;
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
    NSLog(@"Disconnected");
}

//////

- (void) recordingIsStarted: (NSNotification *)n {
    
}

- (void) recordingIsStopped: (NSNotification *)n {
    
}

- (void) gestureIsDetected: (NSNotification *)n {
    self.gestureRecognitionStatus.stringValue = [[NSString alloc] initWithFormat:@"Gesture is Recognized!"];
    [self.gestureRecognitionStatus setHidden:FALSE];
}

- (void) gestureIsCreated: (NSNotification *)n {
    
}

- (void) trainingIsStarted: (NSNotification *)n {
    
}

- (void) trainingIsCompleted: (NSNotification *)n {
    [self.numberOfTrainingLeftForCurrentGesture setHidden:TRUE];
    [self.makeANewGestureButton setEnabled:TRUE];
    
    NSString* name = n.userInfo[@"gestureName"];
    if ([name  isEqual: @"left"]) {
        self.yawLeftGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Left: Set"];
    } else if ([name  isEqual: @"right"]) {
        self.yawRightGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Right: Set"];
    } else if ([name  isEqual: @"up"]) {
        self.upGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Up: Set"];
    } else if ([name  isEqual: @"down"]) {
        self.downGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Down: Set"];
    } else if ([name  isEqual: @"forward"]) {
        self.forwardGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Forward: Set"];
    } else if ([name  isEqual: @"back"]) {
        self.backGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Back: Set"];
    } else if ([name  isEqual: @"hover"]) {
        self.hoverGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Hover: Set"];
    }
    
    //@{ @"gestureName": gestureName, @"trainingGesture": contents, @"isPose": @(isPose)};

}

- (void) trainingGestureIsSaved: (NSNotification *)n {
    NSString* name = n.userInfo[@"gestureName"];
    unsigned long count = _requiredTrainingGesturesCount - [n.userInfo[@"trainingGesture"] count];
    self.numberOfTrainingLeftForCurrentGesture.stringValue = [[NSString alloc] initWithFormat:@"Perform %@ gesture or pose %ld times", name, count];

    [self.numberOfTrainingLeftForCurrentGesture setHidden:FALSE];
}

- (void) GestureIsRecognized: (NSNotification *)n {
    NSString* name = n.userInfo[@"closestGestureName"];
    NSLog(@"%@", name);
}

- (void) GestureIsUnknown: (NSNotification *)n {
    
}
///////

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingIsStarted:) name:@"started-recording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingIsStopped:) name:@"stopped-recording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gestureIsDetected:) name:@"gesture-detected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gestureIsCreated:) name:@"gesture-created" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingIsStarted:) name:@"training-started" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingIsCompleted:) name:@"training-complete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingGestureIsSaved:) name:@"training-gesture-saved" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GestureIsRecognized:) name:@"gesture-recognized" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GestureIsUnknown:) name:@"gesture-unknown" object:nil];
    
    controller = [[LeapController alloc] init];
    [controller addListener:self];
    
    _recording = FALSE;
    _gesture = [NSMutableArray array];
    _frameCount = 0;
    
    _secondsLeftForTrainingToStart = 4;
    [self pauseFrameTracking];
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
    _requiredTrainingGesturesCount = 10; //DAVE change this in the final implementation
    
    _poses = [NSMutableDictionary dictionary];
    _learner = [[GeometricTemplateMatcher alloc] init];
    
    _hitThreshold = 0.80;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)addGesture:(id)sender {
    NSString* name = self.gestureName.stringValue;
    if (![name isEqual: @""])
    {
        if (!([name isEqual: @"left"] || [name isEqual: @"right"] || [name isEqual: @"up"] || [name isEqual: @"down"] || [name isEqual: @"forward"] || [name isEqual: @"back"] || [name isEqual: @"hover"])) {
            //the name is not valid
            self.gestureName.stringValue = @"";
            return;
        }
        
        _trainingGesture = self.gestureName.stringValue;
        [_gestures setObject:[NSMutableArray array] forKey:_trainingGesture];
        
        NSDictionary * userInfo = @{ @"trainingGesture" : _trainingGesture };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"gesture-created" object:self userInfo:userInfo];
        
        [self pauseFrameTracking];
        _threeSecondsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                               target:self
                               selector:@selector(startTrainingTimer)
                               userInfo:nil
                               repeats:YES];
        [self.makeANewGestureButton setEnabled:FALSE];
    }
}

- (void)startTrainingTimer {
    _secondsLeftForTrainingToStart--;
    self.trainingAlert.stringValue = [[NSString alloc] initWithFormat:@"Training will start in %d seconds!", _secondsLeftForTrainingToStart];
    [self.trainingAlert setHidden:FALSE];
    if ( _secondsLeftForTrainingToStart == 0 ) {
        ////
        self.numberOfTrainingLeftForCurrentGesture.stringValue = [[NSString alloc] initWithFormat:@"Perform %@ gesture or pose %d times", _trainingGesture, _requiredTrainingGesturesCount];
        [self.numberOfTrainingLeftForCurrentGesture setHidden:FALSE];
        ////
        [_threeSecondsTimer invalidate];
        _secondsLeftForTrainingToStart = 4;
        [self.trainingAlert setHidden:TRUE];
        [self startTraining:self.gestureName.stringValue];
        
    }

}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];
    LeapFrame *frame = [aController frame:0];
    
    self.testLabel.stringValue = [[NSString alloc] initWithFormat:@"%lld", [frame id]];
    [self updateImageFromFrame:frame];
    
    ///// LeapTrainer Code

    if (_paused) { return; }
    time_t now = (time_t) [[NSDate date] timeIntervalSince1970];
    if (now - _lastHit < _downtime) { return; }
    
    BOOL isRecordable = [self recordableFrame:frame];
    if (isRecordable) {
        if (!_recording) {
            _recording = TRUE;
            _frameCount = 0;
            _gesture = [NSMutableArray array]; //DAVE what type should _gesture be?
            _renderableGesture = [NSMutableArray array]; //DAVE what type should _renderableGesture be?
            _recordedPoseFrames = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"started-recording" object:self];
        }
        
        _frameCount++;
        [self recordFrame:frame withPreviousFrame:[aController frame:1]];
        [self recordRenderableFrame:frame withPreviousFrame:[aController frame:1]];
    } else if (_recording) {
        _recording = FALSE;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopped-recording" object:self];
        
        if (_recordingPose || _frameCount >= _minGestureFrames) {
            
            NSDictionary * userInfo = @{ @"gesture": _gesture, @"frameCount" : @(_frameCount) };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"gesture-detected" object:self userInfo:userInfo];
            
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
    [self resumeFrameTracking];
     NSDictionary * userInfo = @{ @"gestureName": gestureName};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"training-started" object:self userInfo:userInfo];
}

- (void)recordRenderableFrame:(LeapFrame*)frame withPreviousFrame:(LeapFrame*)prevFrame {
//    NSLog(@"recordRenderableFrame needs to be implemented.");
}

- (void)saveTrainingGesture:(NSString*)gestureName withGestureInfo:(NSMutableArray*)gesture withIsPosed:(BOOL)isPose {
    NSMutableArray* contents = [_gestures objectForKey:gestureName];
    [contents addObject:gesture];
    if ([contents count] == _requiredTrainingGesturesCount) {
        [_gestures setObject:contents forKey:gestureName]; //DAVE use distribute method here!!
        [_poses setObject:[NSNumber numberWithBool:isPose] forKey:gestureName];
        _trainingGesture = nil;
        [self trainAlgorithm:gestureName withTrainingData:contents];
        
        NSDictionary * userInfo = @{ @"gestureName": gestureName, @"trainingGesture": contents, @"isPose": @(isPose)};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"training-complete" object:self userInfo:userInfo];
    } else {
        NSDictionary * userInfo = @{ @"gestureName": gestureName, @"trainingGesture": contents };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"training-gesture-saved" object:self userInfo:userInfo];
    }
}

- (void)trainAlgorithm:(NSString*)gestureName withTrainingData:(NSMutableArray*)data {
    /* 
     data is the set of data gathered during training.
     for example if we have _requiredTrainingGesturesCount set to 4, data will comprise 4 arrays.
     each subarray has different points gathered during each motion.
     in each frame we are recording 6 points (each point ha x y z). so each subarray's length will be a multiplication of 6*3.
    */
    NSMutableArray* newData = [NSMutableArray array];
    for (int i = 0; i < [data count]; i++) {
        newData[i] = [_learner process:data[i]];
    }
    [_gestures setObject:newData forKey:gestureName];
    
}

- (void)recognize:(NSMutableArray*)gesture withFrameCount:(int)framecCount {
    NSMutableDictionary* gestures = _gestures;
    float threshold = _hitThreshold;
    NSMutableDictionary* allHits = [NSMutableDictionary dictionary];
    
    float hit = 0;
    float bestHit = 0;
    BOOL recognized = FALSE;
    NSString* closestGestureName = nil;
    BOOL recognizingPose = (framecCount == 1);
    
    for(NSString* gestureName in gestures) {
        if([[_poses objectForKey:gestureName] boolValue] != recognizingPose) {
            hit = 0.0;
        } else {
            hit = [_learner correlate:gestureName withTrainingSet:[gestures objectForKey:gestureName] withCurrentGesture:gesture];
        }
        [allHits setValue:[NSNumber numberWithFloat:hit] forKey:gestureName];
        if (hit >= threshold) { recognized = TRUE; }
        if (hit > bestHit) { bestHit = hit; closestGestureName = gestureName; }
    }
    
    if (recognized) {
        NSDictionary * userInfo = @{ @"bestHit" : [NSNumber numberWithFloat:bestHit], @"closestGestureName" : closestGestureName, @"allHits" : allHits };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"gesture-recognized" object:self userInfo:userInfo];
    } else {
        NSDictionary * userInfo = @{ @"allHits" : allHits };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"gesture-unknown" object:self userInfo:userInfo];
    }
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

- (void)resumeFrameTracking {
    _paused = FALSE;
    self.isTrackingPaused.stringValue = [[NSString alloc] initWithFormat:@"Tracking: In progress"];
}

- (void)pauseFrameTracking {
    _paused = TRUE;
    self.isTrackingPaused.stringValue = [[NSString alloc] initWithFormat:@"Tracking: Paused"];
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
