//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_GeneralSegment.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "OSXDemoHelper.h"

#if USE_GENERAL
#   import "vnn_general.h"
#endif

@interface WindowCtrl_Picture_GeneralSegment ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString *segment_model;
@property (nonatomic, retain) NSString *segment_cfg;
@property (nonatomic, retain) NSString *bg_file;
@property (nonatomic, assign) bool is_sky_task;
@property (nonatomic, assign) bool reverse_mask;
@property (nonatomic, assign) int model_out_h;
@property (nonatomic, assign) int model_out_w;
@property (nonatomic, assign) int model_out_c;

@property (nonatomic, assign) VnnU8BufferPtr outBuffer;

@end

@implementation WindowCtrl_Picture_GeneralSegment

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
                           WithSegmentType:(NSString *)type {
    self = [super initWithRootViewController:rootViewController];
    if(self){
        _model_out_c = 1;
        if([type isEqual:@"HQ_Portrait"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_portraitseg_data/seg_portrait_picture[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_portraitseg_data/seg_portrait_picture[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/0.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Fast_Portrait"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_portraitseg_data/seg_portrait_video[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_portraitseg_data/seg_portrait_video[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/0.jpg"];
            _model_out_w = 128;
            _model_out_h = 128;
        }
        else if([type isEqual:@"Hair"]){
            _is_sky_task = false;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_hairseg_data/hair_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_hairseg_data/hair_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/3.jpg"];
            _model_out_w = 256;
            _model_out_h = 384;
        }
        else if([type isEqual:@"Animal"]){
            _is_sky_task = false;
            _reverse_mask = false;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_animalseg_data/animal_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_animalseg_data/animal_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/6.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Clothes"]){
            _is_sky_task = false;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_clothesseg_data/clothes_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_clothesseg_data/clothes_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/5.jpg"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Sky"]){
            _is_sky_task = true;
            _reverse_mask = true;
            _segment_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_skyseg_data/sky_segment[1.0.0].vnnmodel"];
            _segment_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_skyseg_data/sky_segment[1.0.0]_process_config.json"];
            _bg_file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/seg_background_imgs/4.jpg"];
            _model_out_w = 512;
            _model_out_h = 512;
        }
        else{
            NSAssert(false, @"Error Segment Type");
        }
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_GENERAL
    const void *argv[] = { [_segment_model UTF8String], [_segment_cfg UTF8String]};
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_General(&_handle, argc, argv);
#   endif
    
    size_t dataSize = _model_out_c *  _model_out_h * _model_out_w;
    _outBuffer = VnnU8BufferPtr(new VnnU8Buffer(dataSize));
    
    self.mtkView.mtltexture_offScreenMask = [self.mtkView generateOffScreenTextureWithFormat:MTLPixelFormatA8Unorm width:_model_out_w height:_model_out_h];

    NSURL* url = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", @"file://", _bg_file]];
    self.mtkView.mtltexture_background = [self.mtkView generateOffScreenTextureFromImageURL:url];

}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_GENERAL
    VNN_Destroy_General(&_handle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
    
#   if USE_GENERAL
    if (_handle > 0) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        const int img_h = input.height;
        const int img_w = input.width;
        
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
        
        [self.mtkView.mtltexture_offScreenMask replaceRegion:MTLRegionMake2D(0, 0, _model_out_w, _model_out_h)
                                                 mipmapLevel:0
                                                   withBytes:_outBuffer.get()->data
                                                 bytesPerRow:_model_out_w];
        
        self.mtkView.mtltexture_frontground = [self.mtkView generateOffScreenTextureFromImageURL:url];
        
        self.mtkView.mtltexture_offScreenImage = [self.mtkView generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm width:img_w height:img_h];
        
        id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
        
        if(!_reverse_mask){
            [self.mtkView drawBlendedBGRAToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                         foregroundTexture:self.mtkView.mtltexture_frontground
                                                         backgroundTexture:self.mtkView.mtltexture_background
                                                               maskTexture:self.mtkView.mtltexture_offScreenMask
                                                          offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                               clearScreen:true];
        }
        else{
            [self.mtkView drawBlendedBGRAToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                         foregroundTexture:self.mtkView.mtltexture_background
                                                         backgroundTexture:self.mtkView.mtltexture_frontground
                                                               maskTexture:self.mtkView.mtltexture_offScreenMask
                                                          offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                               clearScreen:true];
        }

        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
        
    }
#   endif
}

@end
