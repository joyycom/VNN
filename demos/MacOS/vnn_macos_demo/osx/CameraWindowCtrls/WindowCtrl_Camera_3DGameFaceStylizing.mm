//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_3DGameFaceStylizing.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "vnn_common.h"
#import "OSXDemoHelper.h"

#if USE_STYLIZING && USE_FACE
#   import "vnn_stylizing.h"
#   import "vnn_face.h"
#endif

#define FACEMASK_WIDTH  (512)
#define FACEMASK_HEIGHT (512)
#define FACEMASK_CHANNEL (1)

#define GAMEFACE_WIDTH  (512)
#define GAMEFACE_HEIGHT (512)
#define GAMEFACE_CHANNEL (3)

@interface WindowCtrl_Camera_3DGameFaceStylizing ()
@property (nonatomic, assign) VNNHandle                                 handle_face;
@property (nonatomic, assign) VNNHandle                                 handle_gameface;
@property (nonatomic, assign) VnnU8BufferPtr                            maskOutBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            bgraMaskBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            gameFaceOutBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            bgraGameFaceBuffer;
@property (nonatomic, strong) NSMutableArray*                           mtltexture_MaskArr;
@property (nonatomic, strong) NSMutableArray*                           mtltexture_FaceArr;


@end

@implementation WindowCtrl_Camera_3DGameFaceStylizing

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)initModel{
#if USE_STYLIZING && USE_FACE
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face278_data/face_pc[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Face(&_handle_face, argc, argv);
    }
    
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_3dgame_data/face_3dgame[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Stylizing(&_handle_gameface, argc, argv);
    }
    
    if (_handle_face > 0) {
        const int use_278pts = 1;
        VNN_Set_Face_Attr(_handle_face, "_use_278pts", &use_278pts);
    }
    
    size_t totalMaskDataSize = FACEMASK_CHANNEL *  FACEMASK_HEIGHT * FACEMASK_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
    _maskOutBuffer = VnnU8BufferPtr(new VnnU8Buffer(totalMaskDataSize));
    
    size_t totalDisneyDataSize = GAMEFACE_CHANNEL *  GAMEFACE_HEIGHT * GAMEFACE_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
    _gameFaceOutBuffer = VnnU8BufferPtr(new VnnU8Buffer(totalDisneyDataSize));
    
    size_t rgbaMaskDataSize = FACEMASK_HEIGHT * FACEMASK_WIDTH * 4;
    _bgraMaskBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaMaskDataSize));
    
    size_t rgbaDisneyDataSize = GAMEFACE_HEIGHT * GAMEFACE_WIDTH * 4;
    _bgraGameFaceBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaDisneyDataSize));
    
    _mtltexture_MaskArr = [[NSMutableArray alloc] init];
    _mtltexture_FaceArr = [[NSMutableArray alloc] init];
    for(int f = 0; f < VNN_FRAMEDATAARR_MAX_FACES_NUM; f++){
        [_mtltexture_MaskArr addObject: [self.mtkView
                                          generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                          width:FACEMASK_WIDTH
                                          height:FACEMASK_HEIGHT]];
        
        [_mtltexture_FaceArr addObject: [self.mtkView
                                          generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                          width:GAMEFACE_WIDTH
                                          height:GAMEFACE_HEIGHT]];
    }
    
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#if USE_STYLIZING && USE_FACE
    VNN_Destroy_Stylizing(&_handle_gameface);
    VNN_Destroy_Face(&_handle_face);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
