//
//  RawImageWithTips.m
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/29/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import "RawImageWithTips.h"

@implementation RawImageWithTips {
    LeapController *_controller;
    NSBitmapImageRep *imgRep;
    int lastWidth;
    int lastHeight;
    int _ID;
}

static const float cameraOffset = 20;

- (id) initWithFrame:(NSRect)frame controller:(LeapController *)controller andImageID:(int)ID
{
    self = [super initWithFrame:frame];
    if (self) {
        _ID = ID;
        _controller = controller;
        [controller addListener:self];
    }
    return self;
}

- (void)onFrame:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    LeapFrame *frame = [_controller frame:0];
    if(frame.images.count > 0)
    {
        LeapImage *image = [frame.images objectAtIndex:_ID];
        if(frame.images.count > 0)
        {
            LeapImage *image = [frame.images objectAtIndex:_ID];

            if (imgRep == nil || image.width != lastWidth || image.height != lastHeight) {

                imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
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

                self.image = [[NSImage alloc] initWithSize:NSMakeSize(image.width, image.height)];
                lastWidth = image.width;
                lastHeight = image.height;
            }

            //Draw a circle on each tip
            for (LeapPointable *pointable in frame.pointables){
                LeapVector *tip = pointable.tipPosition;
                float hSlope = -(tip.x + cameraOffset * (2 * image.id - 1))/tip.y;
                float vSlope = -tip.z/tip.y;

                LeapVector *pixel = [image warp:[[LeapVector alloc] initWithX:hSlope y:vSlope z:0.0]];

                NSBezierPath *tipMarker = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(pixel.x - 5, pixel.y - 5, 10, 10)];
                [[[NSColor yellowColor] colorWithAlphaComponent:0.5] set];
                [tipMarker fill];
            }
            
            for (LeapHand *hand in frame.hands){
                LeapVector *palm = hand.palmPosition;
                float hSlope = -(palm.x + cameraOffset * (2 * image.id - 1))/palm.y;
                float vSlope = -palm.z/palm.y;
                
                LeapVector *pixel = [image warp:[[LeapVector alloc] initWithX:hSlope y:vSlope z:0.0]];
                
                NSBezierPath *palmMarker = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(pixel.x - 5, pixel.y - 5, 10, 10)];
                [[[NSColor yellowColor] colorWithAlphaComponent:0.5] set];
                [palmMarker fill];

            }


        }
        //Copy data from LeapImage to NSBitmapImageRep
        unsigned char * bmpData = [imgRep bitmapData];
        memcpy(bmpData, image.data, image.width * image.height);

        //Assign bitmap data to NSImage
        [self.image addRepresentation:imgRep];
    }
}

//Utility function to create a window
+ (NSWindow *) createWindow:(NSRect)frame withTitle:(NSString *)title
{
    NSUInteger styleMask =    NSResizableWindowMask | NSClosableWindowMask | NSTitledWindowMask;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    NSWindow * window =  [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:false];
    [window setTitle:title];
    return window;
}

- (void) dealloc
{
    [_controller removeListener:self];
}
@end
