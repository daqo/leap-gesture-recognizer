//
//  ViewController.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import "ViewController.h"
#import "LeapObjectiveC.h"
#import "GeometricTemplateMatcher.h"
#import "UndistortedImageViewWithTips.h"
#import "RawImageWithTips.h"

#define MIN_RECORDING_VELOCITY 250
#define MAX_RECORDING_VELOCITY 30
#define MIN_GESTURE_FRAMES 5
#define MIN_POSE_FRAMES 75
#define DOWNTIME 1
#define REQUIRED_TRAINING_GESTURE_COUNT 8
#define HIT_THRESHOLD 0.65


@implementation ViewController
{
    LeapController *_leapController;
    
    int _secondsLeftForTrainingToStart;
    NSTimer* _threeSecondsTimer;
    
    BOOL _recording;
    BOOL _paused;
    BOOL _recordingPose;
    
    int _frameCount;
    time_t _lastHit;
    int _recordedPoseFrames;
    
    NSString* _trainingGestureName;
    NSMutableArray* _gesture;
    NSMutableDictionary* _gestures;
    NSMutableDictionary* _poses;
    
    GeometricTemplateMatcher* _learner;
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Connected");
    LeapController *_controller = (LeapController *)[notification object];
    [_controller setPolicy:LEAP_POLICY_IMAGES];
    [_controller.config save];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingIsStarted:) name:@"started-recording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingIsStopped:) name:@"stopped-recording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gestureIsDetected:) name:@"gesture-detected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingIsStarted:) name:@"training-started" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingIsCompleted:) name:@"training-complete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trainingGestureIsSaved:) name:@"training-gesture-saved" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GestureIsRecognized:) name:@"gesture-recognized" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GestureIsUnknown:) name:@"gesture-unknown" object:nil];
    
    _leapController = [[LeapController alloc] init];
    [_leapController addListener:self];
    [self pauseFrameTracking];
    
    _gesture = [NSMutableArray array];
    _secondsLeftForTrainingToStart = 4;
    _gestures = [NSMutableDictionary dictionary];
    _poses = [NSMutableDictionary dictionary];
    _learner = [[GeometricTemplateMatcher alloc] init];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (BOOL)isGestureNameNotValid:(NSString*)name {
    return !([name isEqual: @"LEFT"] || [name isEqual: @"RIGHT"] || [name isEqual: @"UP"] || [name isEqual: @"DOWN"] || [name isEqual: @"FORWARD"] || [name isEqual: @"BACK"] || [name isEqual: @"HOVER"]);
}

- (IBAction)addGesture:(id)sender {
    NSString* name = [self.gestureName.stringValue uppercaseString];
    if (![name isEqual: @""])
    {
        if ([self isGestureNameNotValid:name]) {
            self.gestureName.stringValue = @"";
            return;
        }
        
        _trainingGestureName = self.gestureName.stringValue;
        [_gestures setObject:[NSMutableArray array] forKey:_trainingGestureName];
        
        [self pauseFrameTracking];
        _threeSecondsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                      target:self
                                      selector:@selector(startTrainingTimer)
                                      userInfo:nil
                                      repeats:YES];
        [self.makeANewGestureButton setEnabled:FALSE];
        [self.gestureName setEnabled:FALSE];
    }
}

- (void)showTrainingGestureStatus: (NSString* )text {
    self.trainingGestureStatus.stringValue = text;
    [self.trainingGestureStatus setHidden:FALSE];
}

- (void)startTrainingTimer {
    _secondsLeftForTrainingToStart--;
    self.trainingAlert.stringValue = [[NSString alloc] initWithFormat:@"Training will start in %d seconds!", _secondsLeftForTrainingToStart];
    [self.trainingAlert setHidden:FALSE];
    if ( _secondsLeftForTrainingToStart == 0 ) {
        [self showTrainingGestureStatus: [[NSString alloc] initWithFormat:@"Perform %@ gesture or pose %d times", _trainingGestureName, REQUIRED_TRAINING_GESTURE_COUNT]];
        [_threeSecondsTimer invalidate];
        _secondsLeftForTrainingToStart = 4;
        [self.trainingAlert setHidden:TRUE];
        [self startTraining:self.gestureName.stringValue];
    }
}

- (void) recordingIsStarted: (NSNotification *)n {
    
}

- (void) recordingIsStopped: (NSNotification *)n {
    
}

- (void) gestureIsDetected: (NSNotification *)n {
}

- (void) trainingIsStarted: (NSNotification *)n {
    
}

