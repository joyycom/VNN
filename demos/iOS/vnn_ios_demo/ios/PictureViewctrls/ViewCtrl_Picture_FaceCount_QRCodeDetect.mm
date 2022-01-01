//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_FaceCount_QRCodeDetect.h"
#import "vnnimage_ios_kit.h"

#if USE_OBJCOUNT
#   import "vnn_kit.h"
#   import "vnn_objcount.h"
#endif

@interface ViewCtrl_Picture_FaceCount_QRCodeDetect ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString* model;
@property (nonatomic, retain) NSString* cfg;
@end

@implementation ViewCtrl_Picture_FaceCount_QRCodeDetect

-(id)initWithFunctionType:(NSString *)type
{
    self = [super init] ;
    if (self) {
        if([type isEqual:@"FaceCount"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_face_count_data/face_count[1.0.0].vnnmodel"];
        }
        else if([type isEqual:@"QRCodeDetect"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_qrcode_detection_data/qrcode_detection[1.0.0].vnnmodel"];
        }
        else{
            NSAssert(false, @"Error Function Type");
        }
    }
    return self;
}

- (void)viewDidLoad {
#   if USE_OBJCOUNT
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    
    const void *argv[] = { _model.UTF8String };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_ObjCount(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
}

- (void)onBtnBack {

#   if USE_OBJCOUNT
    VNN_Destroy_ObjCount(&_handle);
#   endif
    
    [super onBtnBack];
}

- (void)imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {
#   if USE_OBJCOUNT
    if (_handle > 0) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_ObjCountDataArr outputs;
        VNN_Apply_ObjCount_CPU(_handle, &input, &outputs);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        [self.glUtils rectsDrawer]->_rects.clear();
        for (auto j = 0; j < outputs.count; j++) {
            VNN_Rect2D rect = outputs.objRectArr[j];
            [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                            vnn::renderkit::DrawRect2D(
                                                                                         rect.x0,
                                                                                         rect.y0,
                                                                                         rect.x1,
                                                                                         rect.y1,
                                                                                         15,
                                                                                       vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f)
                                                                                         )
                                                            );
        }
        
        VNN_ObjCountDataArr_Free(&outputs);
    }
#   endif
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0){
        [self.glUtils draw_With_YTexture:self.NSYTex UVTexture:self.NSUVTex RotateType:rotateType FlipType:flipType];
    } else {
        [self.glUtils draw_With_BGRATexture:self.NSBGRATex RotateType:rotateType FlipType:flipType];
    }
}

@end
