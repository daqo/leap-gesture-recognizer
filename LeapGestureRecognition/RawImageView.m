//
//  RawImageView.m
//  LeapGestureRecognition
//
//  Created by Dave Qorashi on 3/23/15.
//  Copyright (c) 2015 Dave Qorashi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RawImageView.h"

@implementation RawImageView {
    LeapController *_controller;
    NSBitmapImageRep *imgRep;
    int lastWidth;
    int lastHeight;
    int _ID;
}

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
        
        //Only update if size has changed
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
        
        //Copy data from LeapImage to NSBitmapImageRep
        unsigned char * bmpData = [imgRep bitmapData];
        memcpy(bmpData, image.data, image.width * image.height);
        
        //Assign bitmap data to NSImage
        [self.image addRepresentation:imgRep];
    }
}

- (void) dealloc
{
    [_controller removeListener:self];
}
@end
