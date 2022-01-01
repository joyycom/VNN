//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_FaceSegment.h"
#import "vnnimage_mac_kit.h"
#import "vnn_common.h"
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

@interface WindowCtrl_Picture_FaceSegment ()
@property (nonatomic, assign) VNNHandle                                 handle_face;
@property (nonatomic, assign) VNNHandle                                 handle_facemask;
@property (nonatomic, assign) VnnU8BufferPtr                            outBuffer;
@property (nonatomic, assign) VnnU8BufferPtr                            bgraMaskBuffer;
@property (nonatomic, strong) NSMutableArray*                           mtltexture_MaskArr;

@end

@implementation WindowCtrl_Picture_FaceSegment

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
    
    if (_handle_face > 0) {
        const int use_278pts = 1;
        VNN_Set_Face_Attr(_handle_face, "_use_278pts", &use_278pts);
    }
    
    NSString* bgFilePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/1.jpg"];
    NSURL* bgFileUrl = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", @"file://", bgFilePath]];
    self.mtkView.mtltexture_background = [self.mtkView generateOffScreenTextureFromImageURL:bgFileUrl];
    
    size_t dataSize = FACEMASK_CHANNEL *  FACEMASK_HEIGHT * FACEMASK_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
    _outBuffer = VnnU8BufferPtr(new VnnU8Buffer(dataSize));
    
    size_t rgbaDataSize = FACEMASK_HEIGHT * FACEMASK_WIDTH * 4;
    _bgraMaskBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaDataSize));
    
    _mtltexture_MaskArr = [[NSMutableArray alloc] init];
    for(int f = 0; f < VNN_FRAMEDATAARR_MAX_FACES_NUM; f++){
        [_mtltexture_MaskArr addObject:[self.mtkView
                                       generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                       width:FACEMASK_WIDTH
                                       height:FACEMASK_HEIGHT]];
    }
    
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#if USE_FACE_PARSER && USE_FACE
    VNN_Destroy_FaceParser(&_handle_facemask);
    VNN_Destroy_Face(&_handle_face);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
#if USE_FACE_PARSER && USE_FACE
    
    if (_handle_face && _handle_facemask) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        const int img_h = input.height;
        const int img_w = input.width;
        
        VNN_FaceFrameDataArr faceArr;        
        VNN_Apply_Face_CPU(_handle_face, &input, &faceArr);
        
        VNN_ImageArr faceMaskDataArr;
        faceMaskDataArr.imgsNum = faceArr.facesNum;
        for (int f = 0; f < faceMaskDataArr.imgsNum; f++) {
            faceMaskDataArr.imgsArr[f].width = FACEMASK_WIDTH;
            faceMaskDataArr.imgsArr[f].height = FACEMASK_HEIGHT;
            faceMaskDataArr.imgsArr[f].channels = FACEMASK_CHANNEL;
            faceMaskDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_GRAY8;
            faceMaskDataArr.imgsArr[f].data = _outBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
        }
        VNN_Apply_FaceParser_CPU(_handle_facemask, &input, &faceArr, &faceMaskDataArr);
        
        VNN_Free_VNNImage(pixelBuffer, &input, true);
        
        self.mtkView.mtltexture_offScreenMask = [self.mtkView
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
            
            unsigned char* bgra_ptr = _bgraMaskBuffer.get()->data;
            unsigned char* gray_ptr = _outBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
            const size_t n_pixel = FACEMASK_WIDTH * FACEMASK_HEIGHT;
            tileGrayToBGRA(gray_ptr, bgra_ptr, n_pixel);

            [_mtltexture_MaskArr[f] replaceRegion:MTLRegionMake2D(0, 0, FACEMASK_WIDTH, FACEMASK_HEIGHT)
                                     mipmapLevel:0
                                       withBytes:_bgraMaskBuffer.get()->data
                                     bytesPerRow:FACEMASK_WIDTH*4];
            
            [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                                  rectTexture:_mtltexture_MaskArr[f]
                                                                      rectBox:mtl_rect
                                                             offScreenTexture:self.mtkView.mtltexture_offScreenMask
                                                                  clearScreen:f == 0];
        }
        
        
        self.mtkView.mtltexture_frontground = [self.mtkView generateOffScreenTextureFromImageURL:url];
        
        self.mtkView.mtltexture_offScreenImage = [self.mtkView
                                                  generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                                                  width:img_w
                                                  height:img_h];
        
        [self.mtkView drawBlendedBGRAToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                     foregroundTexture:self.mtkView.mtltexture_frontground
                                                     backgroundTexture:self.mtkView.mtltexture_background
                                                           maskTexture:self.mtkView.mtltexture_offScreenMask
                                                      offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                           clearScreen:true];
        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
        
    }
#endif
}

@end
