//
//  RawImageWithTips.h
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/29/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@interface RawImageWithTips : NSImageView <LeapListener>
- (id) initWithFrame:(NSRect)frame controller:(LeapController *)controller andImageID:(int)ID;
+ (NSWindow *) createWindow:(NSRect)frame withTitle:(NSString *)title;
@end
