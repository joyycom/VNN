//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_DisneyFaceStylizing.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "vnn_common.h"
#import "OSXDemoHelper.h"

#if USE_FACE_PARSER && USE_FACE
#   import "vnn_faceparser.h"
#   import "vnn_face.h"
#endif

#define FACEMASK_WIDTH  (128)
#define FACEMASK_HEIGHT (128)
#define FACEMASK_CHANNEL (1)

#define DISNEY_WIDTH  (512)
#define DISNEY_HEIGHT (512)
#define DISNEY_CHANNEL (3)

@interface WindowCtrl_Camera_DisneyFaceStylizing ()
@property (nonatomic, assign) VNNHandle                                 handle_face;
@property (nonatomic, assign) VNNHandle                                 handle_facemask;
@property (nonatomic, assign) VNNHandle                                 handle_disney;
@property (nonatomic, assign) VnnU8BufferPtr                            maskOutBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            bgraMaskBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            disneyOutBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            bgraDisneyBuffer;
@property (nonatomic, strong) NSMutableArray*                           mtltexture_MaskArr;
@property (nonatomic, strong) NSMutableArray*                           mtltexture_FaceArr;

@end

@implementation WindowCtrl_Camera_DisneyFaceStylizing

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)initModel{
#if USE_FACE_PARSER && USE_FACE
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face278_data/face_pc[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Face(&_handle_face, argc, argv);
    }
    
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face_mask_data/face_mask[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_FaceParser(&_handle_facemask, argc, argv);
    }
    
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_disney_data/face_disney[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_CartFaceMaker(&_handle_disney, argc, argv);
    }
    
    if (_handle_face > 0) {
        const int use_278pts = 1;
        VNN_Set_Face_Attr(_handle_face, "_use_278pts", &use_278pts);
    }
    
    size_t totalMaskDataSize = FACEMASK_CHANNEL *  FACEMASK_HEIGHT * FACEMASK_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
    _maskOutBuffer = VnnU8BufferPtr(new VnnU8Buffer(totalMaskDataSize));
    
    size_t totalDisneyDataSize = DISNEY_CHANNEL *  DISNEY_HEIGHT * DISNEY_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
    _disneyOutBuffer = VnnU8BufferPtr(new VnnU8Buffer(totalDisneyDataSize));
    
    size_t rgbaMaskDataSize = FACEMASK_HEIGHT * FACEMASK_WIDTH * 4;
    _bgraMaskBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaMaskDataSize));
    
    size_t rgbaDisneyDataSize = DISNEY_HEIGHT * DISNEY_WIDTH * 4;
    _bgraDisneyBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaDisneyDataSize));
    
    _mtltexture_MaskArr = [[NSMutableArray alloc] init];
    _mtltexture_FaceArr = [[NSMutableArray alloc] init];
    for(int f = 0; f < VNN_FRAMEDATAARR_MAX_FACES_NUM; f++){
        [_mtltexture_MaskArr addObject: [self.mtkView
                                         generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                         width:FACEMASK_WIDTH
                                         height:FACEMASK_HEIGHT]];
        
        [_mtltexture_FaceArr addObject: [self.mtkView
                                         generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                         width:DISNEY_WIDTH
                                         height:DISNEY_HEIGHT]];
    }
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#if USE_FACE_PARSER && USE_FACE
    VNN_Destroy_CartFaceMaker(&_handle_disney);
    VNN_Destroy_FaceParser(&_handle_facemask);
    VNN_Destroy_Face(&_handle_face);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
#if USE_FACE_PARSER && USE_FACE
    
    if (_handle_face && _handle_facemask && _handle_disney) {
        
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
        
        VNN_ImageArr faceMaskDataArr;
        faceMaskDataArr.imgsNum = faceArr.facesNum;
        for (int f = 0; f < faceMaskDataArr.imgsNum; f++) {
            faceMaskDataArr.imgsArr[f].width = FACEMASK_WIDTH;
            faceMaskDataArr.imgsArr[f].height = FACEMASK_HEIGHT;
            faceMaskDataArr.imgsArr[f].channels = FACEMASK_CHANNEL;
            faceMaskDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_GRAY8;
            faceMaskDataArr.imgsArr[f].data = _maskOutBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
        }
        VNN_Apply_FaceParser_CPU(_handle_facemask, &input, &faceArr, &faceMaskDataArr);
        
        
        VNN_ImageArr disneyFaceDataArr;
        disneyFaceDataArr.imgsNum = faceArr.facesNum;
        for (int f = 0; f < disneyFaceDataArr.imgsNum; f++) {
            disneyFaceDataArr.imgsArr[f].width = DISNEY_WIDTH;
            disneyFaceDataArr.imgsArr[f].height = DISNEY_HEIGHT;
            disneyFaceDataArr.imgsArr[f].channels = DISNEY_CHANNEL;
            disneyFaceDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_RGB888;
            disneyFaceDataArr.imgsArr[f].data = _disneyOutBuffer.get()->data + f * DISNEY_WIDTH * DISNEY_HEIGHT * DISNEY_CHANNEL;
        }
        VNN_Apply_CartFaceMaker_CPU(_handle_disney, &input, &faceArr, &disneyFaceDataArr);
        
        VNN_Free_VNNImage(pixelBuffer, &input, true);
        
        self.mtkView.mtltexture_offScreenMask = [self.mtkView
                                                 generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                                 width:img_w
                                                 height:img_h];
        
        self.mtkView.mtltexture_frontground = [self.mtkView
                                               generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                               width:img_w
                                               height:img_h];
        
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
            
            
            unsigned char* face_bgra_ptr = _bgraDisneyBuffer.get()->data;
            unsigned char* face_rgb_ptr = _disneyOutBuffer.get()->data + f * DISNEY_WIDTH * DISNEY_HEIGHT * DISNEY_CHANNEL;
            const size_t face_n_pixel = DISNEY_WIDTH * DISNEY_HEIGHT;
            convertRGBToBGRA(face_rgb_ptr, face_bgra_ptr, face_n_pixel);
            
            [_mtltexture_FaceArr[f] replaceRegion:MTLRegionMake2D(0, 0, DISNEY_WIDTH, DISNEY_HEIGHT)
                                      mipmapLevel:0
                                        withBytes:_bgraDisneyBuffer.get()->data
                                      bytesPerRow:DISNEY_WIDTH*4];
            
            
            
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