- (void) trainingIsCompleted: (NSNotification *)n {
    [self.makeANewGestureButton setEnabled:TRUE];
    
    NSString* name = [n.userInfo[@"gestureName"] uppercaseString];
    if ([name  isEqual: @"LEFT"]) {
        self.yawLeftGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Left: Set"];
    } else if ([name  isEqual: @"RIGHT"]) {
        self.yawRightGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Right: Set"];
    } else if ([name  isEqual: @"UP"]) {
        self.upGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Up: Set"];
    } else if ([name  isEqual: @"DOWN"]) {
        self.downGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Down: Set"];
    } else if ([name  isEqual: @"FORWARD"]) {
        self.forwardGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Forward: Set"];
    } else if ([name  isEqual: @"BACK"]) {
        self.backGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Back: Set"];
    } else if ([name  isEqual: @"HOVER"]) {
        self.hoverGestureStatus.stringValue = [[NSString alloc] initWithFormat:@"Hover: Set"];
    }
    
    self.trainingGestureStatus.stringValue = @"Learning completed";
    [self.gestureName setEnabled:TRUE];
    self.gestureName.stringValue = @"";
}

unsigned long numberOfTrainingsRequired(unsigned long currentNumber) {
    return REQUIRED_TRAINING_GESTURE_COUNT - currentNumber;
}

- (void) trainingGestureIsSaved: (NSNotification *)n {
    NSString *name = n.userInfo[@"gestureName"];
    unsigned long count = numberOfTrainingsRequired([n.userInfo[@"trainingGesture"] count]);
    [self showTrainingGestureStatus:[[NSString alloc] initWithFormat:@"Perform %@ gesture or pose %ld times", name, count]];
}

- (void) GestureIsRecognized: (NSNotification *)n {
    NSString* name = n.userInfo[@"closestGestureName"];
    self.gestureType.stringValue = [name uppercaseString];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            //Here you returns to main thread.
            self.gestureType.stringValue = @"";
        });
    });
}

- (void) GestureIsUnknown: (NSNotification *)n {
    
}

- (time_t)currentTime
{
    return (time_t) [[NSDate date] timeIntervalSince1970];
}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *aController = (LeapController *)[notification object];
    LeapFrame *frame = [aController frame:0];
    
    self.testLabel.stringValue = [[NSString alloc] initWithFormat:@"%lld", [frame id]];
    
    if (_paused) { return; }
    time_t now = (time_t) [[NSDate date] timeIntervalSince1970];
    if (now - _lastHit < DOWNTIME) { return; }
    
    BOOL isRecordable = [self recordableFrame:frame];
    if (isRecordable) {
        if (!_recording) {
            _recording = TRUE;
            _frameCount = 0;
            @synchronized(self) {
                _gesture = [NSMutableArray array];
            }
            _recordedPoseFrames = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"started-recording" object:self];
        }
        _frameCount++;
        [self recordFrame:frame];
    } else if (_recording) {
        _recording = FALSE;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopped-recording" object:self];
        
        if (_recordingPose || _frameCount >= MIN_GESTURE_FRAMES) {
            
            NSDictionary * userInfo = @{ @"gesture": _gesture, @"frameCount" : @(_frameCount) };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"gesture-detected" object:self userInfo:userInfo];
            
            if (_trainingGestureName) {
                [self saveTrainingGesture:_trainingGestureName withGestureInfo:_gesture withIsPosed:_recordingPose];
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @synchronized(self) {
                        [self recognize:_gesture withFrameCount:_frameCount];
                    }
                });
            }
            _lastHit = [self currentTime];
            _recordingPose = FALSE;
        }
    }
}

- (double)findMaxObjectsVelocity:(LeapHand*)hand {
    LeapVector* palmVelocity = hand.palmVelocity;
    NSMutableArray* objectsVelocity = [NSMutableArray array];
    double palmVelocityValue = fmax(fabs(palmVelocity.x), fmax(fabs(palmVelocity.y), fabs(palmVelocity.z)));
    [objectsVelocity addObject:[NSNumber numberWithDouble:palmVelocityValue]];
    for(LeapFinger* finger in hand.fingers) {
        double tipVelocityValue = fmax(fabs(finger.tipVelocity.x), fmax(fabs(finger.tipVelocity.y), fabs(finger.tipVelocity.z)));
        [objectsVelocity addObject:[NSNumber numberWithDouble:tipVelocityValue]];
    }
    
    return [[objectsVelocity valueForKeyPath:@"@max.self"] doubleValue];
}

- (BOOL)recordableFrame:(LeapFrame*) frame {
    BOOL poseRecordable = FALSE;

    for(LeapHand* hand in frame.hands) {
        double maxObjectVelocityValue = [self findMaxObjectsVelocity:hand];
        
        // We return true if there is a hand moving above the minimum recording velocity
        if (maxObjectVelocityValue >= MIN_RECORDING_VELOCITY) { return true; }
        if (maxObjectVelocityValue <= MAX_RECORDING_VELOCITY) { poseRecordable = TRUE; break; }
    }
    
    if (poseRecordable) {
        _recordedPoseFrames++;
        if (_recordedPoseFrames >= MIN_POSE_FRAMES) {
            _recordingPose = TRUE;
            return TRUE;
        }
    } else {
        _recordedPoseFrames = 0;
    }
    return FALSE; //DAVE: check this line
}

