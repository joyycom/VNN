//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "OSXDemoHelper.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <string>
#include <vector>

@implementation MyAnimator

- (void)animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSView *bottomView = fromViewController.view;
    NSView *topView = viewController.view;
    [topView setWantsLayer:YES];
    [topView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    [topView setAlphaValue:0];
    [bottomView addSubview:topView];
    [topView setFrame:bottomView.frame];
    
    [NSAnimationContext
     runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:2];
        [[bottomView animator] setAlphaValue:0];
        [[topView animator] setAlphaValue:1];
    }
     completionHandler:nil];
}

- (void)animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSView *bottomView = fromViewController.view;
    NSView *topView = viewController.view;
    [topView setWantsLayer:YES];
    [topView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    topView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [NSAnimationContext
     runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:2];
        [[bottomView animator] setAlphaValue:1];
        [[topView animator] setAlphaValue:0];
    }
     completionHandler:^{ [topView removeFromSuperview]; }];
}

@end


@implementation OSXDemoHelper

+ (CVPixelBufferRef)CreateCVPixelBufferRefFromNSImageRGBA:(NSImage *)image
{
    CVPixelBufferRef buffer = NULL;
    
    size_t width = [image size].width;
    size_t height = [image size].height;
    size_t bitsPerComponent = 8;
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, k32BGRAPixelFormat, (__bridge CFDictionaryRef)d, &buffer);
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *rasterData = CVPixelBufferGetBaseAddress(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGContextRef ctxt = CGBitmapContextCreate(rasterData, width, height, bitsPerComponent, bytesPerRow, cs, (CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    if(ctxt == NULL){
        NSLog(@"could not create context");
        return NULL;
    }
    
    // draw
    NSGraphicsContext *nsctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsctxt];
    [image compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
    [NSGraphicsContext restoreGraphicsState];
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    CFRelease(ctxt);
    
    return buffer;
}

+ (NSImage *)U8RGBABufferToNSImage:(const unsigned char*)buffer
                        withHeight:(const int)height
                         withWidth:(const int)width{
    size_t bufferLength = width * height * 4;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    NSAssert(colorSpaceRef, @"Error allocating color space");
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    NSSize imageSize = {.height = height/1.0f, .width = width/1.0f};
    
    NSImage* image = [[NSImage alloc] initWithCGImage:iref size: imageSize];
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    return image;
}

+ (void)saveNSImage:(NSImage *)image atPath:(NSString *)path {
    
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];
    
    NSDictionary *empty = [[NSDictionary alloc] init];
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:empty];
    [pngData writeToFile:path atomically:YES];
}

+(void) drawTextToNSImage: (CGContextRef) context
                 WithText: (std::vector<std::string>) textVec
                 FontSize: (CGFloat) fontSize
                    FontR: (CGFloat) r
                    FontG: (CGFloat) g
                    FontB: (CGFloat) b
                    FontX: (CGFloat) x
                    FontY: (CGFloat) y
{
    CGContextSelectFont (context, "Helvetica-Bold", fontSize, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode (context, kCGTextFill);
    CGContextSetRGBFillColor (context, r, g, b, 1);
    for(int i = 0; i < textVec.size(); i++){
        std::string& text = textVec[i];
        if(text.length() == 0){
            continue;
        }
        float line_y = y - fontSize * i;
        CGContextShowTextAtPoint (context, x, line_y, text.c_str(), text.length());
    }
}

@end

void convertRGBToRGBA(VnnU8BufferPtr rgbbuffer, VnnU8BufferPtr rgbabuffer, const size_t n_pixiel){
    unsigned char* rgb_ptr = rgbbuffer.get()->data;
    unsigned char* rgba_ptr = rgbabuffer.get()->data;
    if(rgb_ptr == nullptr || rgba_ptr == nullptr){
        return;
    }

    for(size_t i = 0; i < n_pixiel; i++){
        rgba_ptr[4*i] = rgb_ptr[3*i];
        rgba_ptr[4*i + 1] = rgb_ptr[3*i + 1];
        rgba_ptr[4*i + 2] = rgb_ptr[3*i + 2];
        rgba_ptr[4*i + 3] = 255;
    }
}

void reverseMask(VnnU8BufferPtr buffer, const size_t n_byte){
    unsigned char* ptr = buffer.get()->data;

    for(size_t i = 0; i < n_byte; i++){
        *ptr = 255 - *ptr;
        ptr++;
    }
}

void tileGrayToBGRA(unsigned char* gray_ptr, unsigned char* bgra_ptr, const size_t n_pixel){
    for(size_t i = 0; i < n_pixel; i++){
        *bgra_ptr = *gray_ptr;
        bgra_ptr++;
        *bgra_ptr = *gray_ptr;
        bgra_ptr++;
        *bgra_ptr = *gray_ptr;
        bgra_ptr++;
        *bgra_ptr = *gray_ptr;
        bgra_ptr++;
        gray_ptr++;
    }
}

void convertRGBToBGRA(unsigned char* rgb_ptr, unsigned char* bgra_ptr, const size_t n_pixel){
    for(size_t i = 0; i < n_pixel; i++){
        unsigned char r = *rgb_ptr;
        rgb_ptr++;
        unsigned char g = *rgb_ptr;
        rgb_ptr++;
        unsigned char b = *rgb_ptr;
        rgb_ptr++;
        
        *bgra_ptr = b;
        bgra_ptr++;
        *bgra_ptr = g;
        bgra_ptr++;
        *bgra_ptr = r;
        bgra_ptr++;
        *bgra_ptr = 255;
        bgra_ptr++;
    }
}
