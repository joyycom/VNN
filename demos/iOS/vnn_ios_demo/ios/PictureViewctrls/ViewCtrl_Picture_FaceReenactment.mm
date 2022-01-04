//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_FaceReenactment.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"
#import "DemoHelper.h"

#if USE_FACE_REENACTMENT && USE_FACE
#   import "vnn_face.h"
#   import "vnn_face_reenactment.h"
#endif

@interface ViewCtrl_Picture_FaceReenactment ()
@property (nonatomic, assign) VNNHandle             handle;
@property (nonatomic, assign) VNNHandle             face_handle;
@property (nonatomic, assign) VnGlYuv2RgbaPtr       cvtYUV2RGBA;
@property (nonatomic, assign) VnGlBgra2RgbaPtr      cvtTransRB;
@property (nonatomic, assign) VnGlImagesDrawerPtr   drawRegion;
@property (nonatomic, assign) VnGlTextureCopyPtr    copyTexture;
@property (nonatomic, assign) VnGlTexturePtr        renderTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr        frameTexRGBA;
@property (nonatomic, assign) VnGlTexturePtr        faceTexRGB;
@property (nonatomic, assign) VnU8BufferPtr         outBuffer;
@property (nonatomic, assign) int                   mOutImgWidth;
@property (nonatomic, assign) int                   mOutImgHeight;
@property (atomic, assign) volatile bool            request_to_quit;
@property (nonatomic, retain) NSLock*               mutex_lock;

@end

@implementation ViewCtrl_Picture_FaceReenactment

- (void)viewDidLoad {
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    
#   if USE_FACE_REENACTMENT && USE_FACE
    const void *face_detection_argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face278_data/face_mobile[1.0.0].vnnmodel"].UTF8String,
    };
    const int face_detection_argc = sizeof(face_detection_argv)/sizeof(face_detection_argv[0]);
    VNN_Create_Face(&_face_handle, face_detection_argc, face_detection_argv);
    int use_278pts = 1;
    VNN_Set_Face_Attr(_face_handle, "_use_278pts", &use_278pts);
    
    const void *face_reenactment_argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face_reenactment_data/face_reenactment[1.0.0].vnnmodel"].UTF8String,
    };
    const int face_reenactment_argc = sizeof(face_reenactment_argv)/sizeof(face_reenactment_argv[0]);
    VNN_Create_FaceReenactment(&_handle, face_reenactment_argc, face_reenactment_argv);
    const char *_driving_json_path = (const char *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face_reenactment_data/driving.kps.json"].UTF8String;
    VNN_Set_FaceReenactment_Attr(_handle, "_kpJsonsPath", _driving_json_path);
    _mOutImgWidth = 256;
    _mOutImgHeight = 256;
#   endif
    
    _mutex_lock = [[NSLock alloc] init];
    [super viewDidLoad];
}

- (void)onBtnBack {
    _request_to_quit = true;
    [_mutex_lock lock];
    
#   if USE_FACE_REENACTMENT && USE_FACE
    VNN_Destroy_Face(&_face_handle);
    VNN_Destroy_FaceReenactment(&_handle);
#   endif
    
    [_mutex_lock unlock];
    [super onBtnBack];
}

- (void)onBtnCapture {
    _request_to_quit = true;
    
    [_mutex_lock lock];
    [super onBtnCapture];
    [_mutex_lock unlock];
}


- (void)imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {
    
    dispatch_queue_t _mt_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(_mt_queue, ^{
        [self process:pixelBuffer];
    });
}

- (void)process:(CVPixelBufferRef)pixelBuffer {
    
    NSAssert(CVPixelBufferGetPlaneCount(pixelBuffer) == 0, @"Support BGRA Image Format Only");
    [_mutex_lock lock];
#   if USE_FACE_REENACTMENT && USE_FACE
    [self initFaceParserEffect:pixelBuffer];
    [self effectPrepare:pixelBuffer];
    
    if (_handle > 0 && _face_handle > 0) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_FaceFrameDataArr face_data, detection_data;
        VNN_Apply_Face_CPU(_face_handle, &input, &face_data);
        VNN_Get_Face_Attr(_face_handle, "_detection_data", &detection_data);
        
        if(detection_data.facesNum == 0){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self setNoticewithTitle:@"Warning" Massage:@"No face is detected"];
            });
            VNN_Free_VNNImage(pixelBuffer, &input, false);
            [_mutex_lock unlock];
            return;
        }
        
        VNN_Set_FaceReenactment_Attr(_handle, "_faceRect", &detection_data.facesArr[0].faceRect);
        
        VNN_Set_FaceReenactment_Attr(_handle, "_targetImage", &input);
        
        int frameCount = 0;
        VNN_Get_FaceReenactment_Attr(_handle, "_frameCount", &frameCount);
        
        VNN_Image faceImg;
        faceImg.width = _mOutImgWidth;
        faceImg.height = _mOutImgHeight;
        faceImg.channels = 3;
        faceImg.pix_fmt = VNN_PIX_FMT_RGB888;
        faceImg.data = _outBuffer.get()->data;
        
        _request_to_quit = false;
        while (true) {
            for(int i=1; i <= frameCount; i++){
                if(_request_to_quit){
                    VNN_Free_VNNImage(pixelBuffer, &input, false);
                    [_mutex_lock unlock];
                    return;
                }
                
                VNN_Apply_FaceReenactment_CPU(_handle, &i, &faceImg);
                printf("process frame %d/%d done\n", i, frameCount);
                
                [self DoDrawWithImage:faceImg];
            }
        }
    }
#   endif
    
}

- (void) DoDrawWithImage:(VNN_Image &)img {
    
    _faceTexRGB->setData(img.data);
    
    DrawImgPos2D position_face{img.rect.x0, img.rect.y0, img.rect.x1, img.rect.y1};
    DrawImgPos2D position_frame{0.f, 0.75f, 0.25f, 1.0f};
    std::vector<DrawImgPos2D> positions{position_face, position_frame};
    _drawRegion->SetPositions(positions);
    _drawRegion->Apply(self.glUtils.passFramebuffer, { _faceTexRGB.get(), _frameTexRGBA.get() }, { _renderTexRGBA.get() });
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    [self.glUtils draw_With_RGBATexture:_renderTexRGBA RotateType:rotateType FlipType:flipType];
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
    if (!_copyTexture) {
        _copyTexture = std::make_shared<VnGlTextureCopy>();
    }
    if (!_renderTexRGBA) {
        _renderTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_frameTexRGBA) {
        _frameTexRGBA = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame_width, frame_height, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_faceTexRGB) {
        _faceTexRGB = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGB, _mOutImgWidth, _mOutImgHeight, GL_UNSIGNED_BYTE, NULL));
    }
    if (!_outBuffer) {
        size_t dataSize = _mOutImgWidth * _mOutImgHeight * 3;
        _outBuffer = VnU8BufferPtr(new VnU8Buffer(dataSize));
    }
}

@end
