//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_CartoonStylizing_ComicStylizing.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "OSXDemoHelper.h"

#if USE_GENERAL
#   import "vnn_general.h"
#endif

@interface WindowCtrl_Camera_CartoonStylizing_ComicStylizing ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString *stylizing_model;
@property (nonatomic, retain) NSString *stylizing_cfg;

@property (nonatomic, assign) int model_out_h;
@property (nonatomic, assign) int model_out_w;
@property (nonatomic, assign) int model_out_c;
@property (nonatomic, assign) VnnU8BufferPtr outBufferRGB;
@property (nonatomic, assign) VnnU8BufferPtr outBufferRGBA;

@end

@implementation WindowCtrl_Camera_CartoonStylizing_ComicStylizing

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
                             WithStyleType:(NSString *)type {
    self = [super initWithRootViewController:rootViewController];
    if(self){
        _model_out_c = 3;
        if([type isEqual:@"Comic"]){
            _stylizing_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_comic_data/stylize_comic[1.0.0].vnnmodel"];
            _stylizing_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_comic_data/stylize_comic[1.0.0]_proceess_config.json"];
            _model_out_w = 384;
            _model_out_h = 512;
        }
        else if([type isEqual:@"Cartoon"]){
            _stylizing_model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_cartoon_data/stylize_cartoon[1.0.0].vnnmodel"];
            _stylizing_cfg = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_cartoon_data/stylize_cartoon[1.0.0]_proceess_config.json"];
            _model_out_w = 512;
            _model_out_h = 512;
        }
        else{
            NSAssert(false, @"Error Style Type");
        }
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_GENERAL
    const void *argv[] = { [_stylizing_model UTF8String], [_stylizing_cfg UTF8String]};
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_General(&_handle, argc, argv);
#   endif
    
    size_t dataSize = _model_out_c *  _model_out_h * _model_out_w;
    _outBufferRGB = VnnU8BufferPtr(new VnnU8Buffer(dataSize));
    _outBufferRGBA = VnnU8BufferPtr(new VnnU8Buffer(dataSize + _model_out_h * _model_out_w));
    
    self.mtkView.mtltexture_offScreenImage= [self.mtkView generateOffScreenTextureWithFormat:MTLPixelFormatRGBA8Unorm width:_model_out_w height:_model_out_h];
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_GENERAL
    VNN_Destroy_General(&_handle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
#   if USE_GENERAL
    if (_handle > 0) {
        
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
        output.imgsArr[0].data = _outBufferRGB.get()->data;
        VNN_Apply_General_CPU(_handle, &input, NULL, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        convertRGBToRGBA(_outBufferRGB, _outBufferRGBA, _model_out_h * _model_out_w);
        
        [self.mtkView.mtltexture_offScreenImage
         replaceRegion:MTLRegionMake2D(0, 0, _model_out_w, _model_out_h)
         mipmapLevel:0
         withBytes:_outBufferRGBA.get()->data
         bytesPerRow:_model_out_w * 4];
        
        self.mtkView.mtltexture_BGRA = self.mtkView.mtltexture_offScreenImage;
    }
#   endif
}

@end
