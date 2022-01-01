//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "MTKView_CameraRenderer.h"

struct VertexData {
    float x=0;
    float y=0;
    float z=0;
    float w=0;
    float r=0;
    float g=0;
    float b=0;
    float a=0;
};

struct VertexTexData {
    vector_float4 position;
    vector_float2 textureCoordinate;
};


struct IndicesTritangleCorner {
    uint32_t p0;
    uint32_t p1;
    uint32_t p2;
};

#define CROSS_PRODUCT(vect_A, vect_B, cross_P) \
cross_P[0] = vect_A[1] * vect_B[2] - vect_A[2] * vect_B[1]; \
cross_P[1] = vect_A[2] * vect_B[0] - vect_A[0] * vect_B[2]; \
cross_P[2] = vect_A[0] * vect_B[1] - vect_A[1] * vect_B[0];

@implementation MTKViewX

- (void)dealloc {
    if (_cvMtlTextureCache) { CFRelease(_cvMtlTextureCache); }
}

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device {
    self = [super initWithFrame:frameRect device:device];
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    self.framebufferOnly = NO;
    self.autoResizeDrawable = YES;
    self.drawableSize = CGSizeMake(720, 1280);
    self.delegate = self;
    [self mtkView:self drawableSizeWillChange:self.drawableSize];
    
    _mtlCmdQueue = [device newCommandQueue];
    
    NSError *error = nil;
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    if (!_pipelineRenderBGRA) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_camframe_bgra_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_camframe_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
        _pipelineRenderBGRA = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderYCbCr) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_camframe_420f_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_camframe_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderYCbCr = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderBlendedBGRA) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_blended_camframe_bgra_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_offscreen_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
        _pipelineRenderBlendedBGRA = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderBlendedYCbCr) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_blended_camframe_420f_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_camframe_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderBlendedYCbCr = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderSolidTritangles) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_tritangle_2d_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_tritangle_2d_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderSolidTritangles = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        
        if (!_vertexBufferRenderSolidTritanglesForCirclePoint) {
            size_t length = (MAX_DRAW_POINTS * 361 * sizeof(VertexData) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexBufferRenderSolidTritanglesForCirclePoint = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
        if (!_vertexIndicesBufferRenderSolidTritanglesForCirclePoint) {
            size_t length = (MAX_DRAW_POINTS * 360 * sizeof(IndicesTritangleCorner) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexIndicesBufferRenderSolidTritanglesForCirclePoint = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
        
        if (!_vertexBufferRenderSolidTritanglesForLine) {
            size_t length = (MAX_DRAW_LINES * 4 * sizeof(VertexData) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexBufferRenderSolidTritanglesForLine = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
        if (!_vertexIndicesBufferRenderSolidTritanglesForLine) {
            size_t length = (MAX_DRAW_LINES * 2 * sizeof(IndicesTritangleCorner) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexIndicesBufferRenderSolidTritanglesForLine = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
        
        if (!_vertexBufferRenderSolidTritanglesForHollowRect) {
            size_t length = (MAX_DRAW_HOLLOWRECTS * 12 * sizeof(VertexData) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexBufferRenderSolidTritanglesForHollowRect = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
        if (!_vertexIndicesBufferRenderSolidTritanglesForHollowRect) {
            size_t length = (MAX_DRAW_HOLLOWRECTS * 8 * sizeof(IndicesTritangleCorner) + 4095) / 4096 * 4096;
            void *p = NULL;
            posix_memalign(&p, 4096, length);
            _vertexIndicesBufferRenderSolidTritanglesForHollowRect = [device newBufferWithBytesNoCopy:p length:length options:MTLResourceStorageModeShared deallocator:^(void * _Nonnull pointer, NSUInteger length) {
                if (pointer) { free(pointer); }
            }];
        }
    }
    
    if (!_pipelineRenderImages) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_image_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_image_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderImages = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    if (!_pipelineRenderRectTextureTobackgroundTexture) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_camframe_bgra_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_offscreen_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements to Texture";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderRectTextureTobackgroundTexture = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    if(!_pipelineBoxFilter) {
        NSError *errors;
        id<MTLFunction> func = [library newFunctionWithName:@"boxfilter_c4hw4_f16_tex"];
        _pipelineBoxFilter = [device newComputePipelineStateWithFunction:func error:&errors];
    }
    
    if (!_pipelineRenderRectMaskImageToBackgroundTexture) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_mask_image_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_offscreen_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements to Texture";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderRectMaskImageToBackgroundTexture = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderBlendMaskImageAndBackground) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_image_mask_background_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_offscreen_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements to Texture";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderBlendMaskImageAndBackground = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    if (!_pipelineRenderCopyTexture) {
        id<MTLFunction> frag = [library newFunctionWithName:@"render_camframe_bgra_frag"];
        id<MTLFunction> vert = [library newFunctionWithName:@"render_offscreen_vert"];
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Pipeline of Rendering Elements";
        pipelineStateDescriptor.vertexFunction   = vert;
        pipelineStateDescriptor.fragmentFunction = frag;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pipelineRenderCopyTexture = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    }
    
    //setup mtltexture cache
    CVMetalTextureCacheCreate(NULL, NULL, device, NULL, &_cvMtlTextureCache);
    
    return self;
}

- (id<MTLTexture>) generateOffScreenTextureWithFormat:(MTLPixelFormat)format width: (int)width height:(int)height {
    MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format width:width height:height mipmapped:NO];
    textureDesc.usage = MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite;
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDesc];
    return texture;
}

/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view {
    if (view.currentDrawable) {
        id <MTLCommandBuffer> mtlCmdBuff = [_mtlCmdQueue commandBuffer];
        [self drawBlendedBGRA_With_MTLCommandBuffer:mtlCmdBuff foregroundTexture:_mtltexture_offScreenImage backgroundTexture:_mtltexture_BGRA maskTexture:_mtltexture_bluredMask];
        
        [self drawImages_With_MTLCommandBuffer:mtlCmdBuff Images:_imgs];
        [self drawSolidPoint2D_With_MTLCommandBuffer:mtlCmdBuff Point2Ds:_points];
        [self drawSolidCircle2D_With_MTLCommandBuffer:mtlCmdBuff Circle2Ds:_circles];
        [self drawSolidLine2D_With_MTLCommandBuffer:mtlCmdBuff Line2Ds:_lines];
        [self drawHollowRect2D_With_MTLCommandBuffer:mtlCmdBuff Rect2Ds:_rects];
        
        [mtlCmdBuff presentDrawable:view.currentDrawable];
        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
    }
}

- (void)drawYCbCr_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf {
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderYCbCr];
    const float vertecis[48] = {
        1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        
        1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
    };
    [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    [encoder setFragmentTexture:_mtltexture_Y atIndex:0];
    [encoder setFragmentTexture:_mtltexture_CbCr atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)drawBlendedYCbCr_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf {
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderBlendedYCbCr];
    const float vertecis[48] = {
        1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        
        1.f, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        1.f,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
    };
    [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    [encoder setFragmentTexture:_mtltexture_Y           atIndex:0];
    [encoder setFragmentTexture:_mtltexture_CbCr        atIndex:1];
    [encoder setFragmentTexture:_mtltexture_background  atIndex:2];
    [encoder setFragmentTexture:_mtltexture_mask        atIndex:3];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)drawBGRA_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf {
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderBGRA];
    const float vertecis[48] = {
        1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        
        1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
    };
    [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    [encoder setFragmentTexture:_mtltexture_BGRA atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}
- (void)drawSingleTex_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf texture:(id<MTLTexture>) singleTex {
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderBGRA];
    const float vertecis[48] = {
        1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        
        1.0, -1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        -1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
        1.0,  1.0, 0.0, 1.0,   0.0, 0.0, 0.0, 0.0,
    };
    [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    [encoder setFragmentTexture:singleTex atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)renderRectTextureToBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf rectTexture:(id<MTLTexture>) rectTex rectBox:(rectBox)rectBox offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen{
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    [encoder setRenderPipelineState:_pipelineRenderRectTextureTobackgroundTexture];
    float width_f = rectBox.x1 - rectBox.x0;
    float height_f = rectBox.y1 - rectBox.y0;
    float x0 = -1.0 + rectBox.x0 * 2.0;
    float y0 = 1.0 - rectBox.y0 * 2.0;
    float x1 = x0 + width_f * 2.0;
    float y1 = y0 - height_f * 2.0;
    const VertexTexData vertecis[] = {
        {{x1, y1, 0.0, 1.0},   {1.0, 1.0}},
        {{x0, y1, 0.0, 1.0},   {0.0, 1.0}},
        {{x0, y0, 0.0, 1.0},   {0.0, 0.0}},
        
        {{x1, y1, 0.0, 1.0},   {1.0, 1.0}},
        {{x0, y0, 0.0, 1.0},   {0.0, 0.0}},
        {{x1, y0, 0.0, 1.0},   {1.0, 0.0}},
    };
    [encoder setVertexBytes:vertecis length:6 * sizeof(VertexTexData) atIndex:0];
    [encoder setFragmentTexture:rectTex atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)drawBlendedBGRA_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf foregroundTexture: (id<MTLTexture>)foregroundTexture backgroundTexture: (id<MTLTexture>)backgroundTexture maskTexture: (id<MTLTexture>)maskTexture{
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderBlendedBGRA];
    
    if(_mirror){
        const VertexTexData vertecis[] = {
            {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{ 1.0, -1.0, 0.0, 1.0},   {0.0, 1.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            
            {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {1.0, 0.0}},
        };
        [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    }
    else{
        const VertexTexData vertecis[] = {
            {{ 1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{-1.0, -1.0, 0.0, 1.0},   {0.0, 1.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            
            {{ 1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {1.0, 0.0}},
        };
        [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    }
    [encoder setFragmentTexture:foregroundTexture        atIndex:0];
    [encoder setFragmentTexture:backgroundTexture  atIndex:1];
    [encoder setFragmentTexture:maskTexture        atIndex:2];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)boxfilter_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf srcTexture: (id<MTLTexture>)srcTexture dstTexture: (id<MTLTexture>)dstTexture boxParam: (BoxFilterParam)boxParam{
    id <MTLComputeCommandEncoder> encoder = [cmdBuf computeCommandEncoder];
    [encoder setComputePipelineState:_pipelineBoxFilter];
    [encoder setTexture:srcTexture atIndex:0];
    [encoder setTexture:dstTexture atIndex:1];
    [encoder setBytes:&boxParam length:sizeof(BoxFilterParam) atIndex:0];
    uint32_t threadExecutionWidth = (uint32_t)[_pipelineBoxFilter threadExecutionWidth];
    uint32_t maxTotalThreadsPerThreadgroup = (uint32_t)[_pipelineBoxFilter maxTotalThreadsPerThreadgroup];
    // get total threads
    uint32_t total_threads_x = srcTexture.width;
    uint32_t total_threads_y = srcTexture.height;
    uint32_t total_threads_z = 1;
    // set dispatch threads of each groups ..
    uint32_t threads_x = std::fmin(threadExecutionWidth,                                     total_threads_x);
    uint32_t threads_y = std::fmin(maxTotalThreadsPerThreadgroup / threads_x,                total_threads_y);
    uint32_t threads_z = std::fmin(maxTotalThreadsPerThreadgroup / (threads_x * threads_y),  total_threads_z);
    // set dispatch groups ..
    uint32_t groups_x = (total_threads_x + threads_x - 1) / threads_x;
    uint32_t groups_y = (total_threads_y + threads_y - 1) / threads_y;
    uint32_t groups_z = (total_threads_z + threads_z - 1) / threads_z;
    // set mtlsizes ..
    MTLSize threadsPerThreadGroup = MTLSizeMake(threads_x, threads_y, threads_z);
    MTLSize threadGroupsPerGrid = MTLSizeMake(groups_x, groups_y, groups_z);
    [encoder dispatchThreadgroups:threadGroupsPerGrid threadsPerThreadgroup:threadsPerThreadGroup];
    [encoder endEncoding];
}

- (CGImageRef)getCGImageRefFromNSImage:(NSImage *)image {
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef = nil;
    if(imageData) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CFRelease(imageSource);
    }
    return imageRef;
}

- (void)drawImages_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Images:(NSArray<DrawImage *> *)images {
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.device];
    for (auto i = 0; i < images.count; i++) {
        DrawImage * img = images[i];
        float t = (0.5 - img.top) * 2;
        float b = (0.5 - img.bottom) * 2;
        float l, r;
        if(_mirror){
            l = (0.5 - img.left) * 2;
            r = (0.5 - img.right) * 2;
        }
        else{
            l = (img.left - 0.5) * 2;
            r = (img.right - 0.5) * 2;
        }

        const float vertecis_normal[24] = {
            l, t, -1., -1.,
            r, t,  1., -1.,
            r, b,  1.,  1.,
            l, t, -1., -1.,
            r, b,  1.,  1.,
            l, b, -1.,  1.,
        };
        
        const float vertecis_mirror[24] = {
            l, t,  1., -1.,
            r, t, -1., -1.,
            r, b, -1.,  1.,
            l, t,  1., -1.,
            r, b, -1.,  1.,
            l, b,  1.,  1.,
        };
        
        NSError * err;
        CGImageRef cgimg = [self getCGImageRefFromNSImage:img.img];
        id<MTLTexture> imgTexture = [loader newTextureWithCGImage:cgimg options:nil error:&err];
        CGImageRelease(cgimg);
        MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
        passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
        passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
        id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
        [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
        [encoder setRenderPipelineState:_pipelineRenderImages];
        [encoder setVertexBytes:_mirror ? vertecis_mirror : vertecis_normal
                         length:24*sizeof(float)
                        atIndex:0];
        [encoder setFragmentTexture:imgTexture atIndex:0];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [encoder endEncoding];
    }
}

- (void)drawSolidPoint2D_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Point2Ds:(NSArray<DrawPoint2D *> *)points {
    if (points == nil) {
        return;
    }
    if (points.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForCirclePoint.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForCirclePoint.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForCirclePoint.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForCirclePoint.length);
    
    const float cosRadian[360] = {1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452,-0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848};
    const float sinRadian[360] = {0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848,1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452};
    
    for (auto i = 0; i < points.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [points[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        
        vetxs->x = (2 - points[i].x - points[i].x) - 1.f;
        vetxs->y = (2 - points[i].y - points[i].y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        float cx = points[i].x;
        float cy = points[i].y;
        float ry = points[i].thickness * fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.height;
        float rx = points[i].thickness * fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.width;
        
        // set circle for 360°
        for (auto j = 0; j < 360; j++) {
            float y = cy + ry * cosRadian[j];
            float x = cx + rx * sinRadian[j];
            //            vetxs->x = x + x - 1.f;
            vetxs->x = (2 - x - x) - 1.f;
            vetxs->y = (2 - y - y) - 1.f;
            vetxs->z = 0;
            vetxs->w = 1;
            vetxs->r = cr;
            vetxs->g = cg;
            vetxs->b = cb;
            vetxs->a = ca;
            vetxs += 1;
        }
    }
    for (auto i = 0; i < points.count; i++) {
        uint32_t offset0 = i * 360;
        uint32_t offset1 = i * 361;
        for (auto j = 0; j < 359; j++) {
            // the j tritangle
            cornerIdxs[offset0 + j].p0 = offset1 + 0;
            cornerIdxs[offset0 + j].p1 = offset1 + j + 1;
            cornerIdxs[offset0 + j].p2 = offset1 + j + 2;
        }
        cornerIdxs[offset0 + 359].p0 = offset1 + 0;
        cornerIdxs[offset0 + 359].p1 = offset1 + 360;
        cornerIdxs[offset0 + 359].p2 = offset1 + 1;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:360 * 3 * points.count];
    [encoder endEncoding];
}

- (void)drawSolidCircle2D_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Circle2Ds:(NSArray<DrawCircle2D *> *)circles {
    if (circles == nil) {
        return;
    }
    if (circles.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForCirclePoint.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForCirclePoint.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForCirclePoint.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForCirclePoint.length);
    
    const float cosRadian[360] = {1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452,-0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848};
    const float sinRadian[360] = {0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848,1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452};
    
    for (auto i = 0; i < circles.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [circles[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        
        vetxs->x = (2 - circles[i].x - circles[i].x) - 1.f;
        vetxs->y = (2 - circles[i].y - circles[i].y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        float cx = circles[i].x;
        float cy = circles[i].y;
        float ry = circles[i].r * fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.height;
        float rx = circles[i].r * fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.width;
        
        // set circle for 360°
        for (auto j = 0; j < 360; j++) {
            float y = cy + ry * cosRadian[j];
            float x = cx + rx * sinRadian[j];
            vetxs->x = (2 - x - x) - 1.f;
            vetxs->y = (2 - y - y) - 1.f;
            vetxs->z = 0;
            vetxs->w = 1;
            vetxs->r = cr;
            vetxs->g = cg;
            vetxs->b = cb;
            vetxs->a = ca;
            vetxs += 1;
        }
    }
    for (auto i = 0; i < circles.count; i++) {
        uint32_t offset0 = i * 360;
        uint32_t offset1 = i * 361;
        for (auto j = 0; j < 359; j++) {
            // the j tritangle
            cornerIdxs[offset0 + j].p0 = offset1 + 0;
            cornerIdxs[offset0 + j].p1 = offset1 + j + 1;
            cornerIdxs[offset0 + j].p2 = offset1 + j + 2;
        }
        cornerIdxs[offset0 + 359].p0 = offset1 + 0;
        cornerIdxs[offset0 + 359].p1 = offset1 + 360;
        cornerIdxs[offset0 + 359].p2 = offset1 + 1;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:360 * 3 * circles.count];
    [encoder endEncoding];
}

- (void)drawSolidLine2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf
                                                 Line2Ds:(NSArray<DrawLine2D *> *)lines
                                        offScreenTexture: (id<MTLTexture>) offScreenTexture
                                             clearScreen:(bool)clearScreen{
    if (lines == nil) {
        return;
    }
    if (lines.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForLine.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForLine.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForLine.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForLine.length);
    
    const float scale_x = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.width;
    const float scale_y = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.height;
    const float vz[3] = { 0.f, 0.f, 1.f };
    
    NSArray<DrawLine2D *> * lines_copy = [lines copy];
    for (auto i = 0; i < lines_copy.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [lines_copy[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        
        if(_mirror){
            lines_copy[i].x0 = 1 - lines_copy[i].x0;
            lines_copy[i].x1 = 1 - lines_copy[i].x1;
        }
        
        float pa[3] = { lines_copy[i].x0, lines_copy[i].y0, 0.f };
        float pb[3] = { lines_copy[i].x1, lines_copy[i].y1, 0.f };
        float vl[3] = { pb[0]-pa[0], pb[1]-pa[1], 0.f };
        float vn[3] = { 0.f, 0.f, 0.f };
        CROSS_PRODUCT(vl, vz, vn);
        float l2 = sqrt(vn[0] * vn[0] + vn[1] * vn[1]);
        vn[0] /= l2;
        vn[1] /= l2;
        float dx = vn[0] * lines_copy[i].thickness * scale_x;
        float dy = vn[1] * lines_copy[i].thickness * scale_y;
        
        float x = lines_copy[i].x0 + dx;
        float y = lines_copy[i].y0 + dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines_copy[i].x0 - dx;
        y = lines_copy[i].y0 - dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines_copy[i].x1 - dx;
        y = lines_copy[i].y1 - dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines_copy[i].x1 + dx;
        y = lines_copy[i].y1 + dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        uint32_t idx_offset = i * 4;
        cornerIdxs->p0 = 0 + idx_offset; cornerIdxs->p1 = 1 + idx_offset; cornerIdxs->p2 = 2 + idx_offset;
        cornerIdxs+=1;
        cornerIdxs->p0 = 0 + idx_offset; cornerIdxs->p1 = 2 + idx_offset; cornerIdxs->p2 = 3 + idx_offset;
        cornerIdxs+=1;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    passDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForLine offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForLine offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 * lines_copy.count];
    [encoder endEncoding];
}

- (void)drawSolidLine2D_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Line2Ds:(NSArray<DrawLine2D *> *)lines_ori {
    if (lines_ori == nil) {
        return;
    }
    if (lines_ori.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForLine.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForLine.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForLine.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForLine.length);
    
    const float scale_x = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.width;
    const float scale_y = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.height;
    const float vz[3] = { 0.f, 0.f, 1.f };
    
    NSArray<DrawLine2D *> * lines = [lines_ori copy];
    for (auto i = 0; i < lines.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [lines[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        
        if(_mirror){
            lines[i].x0 = 1 - lines[i].x0;
            lines[i].x1 = 1 - lines[i].x1;
        }
        
        float pa[3] = { lines[i].x0, lines[i].y0, 0.f };
        float pb[3] = { lines[i].x1, lines[i].y1, 0.f };
        float vl[3] = { pb[0]-pa[0], pb[1]-pa[1], 0.f };
        float vn[3] = { 0.f, 0.f, 0.f };
        CROSS_PRODUCT(vl, vz, vn);
        float l2 = sqrt(vn[0] * vn[0] + vn[1] * vn[1]);
        vn[0] /= l2;
        vn[1] /= l2;
        float dx = vn[0] * lines[i].thickness * scale_x;
        float dy = vn[1] * lines[i].thickness * scale_y;
        
        float x = lines[i].x0 + dx;
        float y = lines[i].y0 + dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines[i].x0 - dx;
        y = lines[i].y0 - dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines[i].x1 - dx;
        y = lines[i].y1 - dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        x = lines[i].x1 + dx;
        y = lines[i].y1 + dy;
        vetxs->x = x + x - 1.f;
        vetxs->y = (2 - y - y) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        uint32_t idx_offset = i * 4;
        cornerIdxs->p0 = 0 + idx_offset; cornerIdxs->p1 = 1 + idx_offset; cornerIdxs->p2 = 2 + idx_offset;
        cornerIdxs+=1;
        cornerIdxs->p0 = 0 + idx_offset; cornerIdxs->p1 = 2 + idx_offset; cornerIdxs->p2 = 3 + idx_offset;
        cornerIdxs+=1;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForLine offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForLine offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 * lines.count];
    [encoder endEncoding];
}

- (void)drawHollowRect2D_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf Rect2Ds:(NSArray<DrawRect2D *> *)rects {
    if (rects == nil) {
        return;
    }
    if (rects.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForHollowRect.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForHollowRect.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForHollowRect.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForHollowRect.length);
    
    const float scale_x = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.width;
    const float scale_y = fmax(self.drawableSize.width, self.drawableSize.height) / self.drawableSize.height;
    float x[12], y[12];
    for (auto i = 0; i < rects.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [rects[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        float dx = rects[i].thickness * scale_x;
        float dy = rects[i].thickness * scale_y;
        
        x[ 0] = rects[i].left;
        y[ 0] = rects[i].top;
        
        x[ 1] = rects[i].right;
        y[ 1] = rects[i].top;
        
        x[ 2] = rects[i].right;
        y[ 2] = rects[i].bottom;
        
        x[ 3] = rects[i].left;
        y[ 3] = rects[i].bottom;
        
        x[11] = rects[i].left - dx;
        y[11] = rects[i].top;
        
        x[ 4] = rects[i].left;
        y[ 4] = rects[i].top - dy;
        
        x[ 5] = rects[i].right;
        y[ 5] = rects[i].top - dy;
        
        x[ 6] = rects[i].right + dx;
        y[ 6] = rects[i].top;
        
        x[ 7] = rects[i].right + dx;
        y[ 7] = rects[i].bottom;
        
        x[ 8] = rects[i].right;
        y[ 8] = rects[i].bottom + dy;
        
        x[ 9] = rects[i].left;
        y[ 9] = rects[i].bottom + dy;
        
        x[10] = rects[i].left - dx;
        y[10] = rects[i].bottom;
        
        for (auto j = 0; j < 12; j++) {
            vetxs[j].x = (2 - x[j] - x[j]) - 1.f;
            vetxs[j].y = (2 - y[j] - y[j]) - 1.f;
            vetxs[j].z = 0;
            vetxs[j].w = 1;
            vetxs[j].r = cr;
            vetxs[j].g = cg;
            vetxs[j].b = cb;
            vetxs[j].a = ca;
        }
        vetxs += 12;
        
        unsigned int offset = 12 * i;
        cornerIdxs[0] = { 11 + offset,  4 + offset,  1  + offset};
        cornerIdxs[1] = {  4 + offset,  5 + offset,  1 + offset };
        cornerIdxs[2] = {  5 + offset,  6 + offset,  2  + offset};
        cornerIdxs[3] = {  6 + offset,  7 + offset,  2 + offset };
        cornerIdxs[4] = {  7 + offset,  8 + offset,  3 + offset };
        cornerIdxs[5] = {  8 + offset,  9 + offset,  3  + offset};
        cornerIdxs[6] = {  9 + offset, 10 + offset,  0  + offset};
        cornerIdxs[7] = { 10 + offset, 11 + offset,  0 + offset };
        cornerIdxs += 8;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setViewport:(MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height, 0.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForHollowRect offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForHollowRect offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:8 * 3 * rects.count];
    [encoder endEncoding];
}

- (void)resetTextures:(CVPixelBufferRef)pixelBuffer {
    size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    if (planeCount != 0) {
        //set BGRA texture to nil
        _mtltexture_BGRA = nil;
        {//get textureY
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
            MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
            
            CVMetalTextureRef texture = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _cvMtlTextureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
            
            NSAssert(status == kCVReturnSuccess, @"PixelBuffer2MTLTexture.Common.Algorithm : Error in %s, CVMetalTextureCacheCreateTextureFromImage failed.", __PRETTY_FUNCTION__);
            
            _mtltexture_Y = CVMetalTextureGetTexture(texture);
            CVBufferRelease(texture);
        }
        {//get textureCbCr
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
            MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm;
            
            CVMetalTextureRef texture = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _cvMtlTextureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
            
            NSAssert(status == kCVReturnSuccess, @"PixelBuffer2MTLTexture.Common.Algorithm : Error in %s, CVMetalTextureCacheCreateTextureFromImage failed.", __PRETTY_FUNCTION__);
            
            _mtltexture_CbCr = CVMetalTextureGetTexture(texture);
            CVBufferRelease(texture);
        }
    }
    else {
        //set YCbCr texture to nil
        _mtltexture_Y = nil;
        _mtltexture_CbCr = nil;
        CVMetalTextureRef textureRef = nil;
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    _cvMtlTextureCache,
                                                                    pixelBuffer,
                                                                    nil,
                                                                    MTLPixelFormatBGRA8Unorm,
                                                                    width,
                                                                    height,
                                                                    0,
                                                                    &textureRef);
        _mtltexture_BGRA = CVMetalTextureGetTexture(textureRef);
        CVBufferRelease(textureRef);
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)renderBlendImageMaskAndBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf imgMaskTexture: (id<MTLTexture>)imgMaskTex backgroundTexture: (id<MTLTexture>)backgroundTexture offscreenTexture: (id<MTLTexture>)offScreenTexture clearScreen:(bool)clearScreen{
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    [encoder setRenderPipelineState:_pipelineRenderBlendMaskImageAndBackground];
    const VertexTexData vertecis[] = {
        {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
        {{ 1.0, -1.0, 0.0, 1.0},   {0.0, 1.0}},
        {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
        
        {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
        {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
        {{-1.0,  1.0, 0.0, 1.0},   {1.0, 0.0}},
    };
    [encoder setVertexBytes:vertecis length:6 * sizeof(VertexTexData) atIndex:0];
    [encoder setFragmentTexture:imgMaskTex atIndex:0];
    [encoder setFragmentTexture:backgroundTexture atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)renderRectMaskImageToBackground_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf maskTexture:(id<MTLTexture>) maskTex imageTexture:(id<MTLTexture>) imgTex rectBox:(rectBox)rectBox offScreenTexture: (id<MTLTexture>) offScreenTexture clearScreen:(bool)clearScreen{
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    [encoder setRenderPipelineState:_pipelineRenderRectMaskImageToBackgroundTexture];
    float width_f = rectBox.x1 - rectBox.x0;
    float height_f = rectBox.y1 - rectBox.y0;
    float x0 = -1.0 + rectBox.x0 * 2.0;
    float y0 = 1.0 - rectBox.y0 * 2.0;
    float x1 = x0 + width_f * 2.0;
    float y1 = y0 - height_f * 2.0;
    const VertexTexData vertecis[] = {
        {{x1, y1, 0.0, 1.0},   {1.0, 1.0}},
        {{x0, y1, 0.0, 1.0},   {0.0, 1.0}},
        {{x0, y0, 0.0, 1.0},   {0.0, 0.0}},
        
        {{x1, y1, 0.0, 1.0},   {1.0, 1.0}},
        {{x0, y0, 0.0, 1.0},   {0.0, 0.0}},
        {{x1, y0, 0.0, 1.0},   {1.0, 0.0}},
    };
    [encoder setVertexBytes:vertecis length:6 * sizeof(VertexTexData) atIndex:0];
    [encoder setFragmentTexture:maskTex atIndex:0];
    [encoder setFragmentTexture:imgTex atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (void)drawBlendedBGRAToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf
                                       foregroundTexture: (id<MTLTexture>)foregroundTexture
                                       backgroundTexture: (id<MTLTexture>)backgroundTexture
                                             maskTexture: (id<MTLTexture>)maskTexture
                                        offScreenTexture: (id<MTLTexture>) offScreenTexture
                                             clearScreen:(bool)clearScreen{
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    [encoder setRenderPipelineState:_pipelineRenderBlendedBGRA];
    
    if(_mirror){
        const VertexTexData vertecis[] = {
            {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{ 1.0, -1.0, 0.0, 1.0},   {0.0, 1.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            
            {{-1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {1.0, 0.0}},
        };
        [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    }
    else{
        const VertexTexData vertecis[] = {
            {{ 1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{-1.0, -1.0, 0.0, 1.0},   {0.0, 1.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            
            {{ 1.0, -1.0, 0.0, 1.0},   {1.0, 1.0}},
            {{-1.0,  1.0, 0.0, 1.0},   {0.0, 0.0}},
            {{ 1.0,  1.0, 0.0, 1.0},   {1.0, 0.0}},
        };
        [encoder setVertexBytes:vertecis length:6*sizeof(VertexData) atIndex:0];
    }
    [encoder setFragmentTexture:foregroundTexture        atIndex:0];
    [encoder setFragmentTexture:backgroundTexture  atIndex:1];
    [encoder setFragmentTexture:maskTexture        atIndex:2];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
}

- (id<MTLTexture>)generateOffScreenTextureFromImageURL:(NSURL *)url{
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.device];
    NSDictionary *textureLoaderOptions =
    @{
        MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite),
        MTKTextureLoaderOptionSRGB : @(NO),
    };
    NSError* err;
    return [loader newTextureWithContentsOfURL:url options:textureLoaderOptions error:&err];
}

- (void)drawHollowRect2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf
                                                  Rect2Ds:(NSArray<DrawRect2D *> *)rects
                                         offScreenTexture: (id<MTLTexture>) offScreenTexture
                                              clearScreen:(bool)clearScreen
{
    if (rects == nil) {
        return;
    }
    if (rects.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForHollowRect.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForHollowRect.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForHollowRect.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForHollowRect.length);
    
    const float scale_x = fmax(offScreenTexture.width, offScreenTexture.height) / offScreenTexture.width;
    const float scale_y =fmax(offScreenTexture.width, offScreenTexture.height) / offScreenTexture.height;
    float x[12], y[12];
    for (auto i = 0; i < rects.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [rects[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        float dx = rects[i].thickness * scale_x;
        float dy = rects[i].thickness * scale_y;
        
        if(_mirror){
            x[ 0] = rects[i].left;
            y[ 0] = rects[i].top;
            
            x[ 1] = rects[i].right;
            y[ 1] = rects[i].top;
            
            x[ 2] = rects[i].right;
            y[ 2] = rects[i].bottom;
            
            x[ 3] = rects[i].left;
            y[ 3] = rects[i].bottom;
            
            x[11] = rects[i].left - dx;
            y[11] = rects[i].top;
            
            x[ 4] = rects[i].left;
            y[ 4] = rects[i].top - dy;
            
            x[ 5] = rects[i].right;
            y[ 5] = rects[i].top - dy;
            
            x[ 6] = rects[i].right + dx;
            y[ 6] = rects[i].top;
            
            x[ 7] = rects[i].right + dx;
            y[ 7] = rects[i].bottom;
            
            x[ 8] = rects[i].right;
            y[ 8] = rects[i].bottom + dy;
            
            x[ 9] = rects[i].left;
            y[ 9] = rects[i].bottom + dy;
            
            x[10] = rects[i].left - dx;
            y[10] = rects[i].bottom;
        }
        else{
            x[ 0] = 1.f - rects[i].left;
            y[ 0] = rects[i].top;
            
            x[ 1] = 1.f - rects[i].right;
            y[ 1] = rects[i].top;
            
            x[ 2] = 1.f - rects[i].right;
            y[ 2] = rects[i].bottom;
            
            x[ 3] = 1.f - rects[i].left;
            y[ 3] = rects[i].bottom;
            
            x[11] = 1.f - (rects[i].left - dx);
            y[11] = rects[i].top;
            
            x[ 4] = 1.f - rects[i].left;
            y[ 4] = rects[i].top - dy;
            
            x[ 5] = 1.f - rects[i].right;
            y[ 5] = rects[i].top - dy;
            
            x[ 6] = 1.f - (rects[i].right + dx);
            y[ 6] = rects[i].top;
            
            x[ 7] = 1.f - (rects[i].right + dx);
            y[ 7] = rects[i].bottom;
            
            x[ 8] = 1.f - rects[i].right;
            y[ 8] = rects[i].bottom + dy;
            
            x[ 9] = 1.f - rects[i].left;
            y[ 9] = rects[i].bottom + dy;
            
            x[10] = 1.f - (rects[i].left - dx);
            y[10] = rects[i].bottom;
        }
        
        for (auto j = 0; j < 12; j++) {
            vetxs[j].x = (2 - x[j] - x[j]) - 1.f;
            vetxs[j].y = (2 - y[j] - y[j]) - 1.f;
            vetxs[j].z = 0;
            vetxs[j].w = 1;
            vetxs[j].r = cr;
            vetxs[j].g = cg;
            vetxs[j].b = cb;
            vetxs[j].a = ca;
        }
        vetxs += 12;
        
        unsigned int offset = 12 * i;
        cornerIdxs[0] = { 11 + offset,  4 + offset,  1  + offset};
        cornerIdxs[1] = {  4 + offset,  5 + offset,  1 + offset };
        cornerIdxs[2] = {  5 + offset,  6 + offset,  2  + offset};
        cornerIdxs[3] = {  6 + offset,  7 + offset,  2 + offset };
        cornerIdxs[4] = {  7 + offset,  8 + offset,  3 + offset };
        cornerIdxs[5] = {  8 + offset,  9 + offset,  3  + offset};
        cornerIdxs[6] = {  9 + offset, 10 + offset,  0  + offset};
        cornerIdxs[7] = { 10 + offset, 11 + offset,  0 + offset };
        cornerIdxs += 8;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    passDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForHollowRect offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForHollowRect offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:8 * 3 * rects.count];
    [encoder endEncoding];
}

- (void)drawSolidPoint2DToOffscreen_With_MTLCommandBuffer:(id<MTLCommandBuffer>)cmdBuf
                                                 Point2Ds:(NSArray<DrawPoint2D *> *)points
                                         offScreenTexture: (id<MTLTexture>) offScreenTexture
                                              clearScreen:(bool)clearScreen{
    if (points == nil) {
        return;
    }
    if (points.count == 0) {
        return;
    }
    if (_pipelineRenderSolidTritangles == nil) {
        return;
    }
    
    IndicesTritangleCorner *cornerIdxs = (IndicesTritangleCorner *)_vertexIndicesBufferRenderSolidTritanglesForCirclePoint.contents;
    VertexData *vetxs = (VertexData *)_vertexBufferRenderSolidTritanglesForCirclePoint.contents;
    
    memset(cornerIdxs, 0x00, _vertexIndicesBufferRenderSolidTritanglesForCirclePoint.length);
    memset(vetxs, 0x00, _vertexBufferRenderSolidTritanglesForCirclePoint.length);
    
    const float cosRadian[360] = {1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452,-0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848};
    const float sinRadian[360] = {0.000000,0.017452,0.034899,0.052336,0.069756,0.087156,0.104528,0.121869,0.139173,0.156434,0.173648,0.190809,0.207912,0.224951,0.241922,0.258819,0.275637,0.292372,0.309017,0.325568,0.342020,0.358368,0.374607,0.390731,0.406737,0.422618,0.438371,0.453990,0.469472,0.484810,0.500000,0.515038,0.529919,0.544639,0.559193,0.573576,0.587785,0.601815,0.615661,0.629320,0.642788,0.656059,0.669131,0.681998,0.694658,0.707107,0.719340,0.731354,0.743145,0.754710,0.766044,0.777146,0.788011,0.798636,0.809017,0.819152,0.829038,0.838671,0.848048,0.857167,0.866025,0.874620,0.882948,0.891007,0.898794,0.906308,0.913545,0.920505,0.927184,0.933580,0.939693,0.945519,0.951057,0.956305,0.961262,0.965926,0.970296,0.974370,0.978148,0.981627,0.984808,0.987688,0.990268,0.992546,0.994522,0.996195,0.997564,0.998630,0.999391,0.999848,1.000000,0.999848,0.999391,0.998630,0.997564,0.996195,0.994522,0.992546,0.990268,0.987688,0.984808,0.981627,0.978148,0.974370,0.970296,0.965926,0.961262,0.956305,0.951057,0.945519,0.939693,0.933580,0.927184,0.920505,0.913545,0.906308,0.898794,0.891007,0.882948,0.874620,0.866025,0.857167,0.848048,0.838671,0.829038,0.819152,0.809017,0.798636,0.788011,0.777146,0.766044,0.754710,0.743145,0.731354,0.719340,0.707107,0.694658,0.681998,0.669131,0.656059,0.642788,0.629320,0.615661,0.601815,0.587785,0.573576,0.559193,0.544639,0.529919,0.515038,0.500000,0.484810,0.469472,0.453990,0.438371,0.422618,0.406737,0.390731,0.374607,0.358368,0.342020,0.325568,0.309017,0.292372,0.275637,0.258819,0.241922,0.224951,0.207912,0.190809,0.173648,0.156434,0.139173,0.121869,0.104528,0.087156,0.069756,0.052336,0.034899,0.017452,0.000000,-0.017452,-0.034899,-0.052336,-0.069756,-0.087156,-0.104528,-0.121869,-0.139173,-0.156434,-0.173648,-0.190809,-0.207912,-0.224951,-0.241922,-0.258819,-0.275637,-0.292372,-0.309017,-0.325568,-0.342020,-0.358368,-0.374607,-0.390731,-0.406737,-0.422618,-0.438371,-0.453990,-0.469472,-0.484810,-0.500000,-0.515038,-0.529919,-0.544639,-0.559193,-0.573576,-0.587785,-0.601815,-0.615661,-0.629320,-0.642788,-0.656059,-0.669131,-0.681998,-0.694658,-0.707107,-0.719340,-0.731354,-0.743145,-0.754710,-0.766044,-0.777146,-0.788011,-0.798636,-0.809017,-0.819152,-0.829038,-0.838671,-0.848048,-0.857167,-0.866025,-0.874620,-0.882948,-0.891007,-0.898794,-0.906308,-0.913545,-0.920505,-0.927184,-0.933580,-0.939693,-0.945519,-0.951057,-0.956305,-0.961262,-0.965926,-0.970296,-0.974370,-0.978148,-0.981627,-0.984808,-0.987688,-0.990268,-0.992546,-0.994522,-0.996195,-0.997564,-0.998630,-0.999391,-0.999848,-1.000000,-0.999848,-0.999391,-0.998630,-0.997564,-0.996195,-0.994522,-0.992546,-0.990268,-0.987688,-0.984808,-0.981627,-0.978148,-0.974370,-0.970296,-0.965926,-0.961262,-0.956305,-0.951057,-0.945519,-0.939693,-0.933580,-0.927184,-0.920505,-0.913545,-0.906308,-0.898794,-0.891007,-0.882948,-0.874620,-0.866025,-0.857167,-0.848048,-0.838671,-0.829038,-0.819152,-0.809017,-0.798636,-0.788011,-0.777146,-0.766044,-0.754710,-0.743145,-0.731354,-0.719340,-0.707107,-0.694658,-0.681998,-0.669131,-0.656059,-0.642788,-0.629320,-0.615661,-0.601815,-0.587785,-0.573576,-0.559193,-0.544639,-0.529919,-0.515038,-0.500000,-0.484810,-0.469472,-0.453990,-0.438371,-0.422618,-0.406737,-0.390731,-0.374607,-0.358368,-0.342020,-0.325568,-0.309017,-0.292372,-0.275637,-0.258819,-0.241922,-0.224951,-0.207912,-0.190809,-0.173648,-0.156434,-0.139173,-0.121869,-0.104528,-0.087156,-0.069756,-0.052336,-0.034899,-0.017452};
    
    for (auto i = 0; i < points.count; i++) {
        CGFloat cr = 0.0f, cg = 0.0f, cb = 0.0f, ca = 1.0f;
        [points[i].color getRed:&cr green:&cg blue:&cb alpha:&ca];
        
        float cy = points[i].y;
        float cx = _mirror ? points[i].x : 1.f - points[i].x;
        float ry = points[i].thickness * fmax(offScreenTexture.width, offScreenTexture.height) / offScreenTexture.height;
        float rx = points[i].thickness * fmax(offScreenTexture.width, offScreenTexture.height) / offScreenTexture.width;
        
        vetxs->x = (2 - cx - cx) - 1.f;
        vetxs->y = (2 - cy - cy) - 1.f;
        vetxs->z = 0;
        vetxs->w = 1;
        vetxs->r = cr;
        vetxs->g = cg;
        vetxs->b = cb;
        vetxs->a = ca;
        vetxs += 1;
        
        // set circle for 360°
        for (auto j = 0; j < 360; j++) {
            float y = cy + ry * cosRadian[j];
            float x = cx + rx * sinRadian[j];
            vetxs->x = (2 - x - x) - 1.f;
            vetxs->y = (2 - y - y) - 1.f;
            vetxs->z = 0;
            vetxs->w = 1;
            vetxs->r = cr;
            vetxs->g = cg;
            vetxs->b = cb;
            vetxs->a = ca;
            vetxs += 1;
        }
    }
    for (auto i = 0; i < points.count; i++) {
        uint32_t offset0 = i * 360;
        uint32_t offset1 = i * 361;
        for (auto j = 0; j < 359; j++) {
            // the j tritangle
            cornerIdxs[offset0 + j].p0 = offset1 + 0;
            cornerIdxs[offset0 + j].p1 = offset1 + j + 1;
            cornerIdxs[offset0 + j].p2 = offset1 + j + 2;
        }
        cornerIdxs[offset0 + 359].p0 = offset1 + 0;
        cornerIdxs[offset0 + 359].p1 = offset1 + 360;
        cornerIdxs[offset0 + 359].p2 = offset1 + 1;
    }
    
    MTLRenderPassDescriptor *passDesc = self.currentRenderPassDescriptor;
    passDesc.colorAttachments[0].texture = offScreenTexture;
    if (clearScreen) {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else {
        passDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    passDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> encoder = [cmdBuf renderCommandEncoderWithDescriptor:passDesc];
    [encoder setRenderPipelineState:_pipelineRenderSolidTritangles];
    [encoder setVertexBuffer:_vertexBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:0];
    [encoder setVertexBuffer:_vertexIndicesBufferRenderSolidTritanglesForCirclePoint offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:360 * 3 * points.count];
    [encoder endEncoding];
}

- (CVPixelBufferRef) createPixelBufferFromBGRAMTLTexture:(id<MTLTexture>)texture
                                           UseDataBuffer: (unsigned char *)databuffer
{
    
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    void *imageBytes = databuffer;
    NSUInteger bytesPerRow = texture.width * 4;
    MTLRegion region = MTLRegionMake2D(0, 0, texture.width, texture.height);
    [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault,texture.width,texture.height,kCVPixelFormatType_32BGRA,imageBytes,bytesPerRow,NULL,NULL,(__bridge CFDictionaryRef)options,&pxbuffer);
    
    return pxbuffer;
}

@end
