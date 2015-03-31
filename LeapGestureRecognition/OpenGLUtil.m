//
//  OpenGLUtil.m
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/25/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import "OpenGLUtil.h"

@implementation OpenGLUtil

+ (GLuint) createProgramForContext:(NSOpenGLContext *)context
                     vertexShader:(NSString *)vertexFilePath
                   fragmentShader:(NSString *)fragmentFilePath
{
    return [OpenGLUtil createProgramForContext:context vertexShader:vertexFilePath fragmentShader:fragmentFilePath geometryShader:nil];
}

+ (GLuint) createProgramForContext:(NSOpenGLContext *)context
                     vertexShader:(NSString *)vertexFilePath
                   fragmentShader:(NSString *)fragmentFilePath
                   geometryShader:(NSString *)geometryFilePath
{
    GLint program = glCreateProgram();

    NSString *vertexShaderSource = [NSString stringWithContentsOfFile:vertexFilePath encoding:NSUTF8StringEncoding error:NULL];
    const char *vertexShaderSourceCString = [vertexShaderSource cStringUsingEncoding:NSUTF8StringEncoding];

    NSString *fragmentShaderSource = [NSString stringWithContentsOfFile:fragmentFilePath encoding:NSUTF8StringEncoding error:NULL];
    const char *fragmentShaderSourceCString = [fragmentShaderSource cStringUsingEncoding:NSUTF8StringEncoding];

    [context makeCurrentContext];
    [self checkGLError:@"make current context"];

    GLint compileSuccess;
    NSLog(@"Open GLSL version: %s",glGetString(GL_SHADING_LANGUAGE_VERSION));

    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourceCString, NULL);
    glCompileShader(fragmentShader);

    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLint logLength;
        glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLength);
        if(logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(fragmentShader, logLength, &logLength, log);
            NSLog(@"Fragment Shader compile log:\n%s", log);
            free(log);
        }
        exit(1);
    }

    glAttachShader(program, fragmentShader);

    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSourceCString, NULL);
    glCompileShader(vertexShader);

    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLint logLength;
        glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
        if(logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
            NSLog(@"Vertex Shader compile log:\n%s", log);
            free(log);
        }
        exit(1);
    }

    glAttachShader(program, vertexShader);

    if (geometryFilePath) {
        NSString *geometryShaderSource = [NSString stringWithContentsOfFile:geometryFilePath encoding:NSUTF8StringEncoding error:NULL];
        const char *geometryShaderSourceCString = [geometryShaderSource cStringUsingEncoding:NSUTF8StringEncoding];

        GLuint geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
        glShaderSource(geometryShader, 1, &geometryShaderSourceCString, NULL);
        glCompileShader(geometryShader);

        glGetShaderiv(geometryShader, GL_COMPILE_STATUS, &compileSuccess);
        if (compileSuccess == GL_FALSE) {
            GLint logLength;
            glGetShaderiv(geometryShader, GL_INFO_LOG_LENGTH, &logLength);
            if(logLength > 0) {
                GLchar *log = (GLchar *)malloc(logLength);
                glGetShaderInfoLog(geometryShader, logLength, &logLength, log);
                NSLog(@"Geometry Shader compile log:\n%s", log);
                free(log);
            }
            exit(1);
        }

        glAttachShader(program, geometryShader);
    }
    
    glLinkProgram(program);
    [self checkGLError:@"Link programs"];

    return program;
}

+ (GLuint) bindTextureUnitForContext:(NSOpenGLContext *)context inSlot:(int)textureUnit
{
    [context makeCurrentContext];

    GLuint texture;
    glActiveTexture(GL_TEXTURE0 + textureUnit);

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
        [OpenGLUtil checkGLError:@"Bind texture"];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    return texture;
}


+(void) checkGLError:(NSString *)contextMessage {
        GLenum err = glGetError();
 
        while(err!=GL_NO_ERROR) {
                NSString *error;

                switch(err) {
                        case GL_INVALID_OPERATION:      error=@"INVALID_OPERATION";      break;
                        case GL_INVALID_ENUM:           error=@"INVALID_ENUM";           break;
                        case GL_INVALID_VALUE:          error=@"INVALID_VALUE";          break;
                        case GL_OUT_OF_MEMORY:          error=@"OUT_OF_MEMORY";          break;
                        case GL_INVALID_FRAMEBUFFER_OPERATION:  error=@"INVALID_FRAMEBUFFER_OPERATION";  break;
                }
                NSLog(@"GL_%@ at %@",error, contextMessage);
                err = glGetError();
        }
}

@end
