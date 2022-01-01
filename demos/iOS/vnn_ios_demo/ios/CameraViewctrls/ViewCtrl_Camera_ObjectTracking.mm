//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_ObjectTracking.h"
#import "vnnimage_ios_kit.h"
#include "vnn_kit.h"
#if USE_OBJTRACKING
#   include "vnn_objtracking.h"
#endif

#include <vector>


#define WAIT_BBOX_STAGE 0
#define INIT_STAGE      1
#define TRACK_STAGE     2
#define FRAME_WIDTH (720/2)
#define FRAME_HEIGHT (1280/2)



@interface ViewCtrl_Camera_ObjTracking ()
#if USE_OBJTRACKING
@property (nonatomic, assign) VNNHandle handle_objtracking;
#endif

@property (atomic, assign) volatile int                                 stage;
@property (atomic, assign) volatile bool                                is_dragged;
@property (atomic, assign) bool                                         is_back_camera;
@property (atomic, assign) CGFloat                                      start_x;
@property (atomic, assign) CGFloat                                      start_y;
@property (atomic, assign) CGFloat                                      end_x;
@property (atomic, assign) CGFloat                                      end_y;

@end

@implementation ViewCtrl_Camera_ObjTracking

- (void)viewDidLoad {
    _stage = WAIT_BBOX_STAGE;
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_objtracking_data/object_tracking[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
#if USE_OBJTRACKING
    VNN_Create_ObjTracking(&_handle_objtracking, argc, argv);
#endif
    
    [super viewDidLoad];
    [self onBtnSwitchCam];
    _is_back_camera = true;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self setNoticewithTitle:@"Usage" Massage:@"Drag a rectangle to the object for tracking"];
}

