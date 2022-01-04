//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_DisneyFaceStylizing.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"
#import "DemoHelper.h"

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

@interface ViewCtrl_Picture_DisneyFaceStylizing ()
@property (nonatomic, assign) VNNHandle                                 handle_face;
@property (nonatomic, assign) VNNHandle                                 handle_facemask;
@property (nonatomic, assign) VNNHandle                                 handle_disney;
@property (nonatomic, assign) VnGlYuv2RgbaPtr                           cvtYUV2RGBA;
@property (nonatomic, assign) VnGlBgra2RgbaPtr                          cvtTransRB;
@property (nonatomic, assign) VnGlImagesDrawerPtr                       drawRegion;
@property (nonatomic, assign) VnGlAlphaBlendingPtr                      alphaBlender;
@property (nonatomic, assign) VnGlTextureCopyPtr                        copyTexture;
@property (nonatomic, assign) VnGlTexturePtr                            frameTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr                            frameMaskTexAlpha;
@property (nonatomic, assign) VnGlTexturePtr                            tempFrameTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr                            disneyTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr                            maskTexAlpha;
@property (nonatomic, assign) VnGlTexturePtr                            renderTexRGBA;
@property (nonatomic, assign) VnU8BufferPtr                             maskOutBuffer;
@property (nonatomic, assign) VnU8BufferPtr                             disneyOutBuffer;
@property (nonatomic, assign) VnU8BufferPtr                             emptyFrameMask;
@property (nonatomic, assign) VnU8BufferPtr                             emptyFrameRGBA;
@end

@implementation ViewCtrl_Picture_DisneyFaceStylizing

- (void)viewDidLoad {
#if USE_FACE_PARSER && USE_FACE
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face278_data/face_mobile[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Face(&_handle_face, argc, argv);
    }
    
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face_mask_data/face_mask[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_FaceParser(&_handle_facemask, argc, argv);
    }
    
    {
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_disney_data/face_disney[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_CartFaceMaker(&_handle_disney, argc, argv);
    }
    
    if (_handle_face > 0) {
        const int use_278pts = 1;
        VNN_Set_Face_Attr(_handle_face, "_use_278pts", &use_278pts);
    }
    
#   endif
    
    [super viewDidLoad];
}

- (void)onBtnBack {
    
#if USE_FACE_PARSER && USE_FACE
    VNN_Destroy_CartFaceMaker(&_handle_disney);
    VNN_Destroy_FaceParser(&_handle_facemask);
    VNN_Destroy_Face(&_handle_face);
#   endif
    
    [super onBtnBack];
}

- (void)imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {

#if USE_FACE_PARSER && USE_FACE
    [self initFaceParserEffect:pixelBuffer];
    [self effectPrepare:pixelBuffer];
    
    if (_handle_face > 0) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_FaceFrameDataArr faceArr;        
        VNN_Apply_Face_CPU(_handle_face, &input, &faceArr);
        
        VNN_ImageArr faceMaskDataArr;
        VNN_ImageArr disneyDataArr;
        
        if (_handle_facemask > 0 && _handle_disney > 0 && faceArr.facesNum > 0) {
            faceMaskDataArr.imgsNum = faceArr.facesNum;
            for (int f = 0; f < faceArr.facesNum; f++) {
                faceMaskDataArr.imgsArr[f].width = FACEMASK_WIDTH;
                faceMaskDataArr.imgsArr[f].height = FACEMASK_HEIGHT;
                faceMaskDataArr.imgsArr[f].channels = FACEMASK_CHANNEL;
                faceMaskDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_GRAY8;
                faceMaskDataArr.imgsArr[f].data = _maskOutBuffer.get()->data + f * FACEMASK_WIDTH * FACEMASK_HEIGHT * FACEMASK_CHANNEL;
            }
            VNN_Apply_FaceParser_CPU(_handle_facemask, &input, &faceArr, &faceMaskDataArr);
            
            disneyDataArr.imgsNum = faceArr.facesNum;
            for (int f = 0; f < faceArr.facesNum; f++) {
                disneyDataArr.imgsArr[f].width = DISNEY_WIDTH;
                disneyDataArr.imgsArr[f].height = DISNEY_HEIGHT;
                disneyDataArr.imgsArr[f].channels = DISNEY_CHANNEL;
                disneyDataArr.imgsArr[f].pix_fmt = VNN_PIX_FMT_RGB888;
                disneyDataArr.imgsArr[f].data = _disneyOutBuffer.get()->data + f * DISNEY_WIDTH * DISNEY_HEIGHT * DISNEY_CHANNEL;
            }
            VNN_Apply_CartFaceMaker_CPU(_handle_disney, &input, &faceArr, &disneyDataArr);
            
            [self effectBlendOnMask:&faceMaskDataArr withImageArr:&disneyDataArr];
        }
        VNN_Free_VNNImage(pixelBuffer, &input, true);
    }
    [self effectDoDraw];
#endif
    
}

