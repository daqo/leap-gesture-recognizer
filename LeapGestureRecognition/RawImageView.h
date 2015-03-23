//
//  RawImageView.h
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#ifndef LeapGestureRecognition_RawImageView_h
#define LeapGestureRecognition_RawImageView_h

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@interface RawImageView : NSImageView <LeapListener>
- (id) initWithFrame:(NSRect)frame controller:(LeapController *)controller andImageID:(int)ID;
@end


#endif
