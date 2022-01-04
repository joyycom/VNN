//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_CartoonStylizing_ComicStylizing.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"
#import "DemoHelper.h"

#if USE_GENERAL
#   import "vnn_general.h"
#endif

@interface ViewCtrl_Camera_CartoonStylizing_ComicStylizing ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString *stylizing_model;
@property (nonatomic, retain) NSString *stylizing_cfg;

@property (nonatomic, assign) int model_out_h;
@property (nonatomic, assign) int model_out_w;
@property (nonatomic, assign) int model_out_c;

@property (nonatomic, assign) VnGlYuv2RgbaPtr cvtYUV2RGBA;
@property (nonatomic, assign) VnGlBgra2RgbaPtr cvtTransRB;
@property (nonatomic, assign) VnGlImagesDrawerPtr drawRegion;
@property (nonatomic, assign) VnGlTexturePtr frameTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr renderTexRGBA;
@property (nonatomic, assign) VnU8BufferPtr outBuffer;
@end

@implementation ViewCtrl_Camera_CartoonStylizing_ComicStylizing

-(id)initWithStyleType:(NSString *)type
{
    self = [super init] ;
    if (self) {
        _model_out_c = 3;
        if([type isEqual:@"Comic"]){
            _stylizing_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_comic_data/stylize_comic[1.0.0].vnnmodel"];
            _stylizing_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_comic_data/stylize_comic[1.0.0]_proceess_config.json"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Cartoon"]){
            _stylizing_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_cartoon_data/stylize_cartoon[1.0.0].vnnmodel"];
            _stylizing_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_cartoon_data/stylize_cartoon[1.0.0]_proceess_config.json"];
            _model_out_w = 512;
            _model_out_h = 512;
        }
        else{
            NSAssert(false, @"Error Style Type");
        }
    }
    return self;
}

- (void)viewDidLoad {
#   if USE_GENERAL
    const void *argv[] = { [_stylizing_model UTF8String], [_stylizing_cfg UTF8String]};
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_General(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
    [self onBtnSwitchCam];
}

- (void)onBtnBack {
    
#   if USE_GENERAL
    VNN_Destroy_General(&_handle);
#   endif
    
    [super onBtnBack];
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
    
#   if USE_GENERAL
    if (_handle > 0) {
        [self initFaceParserEffect:pixelBuffer];
        [self effectPrepare:pixelBuffer];
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_ImageArr output;
        output.imgsNum = 1;
        output.imgsArr[0].height = _model_out_h;
        output.imgsArr[0].width = _model_out_w;
        output.imgsArr[0].channels = _model_out_c;
        output.imgsArr[0].pix_fmt= VNN_PIX_FMT_RGB888;
        output.imgsArr[0].data = _outBuffer.get()->data;
        VNN_Apply_General_CPU(_handle, &input, NULL, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        [self effectDoDraw];
    }
#   endif
    
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
    
    if (!_drawRegion) {
        _drawRegion = std::make_shared<VnGlImagesDrawer>();
    }
    
    if (!_frameTexRGBA) {
        _frameTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_renderTexRGBA) {
        _renderTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGB, _model_out_w, _model_out_h, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_outBuffer){
        size_t dataSize = _model_out_c *  _model_out_h * _model_out_w;
        _outBuffer = VnU8BufferPtr(new VnU8Buffer(dataSize));
    }
}

- (void) effectPrepare:(CVPixelBufferRef _Nullable)pixelBuffer {
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0) {
        _cvtYUV2RGBA->Apply(self.glUtils.passFramebuffer, { self.NSYTex.get(), self.NSUVTex.get() }, { _frameTexRGBA.get() });
    }
    else {
        _cvtTransRB->Apply(self.glUtils.passFramebuffer, { self.NSBGRATex.get() }, { _frameTexRGBA.get() });
    }
}

- (void) effectDoDraw {
    if(_renderTexRGBA == nullptr || _outBuffer == nullptr){
        return;
    }
    _renderTexRGBA->setData(_outBuffer.get()->data);
    
    DrawImgPos2D position{0.f, 0.75f, 0.25f, 1.0f};
    std::vector<DrawImgPos2D> positions{position};
    _drawRegion->SetPositions(positions);
    _drawRegion->Apply(self.glUtils.passFramebuffer, { _frameTexRGBA.get() }, { _renderTexRGBA.get() });
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeRight) {
        rotateType = UIView_GLRenderUtils_RotateType_90R;
    }
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        rotateType = UIView_GLRenderUtils_RotateType_90L;
    }
    [self.glUtils draw_With_RGBATexture:_renderTexRGBA RotateType:rotateType FlipType:flipType];
}

@end
