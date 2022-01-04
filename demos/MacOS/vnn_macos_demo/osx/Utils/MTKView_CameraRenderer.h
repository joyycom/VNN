//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreVideo/CoreVideo.h>
#import "NSDrawElements.h"

#define MAX_DRAW_SOLIDCIRCLES           2048
#define MAX_DRAW_POINTS                 MAX_DRAW_SOLIDCIRCLES
#define MAX_DRAW_LINES                  1024
#define MAX_DRAW_HOLLOWRECTS            1024

NS_ASSUME_NONNULL_BEGIN
struct rectBox {
    float x0 = 0;
    float y0 = 0;
    float x1 = 1.0;
    float y1 = 1.0;
};
struct BoxFilterParam {
    int _kx;
    int _ky;
};
@interface MTKViewX : MTKView<MTKViewDelegate>

@property (atomic, strong) id<MTLCommandQueue>          mtlCmdQueue;

@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderYCbCr;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderBGRA;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderBlendedBGRA;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderBlendedYCbCr;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderSolidTritangles;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderImages;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderRectTextureTobackgroundTexture;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderRectMaskImageToBackgroundTexture;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderBlendMaskImageAndBackground;
@property (atomic, strong) id<MTLRenderPipelineState>   pipelineRenderCopyTexture;
@property (atomic, strong) id<MTLComputePipelineState>  pipelineBoxFilter;

@property (atomic, strong) id<MTLBuffer>                vertexBufferRenderSolidTritanglesForCirclePoint;
@property (atomic, strong) id<MTLBuffer>                vertexIndicesBufferRenderSolidTritanglesForCirclePoint;

@property (atomic, strong) id<MTLBuffer>                vertexBufferRenderSolidTritanglesForLine;
@property (atomic, strong) id<MTLBuffer>                vertexIndicesBufferRenderSolidTritanglesForLine;

@property (atomic, strong) id<MTLBuffer>                vertexBufferRenderSolidTritanglesForHollowRect;
@property (atomic, strong) id<MTLBuffer>                vertexIndicesBufferRenderSolidTritanglesForHollowRect;

@property (atomic, assign) bool                         mirror;
@property (atomic, strong) id<MTLTexture>               mtltexture_BGRA;
@property (atomic, strong) id<MTLTexture>               mtltexture_Y;
@property (atomic, strong) id<MTLTexture>               mtltexture_CbCr;
@property (atomic, strong) id<MTLTexture>               mtltexture_mask;
@property (atomic, strong) id<MTLTexture>               mtltexture_frontground;
@property (atomic, strong) id<MTLTexture>               mtltexture_background;
@property (atomic, assign) CVMetalTextureCacheRef       cvMtlTextureCache;
@property (atomic, strong) id<MTLTexture>               mtltexture_offScreenMask;
@property (atomic, strong) id<MTLTexture>               mtltexture_bluredMask;
@property (atomic, strong) id<MTLTexture>               mtltexture_offScreenImage;
@property (atomic, strong) id<MTLTexture>               mtltexture_srcImage;

@property (   atomic, strong) NSArray<DrawCircle2D *> * circles;
@property (   atomic, strong) NSArray<DrawRect2D *> *   rects;
@property (   atomic, strong) NSArray<DrawPoint2D *> *  points;
@property (   atomic, strong) NSArray<DrawLine2D *> *   lines;
@property (   atomic, strong) NSArray<DrawImage *> *    imgs;

- (void)resetTextures:(CVPixelBufferRef)pixelBuffer;
- (id<MTLTexture>) generateOffScreenTextureWithFormat:(MTLPixelFormat)format width: (int)width height:(int)height;
- (void)renderRectTextureToBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf rectTexture:(id<MTLTexture>) rectTex rectBox:(rectBox)rectBox offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen: (bool)clearScreen;
- (void)boxfilter_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf srcTexture: (id<MTLTexture>)srcTexture dstTexture: (id<MTLTexture>)dstTexture boxParam: (BoxFilterParam)boxParam;
- (void)renderBlendImageMaskAndBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf imgMaskTexture: (id<MTLTexture>)imgMaskTex backgroundTexture: (id<MTLTexture>)backgroundTexture offscreenTexture: (id<MTLTexture>)offScreenTexture clearScreen:(bool)clearScreen;
- (void)renderRectMaskImageToBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf maskTexture:(id<MTLTexture>) maskTex imageTexture:(id<MTLTexture>) imgTex rectBox:(rectBox)rectBox offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen;
- (void)drawBlendedBGRAToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf foregroundTexture: (id<MTLTexture>)foregroundTexture backgroundTexture: (id<MTLTexture>)backgroundTexture maskTexture: (id<MTLTexture>)maskTexture offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen;
- (id<MTLTexture>)generateOffScreenTextureFromImageURL:(NSURL *)url;
- (void)drawHollowRect2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Rect2Ds:(NSArray<DrawRect2D *> *)rects offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen;
- (void)drawSolidPoint2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Point2Ds:(NSArray<DrawPoint2D *> *)points offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen;
- (void)drawSolidLine2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Line2Ds:(NSArray<DrawLine2D *> *)lines offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen;
- (CVPixelBufferRef) createPixelBufferFromBGRAMTLTexture:(id<MTLTexture>)texture UseDataBuffer: (unsigned char *)databuffer;
@end

NS_ASSUME_NONNULL_END
