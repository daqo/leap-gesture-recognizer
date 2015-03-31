//
//  UndistortedImageViewWithTips.m
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/29/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import "UndistortedImageViewWithTips.h"
#import "OpenGLUtil.h"

@implementation UndistortedImageViewWithTips
 {
    GLint swapInterval;
    GLuint imageProgram;
    GLuint tipProgram;
    GLuint vao;
    GLuint vao2;
    GLuint tipBO;
    GLuint raw;
    GLuint distortion;
    GLint rawImageLocation;
    GLint distortionImageLocation;

    bool deviceChanged;
    bool wasFlipped;

    int _ID;
    LeapController *_controller;
    NSTimer *renderTimer;
}

static const float cameraOffset = 20;

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)format andController:(LeapController *)controller andImageID:(int)ID
{
    self = [self initWithFrame:frame pixelFormat:format];
    if(self)
    {
        swapInterval = 1;
        deviceChanged = true;
        wasFlipped = true;
        [[self superview]setAutoresizingMask:NSViewWidthSizable];
        _ID = ID;
        _controller = controller;
        [_controller addListener:self]; //for onConnect and onDeviceChange events

        //Use an NSTimer for gfx rather than the onFrame to avoid overdriving the graphics
        renderTimer = [NSTimer timerWithTimeInterval:0.001   //a 1ms time interval
                                target:self
                                selector:@selector(timerFired:)
                                userInfo:nil
                                repeats:YES];
 
        [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                    forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                    forMode:NSEventTrackingRunLoopMode]; //Ensure timer fires during resize
    }
    return self;
}

- (void)timerFired:(id)sender
{
    [self setNeedsDisplay:YES];
}

- (void)onConnect:(NSNotification *)notification
{
    LeapController *controller = (LeapController *)[notification object];
    [controller setPolicyFlags:LEAP_POLICY_IMAGES];
}

- (void)onDeviceChange:(NSNotification *)notification
{
    NSLog(@"Device change."); //Need to check image size and reload distortion map
    deviceChanged = true;
}

- (void) prepareOpenGL
{
  NSLog(@"Open GL version: %s", glGetString(GL_VERSION));

  [super prepareOpenGL];
  [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

  //Setup image texture shaders
  imageProgram  = [OpenGLUtil createProgramForContext:[self openGLContext]
                                vertexShader:[[NSBundle mainBundle]pathForResource:@"vertexImage" ofType:@"vsh"]
                              fragmentShader:[[NSBundle mainBundle] pathForResource:@"fragmentImage" ofType:@"fsh"]];

  raw = [OpenGLUtil bindTextureUnitForContext:[self openGLContext] inSlot:0];
  distortion = [OpenGLUtil bindTextureUnitForContext:[self openGLContext] inSlot:1];

  distortionImageLocation = glGetUniformLocation(imageProgram, "distortion");
  glProgramUniform1i(imageProgram, distortionImageLocation, GL_TEXTURE1);

  //Set up shaders for drawing finger/tool tips
  tipProgram = [OpenGLUtil createProgramForContext:[self openGLContext]
                                vertexShader:[[NSBundle mainBundle] pathForResource:@"vertexTips" ofType:@"vsh"]
                              fragmentShader:[[NSBundle mainBundle] pathForResource:@"fragmentTips" ofType:@"fsh"]
                              geometryShader:[[NSBundle mainBundle] pathForResource:@"geometryTips" ofType:@"gsh"]];

  [self createScene];
}


- (void) createScene
{
    [[self openGLContext] makeCurrentContext];
    [OpenGLUtil checkGLError:@"make context current"];

    //A textured quad
    const int attributeCount = 5;
    const GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
         1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
         1.0f,  1.0f, 0.0f, 1.0f, 1.0f,
        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f
    };

    const GLubyte triangles[] = {
        0, 1, 2,
        2, 3, 0
    };

    glUseProgram(imageProgram);

    glGenVertexArrays (1, &vao);
    glBindVertexArray (vao);

    GLuint vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray (0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, attributeCount * sizeof(GLfloat), 0);

    GLuint texAttrib = glGetAttribLocation(imageProgram, "inTexCoord");
    glEnableVertexAttribArray(texAttrib);
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, attributeCount * sizeof(GLfloat), (const GLvoid *) (3 * sizeof(GLfloat)));

    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(triangles), triangles, GL_STATIC_DRAW);

    glUseProgram(tipProgram);

    glGenVertexArrays (1, &vao2);
    glBindVertexArray (vao2);

    //Buffer for finger/tool tip points
    glBindVertexArray (vao2);
    glGenBuffers(1, &tipBO);
    glBindBuffer(GL_ARRAY_BUFFER, tipBO);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), 0);

    [OpenGLUtil checkGLError:@"Error creating scene"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    for(LeapDevice *device in _controller.devices)
    {
        if (device.isStreaming && wasFlipped != device.isFlipped) {
            deviceChanged = true;
        }
    }
    LeapFrame *frame = [_controller frame:0];
    if (frame.images.count > 0) {
        LeapImage *image = [frame.images objectAtIndex:_ID];
        [self renderImage:image];
        [self renderTips:frame.pointables onImage:image];
        [self renderPalmPosition:frame.hands onImage:image];
        [[self openGLContext] flushBuffer];
    }

}