- (void)onBtnBack {
    
#   if USE_OBJTRACKING
    VNN_Destroy_ObjTracking(&_handle_objtracking);
#   endif
    
    [super onBtnBack];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event

{
    
    if(_stage == TRACK_STAGE){
        _is_dragged = false;
        _stage = WAIT_BBOX_STAGE;
    }
    
    NSSet *allTouch = [event allTouches];
    UITouch *touch = [allTouch anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    
    _start_x = point.x / FRAME_WIDTH;
    _start_y = point.y / FRAME_HEIGHT;
    
    NSLog(@"Begin x,y == (%f, %f)", _start_x, _start_y);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouch = [event allTouches];
    UITouch *touch = [allTouch anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    _end_x = point.x / FRAME_WIDTH;
    _end_y = point.y / FRAME_HEIGHT;
    
    float left, right, bottom, top;
    
    if(_start_x < _start_y){
        left = _start_x;
        right = _end_x;
    }
    else{
        left = _end_x;
        right = _start_x;
    }
    
    if(_start_y < _end_y){
        top = _start_y;
        bottom = _end_y;
    }
    else{
        top = _end_y;
        bottom = _start_y;
    }
    
    _start_x = left;
    _start_y = top;
    _end_x = right;
    _end_y = bottom;
    
    _is_dragged = true;
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event

{
    if(!_is_dragged){
        return;
    }
    
    NSSet *allTouch = [event allTouches];
    UITouch *touch = [allTouch anyObject];
    CGPoint point = [touch locationInView:[touch view]];
    _end_x = point.x / FRAME_WIDTH;
    _end_y = point.y / FRAME_HEIGHT;
    
    float left, right, bottom, top;
    
    if(_start_x < _start_y){
        left = _start_x;
        right = _end_x;
    }
    else{
        left = _end_x;
        right = _start_x;
    }
    
    if(_start_y < _end_y){
        top = _start_y;
        bottom = _end_y;
    }
    else{
        top = _end_y;
        bottom = _start_y;
    }
    
    if(right - left < 0.1 || bottom - top < 0.1){
        _is_dragged = false;
    }
    
    _start_x = left;
    _start_y = top;
    _end_x = right;
    _end_y = bottom;
    
    _stage = INIT_STAGE;
    NSLog(@"Got Valid Rect, Ready to Init");
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
    
#if USE_OBJTRACKING
    if (_handle_objtracking > 0) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        if(_stage == WAIT_BBOX_STAGE){
            
            [self.glUtils rectsDrawer]->_rects.clear();
            if(_is_dragged){
                [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                                vnn::renderkit::DrawRect2D(
                                                                                             MIN(1.f, MAX(0, _start_x)),     // left
                                                                                             MIN(1.f, MAX(0, _start_y)),    // top
                                                                                             MIN(1.f, MAX(0, _end_x)),    // right
                                                                                             MIN(1.f, MAX(0, _end_y)),    // bottom
                                                                                             2.f,                                // thickness
                                                                                           vnn::renderkit::DrawColorRGBA(1.f, 1.f, 0.f, 1.f)
                                                                                             ));
            }
        }
        else if(_stage == INIT_STAGE){
            NSLog(@"Start to Init");
            
            [self.glUtils rectsDrawer]->_rects.clear();
            if(_is_dragged){
                [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                                vnn::renderkit::DrawRect2D(
                                                                                             MIN(1.f, MAX(0, _start_x)),     // left
                                                                                             MIN(1.f, MAX(0, _start_y)),    // top
                                                                                             MIN(1.f, MAX(0, _end_x)),    // right
                                                                                             MIN(1.f, MAX(0, _end_y)),    // bottom
                                                                                             2.f,                                // thickness
                                                                                           vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f)
                                                                                             ));
            }
            
            
            // 预览画面与采集画面是水平镜像关系
            // 鼠标点击获得的坐标要调整一下
            //            VNN_Rect2D template_bbox = {1.f - _init_bbox[2], _init_bbox[1], 1.f - _init_bbox[0], _init_bbox[3]};
            VNN_Rect2D template_bbox = {static_cast<VNNFloat32>(_start_x), static_cast<VNNFloat32>(_start_y), static_cast<VNNFloat32>(_end_x), static_cast<VNNFloat32>(_end_y)};
            VNN_Set_ObjTracking_Attr(_handle_objtracking, "_objRect", &template_bbox);
            VNN_Set_ObjTracking_Attr(_handle_objtracking, "_targetImage", &input);
            _stage = TRACK_STAGE;
            NSLog(@"Init done, ready to Track");
        }
        else if(_stage == TRACK_STAGE){
            
            VNN_ObjCountDataArr tracking_result_bbox;
            VNN_Apply_ObjTracking_CPU(_handle_objtracking, &input, &tracking_result_bbox);
            
            [self.glUtils rectsDrawer]->_rects.clear();
            if(tracking_result_bbox.count == 1){
                auto bbox = tracking_result_bbox.objRectArr[0];
                [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                                vnn::renderkit::DrawRect2D(
                                                                                             MIN(1.f, MAX(0, bbox.x0)),     // left
                                                                                             MIN(1.f, MAX(0, bbox.y0)),    // top
                                                                                             MIN(1.f, MAX(0, bbox.x1)),    // right
                                                                                             MIN(1.f, MAX(0, bbox.y1)),    // bottom
                                                                                             2.f,                                // thickness
                                                                                           vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f)
                                                                                             ));
            }
            VNN_ObjCountDataArr_Free(&tracking_result_bbox);
        }
        VNN_Free_VNNImage(pixelBuffer, &input, false);
    }
#endif
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeRight) {
        rotateType = UIView_GLRenderUtils_RotateType_90R;
    }
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        rotateType = UIView_GLRenderUtils_RotateType_90L;
    }
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0){
        [self.glUtils draw_With_YTexture:self.NSYTex UVTexture:self.NSUVTex RotateType:rotateType FlipType:flipType];
    } else {
        [self.glUtils draw_With_BGRATexture:self.NSBGRATex RotateType:rotateType FlipType:flipType];
    }
    
}
@end
