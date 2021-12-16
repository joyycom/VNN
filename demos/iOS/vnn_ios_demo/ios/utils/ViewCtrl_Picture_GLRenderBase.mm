//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_GLRenderBase.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewCtrl_Picture_GLRenderBase ()

@end

@implementation ViewCtrl_Picture_GLRenderBase

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (void)dealloc {
    if (_cvGlTextureCache) {
        CFRelease(_cvGlTextureCache);
    }
}

- (void)loadView {
    [super loadView];
    [self.view setBackgroundColor:UIColorFromRGB(0x292a2f)];
    [self setup_gl];
    [self.view addSubview:self.glUtils];
    [self.view addSubview:self.btnCapture];
    [self.view addSubview:self.btnBack];
    self.supportVideoImporting = FALSE;
}

- (void)setup_gl {
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_cvGlTextureCache);
#else
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)self.glContext, NULL, &_cvGlTextureCache);
#endif
    if (ret) {
        printf("Error(%d) at CVOpenGLESTextureCacheCreate.\n", ret);
    }
    _glTexLoader = [[GLKTextureLoader alloc] initWithSharegroup:self.glContext.sharegroup];
}

- (UIButton *)btnBack {
    if (!_btnBack) {
        _btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnBack setFrame:CGRectMake((ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH) / 2 + SCREEN_WIDTH  * 0.1 / 9.0,
                                      (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 0.5 / 16.0 ,
                                      SCREEN_WIDTH  * 0.8 / 9.0,
                                      SCREEN_HEIGHT * 0.8 / 16.0
                                      )];
        [_btnBack setBackgroundColor:[UIColor clearColor]];
        [_btnBack setImage:[UIImage imageWithContentsOfFile:[[[[[NSBundle mainBundle] bundlePath]
                                                               stringByAppendingPathComponent:@"ui"]
                                                              stringByAppendingPathComponent:@"ViewCtrl_GLRenderBase"]
                                                             stringByAppendingPathComponent:@"btnBack.png"]]
                  forState:UIControlStateNormal];
        [_btnBack addTarget:self action:@selector(onBtnBack) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnBack;
}

- (void)onBtnBack {
    glFinish();
    [self dismissViewControllerAnimated:YES completion:^{ NSLog(@"Back to main View."); }];
}

- (UIButton *)btnCapture {
    if (!_btnCapture) {
        _btnCapture = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnCapture setFrame:CGRectMake((ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH) / 2 + SCREEN_WIDTH  * 3.5 / 9.0,
                                         (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 13 / 16.0 ,
                                         SCREEN_WIDTH  * 2 / 9.0,
                                         SCREEN_HEIGHT * 2 / 16.0)];
        [_btnCapture setBackgroundColor:[UIColor clearColor]];
        [_btnCapture setImage:[UIImage imageWithContentsOfFile:[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ui"] stringByAppendingPathComponent:@"ViewCtrl_GLRenderBase"] stringByAppendingPathComponent:@"btnCaptureLight.png"]] forState:UIControlStateHighlighted];
        [_btnCapture setImage:[UIImage imageWithContentsOfFile:[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ui"] stringByAppendingPathComponent:@"ViewCtrl_GLRenderBase"] stringByAppendingPathComponent:@"btnCaputreDark.png"]] forState:UIControlStateNormal];
        [_btnCapture addTarget:self action:@selector(onBtnCapture) forControlEvents:UIControlEventTouchUpInside];
        _btnCapture.layer.cornerRadius = 4.0f;
    }
    return _btnCapture;
}

- (void)onBtnCapture {
    UIAlertController *uialertctrl = [UIAlertController alertControllerWithTitle:@"Select Source" message:@"select a media source from ..." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *selectCameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        printf("Selected Camera.\n");
        //        [self.captureSession stopRunning];
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;
        imagePicker.allowsEditing = NO;
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        if(self->_supportVideoImporting){
            imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }
        else{
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    UIAlertAction *selectPhotoLibraryAction = [UIAlertAction actionWithTitle:@"PhotoLibrary" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        printf("Selected PhotoLibrary.\n");
        //        [self.captureSession stopRunning];
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = NO;
        if(self->_supportVideoImporting){
            imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }
        else{
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    UIAlertAction *selectAlbumAction = [UIAlertAction actionWithTitle:@"Album" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        printf("Selected Album.\n");
        //        [self.captureSession stopRunning];
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePicker.allowsEditing = NO;
        if(self->_supportVideoImporting){
            imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }
        else{
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Cancel Action");
    }];
    [uialertctrl addAction:selectCameraAction];
    [uialertctrl addAction:selectPhotoLibraryAction];
    [uialertctrl addAction:selectAlbumAction];
    [uialertctrl addAction:cancelAction];
    [self presentViewController:uialertctrl animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqual:@"public.image"]) {
        // process image ...
        UIImage *oriImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        UIImage *fixedImage = [DemoHelper fixOrientation:oriImage];
        UIImage *resizedImage = [DemoHelper resizePad:fixedImage withHeight:FIX_IMAGE_WIDTH withWidth:FIX_IMAGE_HEIGHT];
        
        if(_imageBuffer){
            CVPixelBufferRelease(_imageBuffer);
            _imageBuffer = nil;
        }
        
        _imageBuffer = [DemoHelper CVPixelBufferRefFromUiImage:resizedImage];
        [self initWithCVPixelBufferRef:_imageBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self imageCaptureCallback:self->_imageBuffer];
        });
    }
    else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqual:@"public.movie"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self videoCaptureCallback:[info objectForKey:UIImagePickerControllerMediaURL]];
        });
    }
    else {
        assert(false && "Unknow UIImagePickerControllerMediaType");
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIView_GLRenderUtils *)glUtils {
    if (!_glUtils) {
        _glUtils = [[UIView_GLRenderUtils alloc] init_With_Frame:CGRectMake((ACTUAL_SCREEN_WIDTH - SCREEN_WIDTH) / 2,
                                                                            (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2,
                                                                            SCREEN_WIDTH,
                                                                            SCREEN_HEIGHT)
                                                     EAGLContext:self.glContext];
    }
    return _glUtils;
}

- (void)videoCaptureCallback:(NSURL *)videoURL {

}

- (void)imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {
    
}

- (void)initWithCVPixelBufferRef:(CVPixelBufferRef)pixelBuffer {
    //check if _cvGlTextureCache is nil
    if (!_cvGlTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    
    //clean up textures
    //    if (_gltexture_Y) {
    //        CFRelease(_gltexture_Y);
    //        _gltexture_Y = NULL;
    //    }
    //    if (_gltexture_CbCr) {
    //        CFRelease(_gltexture_CbCr);
    //        _gltexture_CbCr = NULL;
    //    }
    if (_gltexture_BGRA) {
        CFRelease(_gltexture_BGRA);
        _gltexture_BGRA = NULL;
    }
    
    if (!_NSYTex) {
        _NSYTex = std::make_shared<VnGlTexture>();
    }
    if (!_NSUVTex) {
        _NSUVTex = std::make_shared<VnGlTexture>();
    }
    if (!_NSBGRATex) {
        _NSBGRATex = std::make_shared<VnGlTexture>();
    }
    
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _cvGlTextureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)width,
                                                                (GLsizei)height,
                                                                GL_RGBA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &_gltexture_BGRA);
    
    if (err) {
        printf("CVOpenGLESTextureCacheCreate failed. err(%d).\n", err);
    }
    glBindTexture(CVOpenGLESTextureGetTarget(_gltexture_BGRA), CVOpenGLESTextureGetName(_gltexture_BGRA));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    _NSBGRATex->_target = GL_TEXTURE_2D;
    _NSBGRATex->_format = GL_RGBA;
    _NSBGRATex->_width = (int)width;
    _NSBGRATex->_height = (int)height;
    _NSBGRATex->_handle = CVOpenGLESTextureGetName(_gltexture_BGRA);
}

-(void)setNoticewithTitle:(NSString *)title Massage:(NSString *)massage{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:massage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
