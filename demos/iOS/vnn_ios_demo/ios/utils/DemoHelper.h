//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <MetalKit/MetalKit.h>
#import <Accelerate/Accelerate.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import "vnn_kit.h"

#define SCREEN_WIDTH (floor([UIScreen mainScreen].bounds.size.width / 9) * 9)
#define SCREEN_HEIGHT (SCREEN_WIDTH * 16 / 9)
#define ACTUAL_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define ACTUAL_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define FIX_IMAGE_WIDTH (720)
#define FIX_IMAGE_HEIGHT (1280)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define EFFECT_PORTRAITSEGMENTATION 0
#define EFFECT_BEAUTY 1
#define EFFECT_FACEMERGE 2

@interface DemoHelper : NSObject

+ (float)getCpuUsage;
+ (float)getCpuFrequency;
+ (CGImageRef) imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer CPUorGPU:(BOOL)xpu;
+ (NSString *)getDeviceHardwareInfo;
+ (id<MTLTexture>)UIImage2MTLTexture_With_UIImage:(UIImage *)uiimage
                                        MTLDevice:(id<MTLDevice>)mtlDev
                                   MTLTextureType:(MTLTextureType)mtlTexType
                                   MTLPixelFormat:(MTLPixelFormat)mtlPixFormat
                                         IfMipmap:(BOOL)ifMipmap
                                           IfFlip:(BOOL)ifFlip;
+ (UIImage *)scaleToSize_WithUIImage:(UIImage *)img Size:(CGSize)size;

+ (bool)compileShader_With_ShaderHandle:(GLuint *)shader ShadeType:(GLenum)type ShaderContent:(NSString *)content;
+ (GLuint)loadShaders_With_VertexShader:(NSString *)vsPath FragmentShader:(NSString *)fsPath;
+ (bool)linkProgram:(GLuint)program;
+ (bool)createPixelBufferPool:(CVPixelBufferPoolRef *)pool width:(int)width height:(int)height;
+ (void)destroyPixelBufferPool:(CVPixelBufferPoolRef *)pool;
+ (CVPixelBufferRef)imageToYUVPixelBuffer:(UIImage *)image;
+ (NSArray *)getPathList:(NSString *)list_path;
+ (NSString *)getWLANIpAddress;
+ (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img;
+ (void) resizeBilinear_U8_C1_Image:(unsigned char *)src srch:(int)srch srcw: (int)srcw dstImage:(unsigned char *)dst dsth:(int)dsth dstw: (int)dstw;
+ (unsigned char *) allocMaskBy:(const VNN_Image &)faceMask onImage:(const VNN_Image &) frameImg;
+ (void) resizeBilinear_U8_C3_Image:(unsigned char *)src srch:(int)srch srcw: (int)srcw dstImage:(unsigned char *)dst dsth:(int)dsth dstw: (int)dstw;
+ (unsigned char *) allocRGBFaceBy:(const VNN_Image &)faceData onImage:(const VNN_Image &) frameImg;
+ (UIImage *)fixOrientation:(UIImage *)aImage;
+ (UIImage *)resizePad:(UIImage *)oriImage withHeight:(int) h withWidth:(int)w;
+ (void) replaceRGBFaceBy:(const VNN_Image &)faceData refImage:(const VNN_Image &) frameImg onBuffer:(unsigned char *)buffer outputBGRA:(bool)outputBGRA;
@end
