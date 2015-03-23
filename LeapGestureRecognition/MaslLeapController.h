//
//  MaslLeapController.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#ifndef LeapGestureRecognition_MaslLeapController_h
#define LeapGestureRecognition_MaslLeapController_h

#import <Foundation/Foundation.h>
#import "LeapObjectiveC.h"

@interface MaslLeapController : NSObject<LeapListener>

-(void)run;

@end


#endif
