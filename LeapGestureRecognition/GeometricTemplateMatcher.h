//
//  GeometricTemplateMatcher.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/26/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//
struct LeapPoint
{
    float x;
    float y;
    float z;
    int stroke;
};

@interface GeometricTemplateMatcher : NSObject  {
    int _pointCount;
    struct LeapPoint _origin;
}

- (NSMutableArray*)process: (NSMutableArray* )gesture;
- (float)correlate:(NSString*)gestureName withTrainingSet:(NSMutableArray*)trainingGestures withCurrentGesture:(NSMutableArray*)gesture;


@end