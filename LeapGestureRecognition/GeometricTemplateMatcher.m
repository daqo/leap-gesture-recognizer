//
//  GeometricTemplateMatcher.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/26/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeometricTemplateMatcher.h"

@implementation GeometricTemplateMatcher {
    int _pointCount;
    LeapPoint _origin;
}

- (id) init {
    self = [super init];
    if (self) {
        _origin.x = 0; _origin.y = 0; _origin.z = 0;
        _pointCount = 25;
    }
    return self;
}

- (NSValue*)packStructAsObject:(LeapPoint)pointStruct {
    return [NSValue valueWithBytes:&pointStruct objCType:@encode(LeapPoint)];
}

- (NSMutableArray*)formAs3DPoints:(NSMutableArray*)gesturePoints {
    NSMutableArray* points = [NSMutableArray array];
    int stroke = 1;
    for(int i = 0; i < [gesturePoints count]; i+=3) {
        LeapPoint p;
        p.x = [gesturePoints[i] floatValue];
        p.y = [gesturePoints[i+1] floatValue];
        p.z = [gesturePoints[i+2] floatValue];
        p.stroke = stroke;
        
        [points addObject:[self packStructAsObject:p]];
    }
    return points;
}

- (NSMutableArray*)process: (NSMutableArray* )gesturePoints {
    NSMutableArray* points = [self formAs3DPoints:gesturePoints];
    NSMutableArray* resampledSet = [self resample:points];
    NSMutableArray* scaledSet = [self scale:resampledSet];
    return [self translateToOrigin:scaledSet];
}

- (NSMutableArray*)resample: (NSMutableArray* )gesture {
    int target = _pointCount - 1;
    double interval = [self pathLength:gesture] / target;
    double dist = 0.0;
    NSMutableArray* resampledGesture = [NSMutableArray arrayWithObject:[gesture objectAtIndex:0]];
    
    for(int i = 1; i < [gesture count]; i++) {
        LeapPoint curPoint = [self getLeapPointFromObject:[gesture objectAtIndex:i]];
        LeapPoint prevPoint = [self getLeapPointFromObject:[gesture objectAtIndex:i-1]];
        
        if (curPoint.stroke == prevPoint.stroke) {
            double d = [self euclidianDistance:curPoint withPoint:prevPoint];
            if ((dist + d) >= interval) {
                float ppx = prevPoint.x; float ppy = prevPoint.y; float ppz = prevPoint.z;
                LeapPoint newp = {  (ppx + ((interval - dist) / d) * (curPoint.x - ppx)),
                                    (ppy + ((interval - dist) / d) * (curPoint.y - ppy)),
                                    (ppz + ((interval - dist) / d) * (curPoint.z - ppz)),
                                    curPoint.stroke
                };
                
                [resampledGesture addObject:[self packStructAsObject:newp]];
                //newp will be the next p[i]
                [gesture insertObject:[self packStructAsObject:newp] atIndex:i];
                
                dist = 0.0;
            } else {
                dist += d;
            }
        }
    }
    
    if ([resampledGesture count] != target) {
        NSValue *lastPoint = [gesture objectAtIndex:[gesture count] - 1]; //this is a wrapped point
        [resampledGesture addObject:lastPoint];
    }
    
    return resampledGesture;
}


//Rescale points with shape preservation so that the resulting bounding box will be ⊆ [0..1] × [0..1].
- (NSMutableArray*)scale: (NSMutableArray* )gesture {
    float xMin, xMax, yMin, yMax, zMin, zMax;
    xMin = yMin = zMin = +INFINITY;
    xMax = yMax = zMax = -INFINITY;
    
    for(NSValue* pointObject in gesture) {
        LeapPoint point = [self getLeapPointFromObject:pointObject];
        xMin = fminf(xMin, point.x);
        xMax = fmaxf(xMax, point.x);
        yMin = fminf(yMin, point.y);
        yMax = fmaxf(yMax, point.y);
        zMin = fminf(zMin, point.z);
        zMax = fmaxf(zMax, point.z);
    }
    float scale = fmaxf(xMax - xMin, fmaxf(yMax - yMin, zMax - zMin));
    
    for (int i = 0; i < [gesture count]; i++) {
        LeapPoint oldPoint = [self getLeapPointFromObject:[gesture objectAtIndex:i]];
        LeapPoint newPoint = { (oldPoint.x - xMin)/scale, (oldPoint.y - yMin)/scale, (oldPoint.z - zMin)/scale, oldPoint.stroke };
        [gesture replaceObjectAtIndex:i withObject:[self packStructAsObject:newPoint]];
    }
    return gesture;
}

- (LeapPoint)getLeapPointFromObject:(NSValue*)object {
    LeapPoint point;
    [object getValue:&point];
    return point;
}