#if USE_STYLIZING && USE_FACE
    
    if (_handle_face && _handle_gameface){
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        const int img_h = input.height;
        const int img_w = input.width;
        if(self.mtkView.mtltexture_bluredMask == nil){
            self.mtkView.mtltexture_bluredMask = [self.mtkView
                                                  generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                                  width:img_w
                                                  height:img_h];
            
            self.mtkView.mtltexture_offScreenImage = [self.mtkView
                                                   generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                                   width:img_w
                                                   height:img_h];
        }
        
        VNN_FaceFrameDataArr faceArr;        
        VNN_Apply_Face_CPU(_handle_face, &input, &faceArr);
        
        VNN_ImageArr gameFaceDataArr;
        gameFaceDataArr.imgsNum = faceArr.facesNum;
        for (int f = 0; f < gameFaceDataArr.imgsNum; f++) {
            gameFaceDataArr.imgsArr[f].width = GAMEFACE_WIDTH;
            gameFaceDataArr.imgsArr[f].height = GAMEFACE_HEIGHT;
            gameFaceDataArr.imgsArr[f].channels = GAMEFACE_CHANNEL;
            gameFaceDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_RGB888;
            gameFaceDataArr.imgsArr[f].data = _gameFaceOutBuffer.get()->data + f * GAMEFACE_WIDTH * GAMEFACE_HEIGHT * GAMEFACE_CHANNEL;
        }
        VNN_Apply_Stylizing_CPU(_handle_gameface, &input, &faceArr, &gameFaceDataArr);
        
        
        VNN_ImageArr faceMaskDataArr;
        faceMaskDataArr.imgsNum = faceArr.facesNum;
        for (int f = 0; f < faceMaskDataArr.imgsNum; f++) {
            faceMaskDataArr.imgsArr[f].width = FACEMASK_WIDTH;
            faceMaskDataArr.imgsArr[f].height = FACEMASK_HEIGHT;
            faceMaskDataArr.imgsArr[f].channels = FACEMASK_CHANNEL;
            faceMaskDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_GRAY8;
            faceMaskDataArr.imgsArr[f].data = _maskOutBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
        }
        VNN_Get_Stylizing_Attr(_handle_gameface,  "_Mask", &faceMaskDataArr);
        
        VNN_Free_VNNImage(pixelBuffer, &input, true);
        
        id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
        
        for (int f = 0; f < faceMaskDataArr.imgsNum; f++) {
            
            VNN_Rect2D vnn_rect = faceMaskDataArr.imgsArr[f].rect;
            rectBox mtl_rect;
            mtl_rect.x0 = vnn_rect.x0;
            mtl_rect.y0 = vnn_rect.y0;
            mtl_rect.x1 = vnn_rect.x1;
            mtl_rect.y1 = vnn_rect.y1;
            
            unsigned char* mask_bgra_ptr = _bgraMaskBuffer.get()->data;
            unsigned char* mask_gray_ptr = _maskOutBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
            const size_t mask_n_pixel = FACEMASK_WIDTH * FACEMASK_HEIGHT;
            tileGrayToBGRA(mask_gray_ptr, mask_bgra_ptr, mask_n_pixel);
            
            [_mtltexture_MaskArr[f] replaceRegion:MTLRegionMake2D(0, 0, FACEMASK_WIDTH, FACEMASK_HEIGHT)
                                              mipmapLevel:0
                                                withBytes:_bgraMaskBuffer.get()->data
                                              bytesPerRow:FACEMASK_WIDTH*4];
            
            [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                                  rectTexture:_mtltexture_MaskArr[f]
                                                                      rectBox:mtl_rect
                                                             offScreenTexture:self.mtkView.mtltexture_bluredMask
                                                                  clearScreen:f == 0];
            
            
            unsigned char* face_bgra_ptr = _bgraGameFaceBuffer.get()->data;
            unsigned char* face_rgb_ptr = _gameFaceOutBuffer.get()->data + f * GAMEFACE_WIDTH * GAMEFACE_HEIGHT * GAMEFACE_CHANNEL;
            const size_t face_n_pixel = GAMEFACE_WIDTH * GAMEFACE_HEIGHT;
            convertRGBToBGRA(face_rgb_ptr, face_bgra_ptr, face_n_pixel);
            
            [_mtltexture_FaceArr[f] replaceRegion:MTLRegionMake2D(0, 0, GAMEFACE_WIDTH, GAMEFACE_HEIGHT)
                                              mipmapLevel:0
                                                withBytes:_bgraGameFaceBuffer.get()->data
                                              bytesPerRow:GAMEFACE_WIDTH*4];
            
            
            
            [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                                  rectTexture:_mtltexture_FaceArr[f]
                                                                      rectBox:mtl_rect
                                                             offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                                  clearScreen:f == 0];
        }
        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
        
    }
#endif
}

@end
