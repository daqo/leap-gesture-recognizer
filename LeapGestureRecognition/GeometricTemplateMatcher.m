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
//    int _pointCount;
}

- (id) init {
    self = [super init];
    if (self) {
//        _pointCount = 25;
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
//    int target = _pointCount - 1;
    NSUInteger target = [gesture count];
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
        LeapPoint oldPoint = [self getLeapPointFromObject:gesture[i]];
        LeapPoint newPoint = {  (oldPoint.x - center.x),
                                (oldPoint.y - center.y),
                                (oldPoint.z - center.z),
                                oldPoint.stroke
                             };
        [gesture replaceObjectAtIndex:i withObject:[self packStructAsObject:newPoint]];
    }
    return gesture;
}

- (LeapPoint)centroid:(NSMutableArray*)gesture {
    LeapPoint center = { 0.0, 0.0, 0.0 };
    
    for (NSValue* pointObject in gesture) {
        LeapPoint p = [self getLeapPointFromObject:pointObject];
        center.x += p.x;
        center.y += p.y;
        center.z += p.z;
    }
    center.x /= [gesture count];
    center.y /= [gesture count];
    center.z /= [gesture count];
    return center;
}

- (double)correlate:(NSString*)gestureName withTrainingSet:(NSMutableArray*)trainingGestures withCurrentGesture:(NSMutableArray*)gesture {
    gesture = [self process:gesture];
    double score = +INFINITY;
    BOOL foundMatch = FALSE;
    double distance;
    
    for(NSMutableArray* dataset in trainingGestures) {
        distance = [self greedyCloudMatch:gesture withTrainingData: dataset];
        if (score > distance) {
            score = distance;
            foundMatch = TRUE;
        }
    }
    
    double hit;
    if (!foundMatch) {
        hit = 0.0;
    } else {
//        hit = fabs((score - 4.0) / 4);
        hit = fmax(fabs((4.0 - score) / 4.0), 0.0);
    }
    return hit;
}

- (double)greedyCloudMatch: (NSMutableArray*)gesture withTrainingData:(NSMutableArray *)data {
    double e = 0.5;
    int step = floor(pow([gesture count], 1 - e));
    double min = +INFINITY;
    NSUInteger gestureCount = [gesture count];
    for (int i = 0; i < [gesture count]; i+=step ) {
        double d1 = [self cloudDistance:gesture withTrainingGesture:data withCount:gestureCount withStartIndex:i];
        double d2 = [self cloudDistance:data withTrainingGesture:gesture withCount:gestureCount withStartIndex:i];
        min = fmin(fmin(d1, d2), min);
    }
    return min;
}

- (double)cloudDistance: (NSMutableArray*)points withTrainingGesture:(NSMutableArray*)tmpl withCount:(NSUInteger)count withStartIndex: (int)start {
    NSMutableArray* matched = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++ )
    {
        [matched addObject:[NSNumber numberWithBool:false]];
    }
    double sum = 0;
    
    int i = start;
    int index = -1; //Invalid index
    
    do {
        double min = +INFINITY;
        for (int j = 0; j < count; j++) {
            if (![matched[j] boolValue]) {
                if ((j >= [tmpl count]) || i>=[points count]) { break; }
                
                LeapPoint p1 = [self getLeapPointFromObject:points[i]];
                LeapPoint p2 = [self getLeapPointFromObject:tmpl[j]];
                double d = [self euclidianDistance:p1 withPoint:p2];
                if (d < min) {
                    min = d;
                    index = j;
                }
            }
        }
        
        if (index != -1) {
            matched[index] = [NSNumber numberWithBool:TRUE];
        }
        double weight = 1 - ((i - start + count) % count) / (double)count;
        sum += weight * min;
        i = (i + 1) % count;
    } while (i != start);
    
    return sum;
}
@end