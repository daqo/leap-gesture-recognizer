//
//  GeometricTemplateMatcher.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/26/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//
struct LeapPoint
{
    double x;
    double y;
    double z;
    int stroke;
};
typedef struct LeapPoint LeapPoint;

@interface GeometricTemplateMatcher : NSObject

- (NSMutableArray*)process: (NSMutableArray* )gesture;
- (double)correlate:(NSString*)gestureName withTrainingSet:(NSMutableArray*)trainingGestures withCurrentGesture:(NSMutableArray*)gesture;

@end