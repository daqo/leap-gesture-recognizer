//
//  OpenGLUtil.h
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/25/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>

@interface OpenGLUtil : NSObject

+ (GLuint) createProgramForContext:(NSOpenGLContext *)context
                     vertexShader:(NSString *)vertexFilePath
                   fragmentShader:(NSString *)fragmentFilePath;

+ (GLuint) createProgramForContext:(NSOpenGLContext *)context
                     vertexShader:(NSString *)vertexFilePath
                   fragmentShader:(NSString *)fragmentFilePath
                   geometryShader:(NSString *)geometryFilePath;

+ (GLuint) bindTextureUnitForContext:(NSOpenGLContext *)context inSlot:(int)textureUnit;

+(void) checkGLError:(NSString *)contextMessage;
@end