- (void)initFaceParserEffect:(CVPixelBufferRef _Nullable)pixelBuffer {
    [EAGLContext setCurrentContext:self.glContext];
    int frame_width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int frame_height = (int)CVPixelBufferGetHeight(pixelBuffer);
    if (!_cvtYUV2RGBA) {
        _cvtYUV2RGBA = std::make_shared<VnGlYuv2Rgba>();
    }
    if (!_cvtTransRB) {
        _cvtTransRB = std::make_shared<VnGlBgra2Rgba>();
    }
    if (!_alphaBlender) {
        _alphaBlender = std::make_shared<VnGlAlphaBlending>();
    }
    
    if (!_drawRegion) {
        _drawRegion = std::make_shared<VnGlImagesDrawer>();
    }
    
    if (!_copyTexture) {
        _copyTexture = std::make_shared<VnGlTextureCopy>();
    }
    
    if (!_frameTexRGBA) {
        _frameTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_maskTexAlpha) {
        _maskTexAlpha = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_LUMINANCE, FACEMASK_WIDTH, FACEMASK_HEIGHT, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_disneyTexRGBA) {
        _disneyTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGB, DISNEY_WIDTH, DISNEY_HEIGHT, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_tempFrameTexRGBA) {
        _tempFrameTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_frameMaskTexAlpha) {
        _frameMaskTexAlpha = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_renderTexRGBA) {
        _renderTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_maskOutBuffer) {
        size_t dataSize = FACEMASK_CHANNEL * FACEMASK_HEIGHT * FACEMASK_HEIGHT * VNN_FRAMEDATAARR_MAX_FACES_NUM;
        _maskOutBuffer = VnU8BufferPtr(new VnU8Buffer(dataSize));
    }
    
    if (!_disneyOutBuffer) {
        size_t dataSize = DISNEY_CHANNEL * DISNEY_HEIGHT * DISNEY_WIDTH * VNN_FRAMEDATAARR_MAX_FACES_NUM;
        _disneyOutBuffer = VnU8BufferPtr(new VnU8Buffer(dataSize));
    }
    
    if (!_emptyFrameMask) {
        size_t dataSize = frame_width * frame_height * 4;
        _emptyFrameMask = VnU8BufferPtr(new VnU8Buffer(dataSize));
        memset(_emptyFrameMask.get()->data, 0, dataSize);
    }
    
    if (!_emptyFrameRGBA) {
        size_t dataSize = frame_width * frame_height * 4;
        _emptyFrameRGBA = VnU8BufferPtr(new VnU8Buffer(dataSize));
        memset(_emptyFrameRGBA.get()->data, 0, dataSize);
    }
}

- (void) effectPrepare:(CVPixelBufferRef _Nullable)pixelBuffer {
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0) {
        _cvtYUV2RGBA->Apply(self.glUtils.passFramebuffer, { self.NSYTex.get(), self.NSUVTex.get() }, { _frameTexRGBA.get() });
    }
    else {
        _cvtTransRB->Apply(self.glUtils.passFramebuffer, { self.NSBGRATex.get() }, { _frameTexRGBA.get() });
    }
    _copyTexture->Apply(self.glUtils.passFramebuffer, { _frameTexRGBA.get() }, { _renderTexRGBA.get() });
}

- (void) effectBlendOnMask:(VNN_ImageArr *)maskArr withImageArr:(VNN_ImageArr *)imageArr{
    if(_drawRegion == NULL || _alphaBlender == NULL) {
        return;
    }
    
    if(maskArr->imgsNum > 0){
        for(int f = 0; f < maskArr->imgsNum; f++){
            _frameMaskTexAlpha->setData(_emptyFrameMask.get()->data);
            _tempFrameTexRGBA->setData(_emptyFrameRGBA.get()->data);
            
            VNN_Image* mask = &(maskArr->imgsArr[f]);
            _maskTexAlpha->setData(mask->data);
            DrawImgPos2D positionMask{mask->rect.x0, mask->rect.y0, mask->rect.x1, mask->rect.y1};
            std::vector<DrawImgPos2D> positionsMask{positionMask};
            _drawRegion->SetPositions(positionsMask);
            _drawRegion->Apply(self.glUtils.passFramebuffer, { _maskTexAlpha.get() }, { _frameMaskTexAlpha.get() });
            
            VNN_Image* image = &(imageArr->imgsArr[f]);
            _disneyTexRGBA->setData(image->data);
            DrawImgPos2D positionImage{image->rect.x0, image->rect.y0, image->rect.x1, image->rect.y1};
            std::vector<DrawImgPos2D> positionsImage{positionImage};
            _drawRegion->SetPositions(positionsImage);
            _drawRegion->Apply(self.glUtils.passFramebuffer, { _disneyTexRGBA.get() }, { _tempFrameTexRGBA.get() });
            
            _alphaBlender->Apply(self.glUtils.passFramebuffer, { _tempFrameTexRGBA.get(), _frameMaskTexAlpha.get(), _renderTexRGBA.get() }, { _renderTexRGBA.get() });
        }
    }
}

- (void) effectDoDraw {
    
    DrawImgPos2D position{0.f, 0.75f, 0.25f, 1.0f};
    std::vector<DrawImgPos2D> positions{position};
    _drawRegion->SetPositions(positions);
    _drawRegion->Apply(self.glUtils.passFramebuffer, { _frameTexRGBA.get() }, { _renderTexRGBA.get() });
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    [self.glUtils draw_With_RGBATexture:_renderTexRGBA RotateType:rotateType FlipType:flipType];
}

@end
