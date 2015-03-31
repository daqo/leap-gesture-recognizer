//
//  GeometricTemplateMatcher.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/26/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeometricTemplateMatcher.h"

@implementation GeometricTemplateMatcher

- (id) init {
    self = [super init];
    if (self) {
        _origin.x = 0; _origin.y = 0; _origin.z = 0;
        _pointCount = 25;
    }
    return self;
}

- (NSMutableArray*)process: (NSMutableArray* )gesture {
    NSMutableArray* points = [NSMutableArray array];
    int stroke = 1;
    for(int i = 0; i < [gesture count]; i+=3) {
        struct LeapPoint p;
        p.x = [gesture[i] floatValue];
        p.y = [gesture[i+1] floatValue];
        p.z = [gesture[i+2] floatValue];
        p.stroke = stroke;
        
        
        //adding point struct value to a NSMutableArray
        NSValue *value = [NSValue valueWithBytes:&p objCType:@encode(struct LeapPoint)];
        [points addObject:value];
    }
    
    NSMutableArray* resampledSet = [self resample:points];
    NSMutableArray* scaledSet = [self scale:resampledSet];
    return [self translateTo:scaledSet];
}

- (NSMutableArray*)resample: (NSMutableArray* )gesture {
    int target = _pointCount - 1;
    double interval = [self pathLength:gesture] / target;
    float dist = 0.0;
    NSMutableArray* resamplesGesture = [NSMutableArray array];
    
    //Add first element to the newly created array
    NSValue *point = [gesture objectAtIndex:0];
    [resamplesGesture addObject:point];
    
    for(int i = 1; i < [gesture count]; i++) {
        NSValue *value;
        
        struct LeapPoint curPoint;
        value = [gesture objectAtIndex:i];
        [value getValue:&curPoint];
        
        struct LeapPoint prevPoint;
        value = [gesture objectAtIndex:i-1];
        [value getValue:&prevPoint];
        
        if (curPoint.stroke == prevPoint.stroke) {
            float d = [self distance:curPoint withPoint:prevPoint];
            if ((dist + d) >= interval) {
                float ppx = prevPoint.x; float ppy = prevPoint.y; float ppz = prevPoint.z;
                struct LeapPoint newp;
                newp.x = (ppx + ((interval - dist) / d) * (curPoint.x - ppx));
                newp.y = (ppy + ((interval - dist) / d) * (curPoint.y - ppy));
                newp.z = (ppz + ((interval - dist) / d) * (curPoint.z - ppz));
                newp.stroke = curPoint.stroke;
                
                ///
                NSValue *value = [NSValue valueWithBytes:&newp objCType:@encode(struct LeapPoint)];
                [resamplesGesture addObject:value];
                ///
                [gesture insertObject:value atIndex:i];
                
                dist = 0.0;
            } else {
                dist += d;
            }
        }
    }
    
    if ([resamplesGesture count] != target) {
        NSValue *p = [gesture objectAtIndex:[gesture count] - 1]; //this is a wrapped point
        
        [resamplesGesture addObject:p];
        
    }
    
    return resamplesGesture;
}

- (NSMutableArray*)scale: (NSMutableArray* )gesture {
    float minX = +INFINITY; float maxX = -INFINITY;
    float minY = +INFINITY; float maxY = -INFINITY;
    float minZ = +INFINITY; float maxZ = -INFINITY;
    
    for(int i = 0; i < [gesture count]; i++) {
        struct LeapPoint point;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&point];
        
        minX = fminf(minX, point.x);
        minY = fminf(minY, point.y);
        minZ = fminf(minZ, point.z);
        
        maxX = fmaxf(maxX, point.x);
        maxY = fmaxf(maxY, point.y);
        maxZ = fmaxf(maxZ, point.z);
        
    }
    
    float size = fmaxf(maxX - minX, fmaxf(maxY - minY, maxZ - minZ));
    for (int i = 0; i < [gesture count]; i++) {
        struct LeapPoint oldPoint;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&oldPoint];
        
        struct LeapPoint newPoint;
        newPoint.x = (oldPoint.x - minX)/size;
        newPoint.y = (oldPoint.y - minY)/size;
        newPoint.z = (oldPoint.z - minZ)/size;
        newPoint.stroke = oldPoint.stroke;
        NSValue *newValue = [NSValue valueWithBytes:&newPoint objCType:@encode(struct LeapPoint)];
        [gesture replaceObjectAtIndex:i withObject:newValue];
    }
    return gesture;
}

- (double)pathLength: (NSMutableArray* )gesture {
    float d = 0.0;
    NSValue* value;
    for(int i = 1; i < [gesture count]; i++) {
        struct LeapPoint curPoint;
        value = [gesture objectAtIndex:i];
        [value getValue:&curPoint];
        
        struct LeapPoint prevPoint;
        value = [gesture objectAtIndex:i-1];
        [value getValue:&prevPoint];
        
        if(curPoint.stroke == prevPoint.stroke) {
            d += [self distance:prevPoint withPoint:curPoint];
        }
    }
    return d;
}

- (float)distance:(struct LeapPoint)p1 withPoint:(struct LeapPoint)p2 {
    float dx = p1.x - p2.x;
    float dy = p1.y - p2.y;
    float dz = p1.z - p2.z;
    
    return sqrt(dx * dx + dy * dy + dz * dz);
}

- (NSMutableArray*)translateTo:(NSMutableArray*)gesture {
    struct LeapPoint center = [self centroid:gesture];
    for (int i = 0; i < [gesture count]; i++) {
        
        struct LeapPoint oldPoint;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&oldPoint];
        
        struct LeapPoint newPoint;
        newPoint.x = (oldPoint.x + _origin.x - center.x);
        newPoint.y = (oldPoint.y + _origin.y - center.y);
        newPoint.z = (oldPoint.z + _origin.z - center.z);
        newPoint.stroke = oldPoint.stroke;
        
        NSValue *newValue = [NSValue valueWithBytes:&newPoint objCType:@encode(struct LeapPoint)];
        [gesture replaceObjectAtIndex:i withObject:newValue];
        
    }
    return gesture;
}

- (struct LeapPoint)centroid:(NSMutableArray*)gesture {
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;
    
    for (int i = 0; i < [gesture count]; i++) {
        struct LeapPoint p;
        NSValue* value = [gesture objectAtIndex:i];
        [value getValue:&p];

        x += p.x;
        y += p.y;
        z += p.z;
        
    }
    
    struct LeapPoint new_p;
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
                
                struct LeapPoint p1;
                NSValue* value1 = [gesture1 objectAtIndex:i];
                [value1 getValue:&p1];
                
                struct LeapPoint p2;
                NSValue* value2 = [gesture2 objectAtIndex:j];
                [value2 getValue:&p2];
                
                
                float d = [self distance:p1 withPoint:p2];
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