- (void) renderImage:(LeapImage *)image
{
    [[self openGLContext] makeCurrentContext];

    //Upload distortion map to GPU texture if device has changed
    if (deviceChanged) {
        glBindTexture(GL_TEXTURE_2D, distortion);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RG32F, 64, 64, 0, GL_RG, GL_FLOAT, image.distortion);
        [OpenGLUtil checkGLError:@"Error loading distortion map"];
    }

    //Upload image data to GPU texture
    glBindTexture(GL_TEXTURE_2D, raw);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, image.width, image.height, 0, GL_RED, GL_UNSIGNED_BYTE, image.data);
    [OpenGLUtil checkGLError:@"Error loading raw image data"];

    glBindVertexArray(vao);
    glUseProgram(imageProgram);

    glUniform1i(rawImageLocation, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, raw);

    glUniform1i(distortionImageLocation, 1);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, distortion);

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, (void*)0);
    [OpenGLUtil checkGLError:@"Error trying to draw triangles"];

}

- (void) renderPalmPosition:(NSArray *)hands onImage:(LeapImage *)image {
    GLfloat tips[hands.count * 3];
    int palmCoordinates = 0;
    for (LeapHand *hand in hands){
        LeapVector *palm = hand.palmPosition;
        float hSlope = -(palm.x + cameraOffset * (2 * image.id - 1))/palm.y;
        float vSlope = -palm.z/palm.y;
        
        tips[palmCoordinates++] = (hSlope * image.rayScaleX + image.rayOffsetX) * 2 - 1;
        tips[palmCoordinates++] = (vSlope * image.rayScaleY + image.rayOffsetY) * 2 - 1;
        tips[palmCoordinates++] = 0.0;
    }
    
    glBindVertexArray(vao2);
    glUseProgram(tipProgram);
    glBufferData(GL_ARRAY_BUFFER, sizeof(tips), tips, GL_DYNAMIC_DRAW);
    
    glDrawArrays(GL_POINTS, 0, (int)hands.count);
    [OpenGLUtil checkGLError:@"Error trying to draw palm position"];
}

- (void) renderTips:(NSArray *)pointables onImage:(LeapImage *)image
{
    GLfloat tips[pointables.count * 3];
    int tipCoordinates = 0;
    for (LeapPointable *pointable in pointables){
        LeapVector *tip = pointable.tipPosition;
        float hSlope = -(tip.x + cameraOffset * (2 * image.id - 1))/tip.y;
        float vSlope = -tip.z/tip.y;

        tips[tipCoordinates++] = (hSlope * image.rayScaleX + image.rayOffsetX) * 2 - 1;
        tips[tipCoordinates++] = (vSlope * image.rayScaleY + image.rayOffsetY) * 2 - 1;
        tips[tipCoordinates++] = 0.0;
    }

    glBindVertexArray(vao2);
    glUseProgram(tipProgram);
    glBufferData(GL_ARRAY_BUFFER, sizeof(tips), tips, GL_DYNAMIC_DRAW);

    glDrawArrays(GL_POINTS, 0, (int)pointables.count);
    [OpenGLUtil checkGLError:@"Error trying to draw finger tips"];
}

- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    float screenWidth = (float)[_window frame].size.width;
    float screenHeight = (float)[_window frame].size.height;
    glViewport(0,0,screenWidth/2,screenHeight);
    if (_ID == 0) {
        [super setFrame:NSMakeRect(0, 0, screenWidth/2, screenHeight)];
    } else{
        [super setFrame:NSMakeRect(screenWidth/2, 0, screenWidth/2, screenHeight)];
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