- (void)recordFrame:(LeapFrame*)frame {
    for(LeapHand* hand in frame.hands) {
        [self recordVector:hand.stabilizedPalmPosition];
        for(LeapFinger* finger in hand.fingers) {
            [self recordVector:finger.stabilizedTipPosition];
        };
    };
}

- (void)startTraining:(NSString*)gestureName {
    [self resumeFrameTracking];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"training-started" object:self userInfo:@{ @"gestureName": gestureName}];
}


- (void)saveTrainingGesture:(NSString*)gestureName withGestureInfo:(NSMutableArray*)data withIsPosed:(BOOL)isPose {
    NSMutableArray* dataAssociatedToCurrentGesture = [_gestures objectForKey:gestureName];
    [dataAssociatedToCurrentGesture addObject:data];
    if ([dataAssociatedToCurrentGesture count] == REQUIRED_TRAINING_GESTURE_COUNT) {
        [_gestures setObject:dataAssociatedToCurrentGesture forKey:gestureName]; //DAVE use distribute method here!!
        [_poses setObject:[NSNumber numberWithBool:isPose] forKey:gestureName];
        [self trainAlgorithm:gestureName withTrainingData:dataAssociatedToCurrentGesture];
        _trainingGestureName = nil;
        
        NSDictionary * userInfo = @{ @"gestureName": gestureName, @"trainingGesture": dataAssociatedToCurrentGesture, @"isPose": @(isPose)};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"training-complete" object:self userInfo:userInfo];
    } else {
        NSDictionary * userInfo = @{ @"gestureName": gestureName, @"trainingGesture": dataAssociatedToCurrentGesture };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"training-gesture-saved" object:self userInfo:userInfo];
    }
}

- (void)trainAlgorithm:(NSString*)gestureName withTrainingData:(NSMutableArray*)dataForGestureName {
    /* 
     dataForGestureName is the set of data gathered during training.
     for example if we have REQUIRED_TRAINING_GESTURE_COUNT set to 4, dataForGestureName will comprise 4 arrays.
     each subarray includes different points gathered during each motion.
     in each frame we are recording 6 points (each point has x y z). so each subarray's length will be a multiplication of 6*3.
    */
    NSMutableArray* newData = [NSMutableArray array];
    for (int i = 0; i < [dataForGestureName count]; i++) {
        newData[i] = [_learner process:dataForGestureName[i]]; //each dataForGestureName[i] element is an Array of floats
    }
    [_gestures setObject:newData forKey:gestureName];
}

- (void)recognize:(NSMutableArray*)gesture withFrameCount:(int)frameCount {
    NSMutableDictionary* gestures = _gestures;
    double threshold = HIT_THRESHOLD;
    NSMutableDictionary* allHits = [NSMutableDictionary dictionary];
    
    double hit = 0;
    double bestHit = 0;
    BOOL recognized = FALSE;
    NSString* closestGestureName = nil;
    BOOL recognizingPose = (frameCount == 1); //Single-frame recordings are idenfied as poses
    
    for(NSString* gestureName in gestures) {
        // We don't actually attempt to compare gestures to poses
        if([[_poses objectForKey:gestureName] boolValue] != recognizingPose) {
            hit = 0.0;
        } else {
            /*
             * For each know gesture we generate a correlation value between the parameter gesture and a saved
             * set of training gestures. This correlation value is a numeric value between 0.0 and 1.0 describing how similar
             * this gesture is to the training set.
             */
            hit = [_learner correlate:gestureName withTrainingSet:[gestures objectForKey:gestureName] withCurrentGesture:gesture];
        }
        //Each hit is recorded
        [allHits setValue:[NSNumber numberWithDouble:hit] forKey:gestureName];
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
- (IBAction)updateImage:(id)sender {
    LeapFrame *frame = [_leapController frame:0];
    
//    if (frame.images.count > 0) {
//        LeapImage *rightImage = [frame.images objectAtIndex:1];
//        
//        NSRect rightImageFrame = NSMakeRect(0,0, rightImage.width, rightImage.height);
//        RawImageWithTips *rightImageView = [[RawImageWithTips alloc] initWithFrame:rightImageFrame controller:_leapController andImageID:rightImage.id];
//        [self.frameView addSubview:rightImageView];
//
//    }
    
    if (frame.images.count > 0) {
        LeapImage *leftImage = [frame.images objectAtIndex:0];
        
        NSOpenGLPixelFormatAttribute attrs[] =
        {
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            0
        };
        
        NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        if (pixFmt == nil) {
            NSLog(@"Pixel format creation failed.");
        }
        
        NSSize frameViewSize = self.frameView.frame.size;
        
        NSRect leftImageFrame = NSMakeRect(0,0,frameViewSize.width, frameViewSize.height);
        UndistortedImageViewWithTips *leftUnwarpWithShaderView = [[UndistortedImageViewWithTips alloc] initWithFrame:leftImageFrame pixelFormat:pixFmt andController:_leapController andImageID:leftImage.id];
        [self.frameView addSubview:leftUnwarpWithShaderView];
        [self.frameView setAutoresizesSubviews:YES];
    }

}
@end