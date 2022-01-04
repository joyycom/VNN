//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_GeneralSegment.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"
#import "DemoHelper.h"

#if USE_GENERAL
#   import "vnn_general.h"
#endif

@interface ViewCtrl_Picture_GeneralSegment ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString *segment_model;
@property (nonatomic, retain) NSString *segment_cfg;
@property (nonatomic, retain) NSString *bg_file;
@property (nonatomic, assign) bool is_sky_task;
@property (nonatomic, assign) bool reverse_mask;
@property (nonatomic, assign) int model_out_h;
@property (nonatomic, assign) int model_out_w;
@property (nonatomic, assign) int model_out_c;

@property (nonatomic, assign) VnGlYuv2RgbaPtr              cvtYUV2RGBA;
@property (nonatomic, assign) VnGlBgra2RgbaPtr             cvtTransRB;
@property (nonatomic, assign) VnGlAlphaBlendingPtr         alphaBlender;
@property (nonatomic, assign) VnGlImagesDrawerPtr          drawRegion;
@property (nonatomic, assign) VnU8BufferPtr                outBuffer;
@property (nonatomic, assign) VnGlTexturePtr               bgPictureTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr               frameTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr               frameMaskTexAlpha;
@property (nonatomic, assign) VnGlTexturePtr               renderTexRGBA;
@end


@implementation ViewCtrl_Picture_GeneralSegment

-(id)initWithSegmentType:(NSString *)type
{
    self = [super init] ;
    if (self) {
        _model_out_c = 1;
        if([type isEqual:@"HQ_Portrait"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_portraitseg_data/seg_portrait_picture[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_portraitseg_data/seg_portrait_picture[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/0.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Fast_Portrait"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_portraitseg_data/seg_portrait_video[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_portraitseg_data/seg_portrait_video[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/0.jpg"];
            _model_out_w = 128;
            _model_out_h = 128;
        }
        else if([type isEqual:@"Hair"]){
            _is_sky_task = false;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_hairseg_data/hair_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_hairseg_data/hair_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/3.jpg"];
            _model_out_w = 256;
            _model_out_h = 384;
        }
        else if([type isEqual:@"Animal"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_animalseg_data/animal_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_animalseg_data/animal_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/6.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Clothes"]){
            _is_sky_task = false;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_clothesseg_data/clothes_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_clothesseg_data/clothes_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/5.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Sky"]){
            _is_sky_task = true;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_skyseg_data/sky_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_skyseg_data/sky_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/effects/seg_background_imgs/4.jpg"];
            _model_out_w = 512;
            _model_out_h = 512;
        }
        else{
            NSAssert(false, @"Error Segment Type");
        }
    }
    return self;
}

- (void)viewDidLoad {
#   if USE_GENERAL
    const void *argv[] = { [_segment_model UTF8String], [_segment_cfg UTF8String]};
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_General(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
}

- (void)onBtnBack {
#   if USE_GENERAL
    VNN_Destroy_General(&_handle);
#   endif
    
    [super onBtnBack];
}

- (void)imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {
#   if USE_GENERAL
    if (_handle > 0) {
        [self initFaceParserEffect:pixelBuffer];
        [self effectPrepare:pixelBuffer];
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_ImageArr output;
        output.imgsNum = 1;
        output.imgsArr[0].height = _model_out_h;
        output.imgsArr[0].width = _model_out_w;
        output.imgsArr[0].channels = _model_out_c;
        output.imgsArr[0].pix_fmt= VNN_PIX_FMT_GRAY8;
        output.imgsArr[0].data = _outBuffer.get()->data;
        VNN_Apply_General_CPU(_handle, &input, NULL, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        if(_is_sky_task){
            int hasSky;
            VNN_Get_General_Attr(_handle, "_hasTarget", &hasSky);
            if(!hasSky){
                size_t dataSize = _model_out_c * _model_out_h * _model_out_w;
                memset(_outBuffer.get()->data, 0, dataSize);
            }
        }
        
        [self effectBlendOnMask];
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
    if (!_alphaBlender) {
        _alphaBlender = std::make_shared<VnGlAlphaBlending>();
    }
    if (!_drawRegion) {
        _drawRegion = std::make_shared<VnGlImagesDrawer>();
    }
    
    if (!_bgPictureTexRGBA) {
        NSError *error;
        UIImage *img = [UIImage imageWithContentsOfFile:_bg_file];
        GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:img.CGImage options:nil error:&error];
        NSAssert(texture != nil, @"Error load background picture");
        _bgPictureTexRGBA = VnGlTexturePtr(new VnGlTexture(texture.name, GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if (!_frameTexRGBA) {
        _frameTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_frameMaskTexAlpha) {
        _frameMaskTexAlpha = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_LUMINANCE, _model_out_w, _model_out_h, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_renderTexRGBA) {
        _renderTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    
    if(!_outBuffer) {
        size_t dataSize = _model_out_c * _model_out_h * _model_out_w;
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

- (void) effectBlendOnMask{
    _frameMaskTexAlpha->setData(_outBuffer.get()->data);
    if(_reverse_mask){
        _alphaBlender->Apply(self.glUtils.passFramebuffer, { _bgPictureTexRGBA.get(), _frameMaskTexAlpha.get(), _frameTexRGBA.get() }, { _renderTexRGBA.get() });
        
    }
    else{
        _alphaBlender->Apply(self.glUtils.passFramebuffer, { _frameTexRGBA.get(), _frameMaskTexAlpha.get(), _bgPictureTexRGBA.get() }, { _renderTexRGBA.get() });
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