- (double)pathLength: (NSMutableArray* )gesture {
    double d = 0.0;
    for(int i = 1; i < [gesture count]; i++) {
        LeapPoint curPoint = [self getLeapPointFromObject:[gesture objectAtIndex:i]];
        LeapPoint prevPoint = [self getLeapPointFromObject:[gesture objectAtIndex:i-1]];
        
        if(curPoint.stroke == prevPoint.stroke) {
            d += [self euclidianDistance:prevPoint withPoint:curPoint];
        }
    }
    return d;
}

- (double)euclidianDistance:(LeapPoint)p1 withPoint:(LeapPoint)p2 {
    double dx = p1.x - p2.x;
    double dy = p1.y - p2.y;
    double dz = p1.z - p2.z;
    
    return sqrt(dx * dx + dy * dy + dz * dz);
}

- (NSMutableArray*)translateToOrigin:(NSMutableArray*)gesture {
    LeapPoint center = [self centroid:gesture];
    for (int i = 0; i < [gesture count]; i++) {
        
        LeapPoint oldPoint;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&oldPoint];
        
        LeapPoint newPoint;
        newPoint.x = (oldPoint.x + _origin.x - center.x);
        newPoint.y = (oldPoint.y + _origin.y - center.y);
        newPoint.z = (oldPoint.z + _origin.z - center.z);
        newPoint.stroke = oldPoint.stroke;
        
        NSValue *newValue = [NSValue valueWithBytes:&newPoint objCType:@encode(LeapPoint)];
        [gesture replaceObjectAtIndex:i withObject:newValue];
        
    }
    return gesture;
}

- (LeapPoint)centroid:(NSMutableArray*)gesture {
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;
    
    for (int i = 0; i < [gesture count]; i++) {
        LeapPoint p;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&p];
        
        x += p.x;
        y += p.y;
        z += p.z;
        
    }
    
    LeapPoint new_p;
    new_p.x = x / [gesture count];
    new_p.y = y / [gesture count];
    new_p.z = z / [gesture count];
    
    return new_p;
}

- (float)correlate:(NSString*)gestureName withTrainingSet:(NSMutableArray*)trainingGestures withCurrentGesture:(NSMutableArray*)gesture {
    gesture = [self process:gesture];
    float nearest = +INFINITY;
    BOOL foundMatch = FALSE;
    float distance;
    
    for(int i = 0; i < [trainingGestures count]; i++) {
        distance = [self match:gesture withTrainingData: [trainingGestures objectAtIndex:i]];
        if (distance < nearest) {
            nearest = distance;
            foundMatch = TRUE;
        }
    }
    
    float hit;
    if (!foundMatch) {
        hit = 0.0;
    } else {
        hit = fabs((nearest - 4.0) / 4); //DAVE make sure it's working correctly
    }
    return hit;
}

- (float)match: (NSMutableArray*)gesture withTrainingData:(NSMutableArray *)data {
    float min = +INFINITY;
    float a = [self gestureDistance:gesture withTrainingGesture:data];
    float b = [self gestureDistance:data withTrainingGesture:gesture];
    float m = fminf(a, b);
    return fminf(min, m);
}

- (float)gestureDistance: (NSMutableArray*)gesture1 withTrainingGesture:(NSMutableArray*)gesture2 {
    NSUInteger len1 = [gesture1 count];
    NSUInteger len2 = [gesture2 count];
    NSMutableArray* matched = [[NSMutableArray alloc] initWithCapacity:len1];
    
    for (int i = 0; i < len1; i++ )
    {
        [matched addObject:[NSNumber numberWithBool:false]];
    }
    
    int index = -1;
    int start = 0; int i = 0;
    
    float sum = 0;
    //do {
    index = -1;
    float min = +INFINITY;
    for (int j = 0; j < len1; j++) {
        if (![matched[j] boolValue]) {
            //if (gesture1[i] == nil || gesture2[j] == nil) { continue; } //DAVE what's this?
            if ( j >= len2 ) { break; }
            
            LeapPoint p1;
            NSValue* value1 = [gesture1 objectAtIndex:i];
            [value1 getValue:&p1];
            
            LeapPoint p2;
            NSValue* value2 = [gesture2 objectAtIndex:j];
            [value2 getValue:&p2];
            
            
            double d = [self euclidianDistance:p1 withPoint:p2];
            if (d < min) { min = d; index = j;}
        }
    }
    if (index != -1) {
        matched[index] = [NSNumber numberWithBool:TRUE];
    }
    sum += (1 - ((i - start + len1) % len1) / len1) * min;
    //i = (i + 1) % len1;
    //} while (i != start);
    
    return sum;
}
@end