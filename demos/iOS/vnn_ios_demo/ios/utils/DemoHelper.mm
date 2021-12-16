//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "DemoHelper.h"
#import <fstream>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <map>

@implementation DemoHelper

+ (float)getCpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0) {
        stat_thread += thread_count;
    }
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

+ (float)getCpuFrequency {
    volatile NSTimeInterval times[500] = {0.0};
    
    int sum = 0;
    
    for (int i = 0; i < 20; i++)
    {
        times[i] = [[NSProcessInfo processInfo] systemUptime];
        int count = 10000;
#if __ARM_NEON
#if __aarch64__
        __asm volatile(
                       "0:"
                       //loop 1
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 2
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 3
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 4
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 5
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 6
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 7
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 8
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop 9
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       //loop q10
                       "add     x2, x2, x1 \n"
                       "add     x3, x3, x2 \n"
                       "add     x4, x4, x3 \n"
                       "add     x5, x5, x4 \n"
                       "add     x6, x6, x5 \n"
                       "add     x7, x7, x6 \n"
                       "add     x8, x8, x7 \n"
                       "add     x9, x9, x8 \n"
                       "add     x10, x10, x9 \n"
                       "add     x11, x11, x10 \n"
                       "add     x12, x12, x11 \n"
                       "add     x14, x14, x12 \n"
                       "add     x1, x1, x14 \n"
                       
                       "subs %x0, %x0, #1 \n"
                       "bne            0b\n"
                       
                       :
                       "=r"(count)
                       :
                       "0"(count)
                       : "cc", "memory", "x1", "x2", "x3","x4", "x5",  "x6", "x7", "x8","x9", "x10",  "x11", "x12", "x13","x14"
                       );
#else
        assert(false && "Not implemented");
#endif // __aarch64__
#else
        assert(false && "Not implemented");
#endif // __ARM_NEON
        times[i] = 1000.0*([[NSProcessInfo processInfo] systemUptime] - times[i]);//for ms
    }
    
    NSTimeInterval total_time = 0.0;
    NSTimeInterval time = 10.0;
    for (int i = 0; i < 50; i++) {
        total_time += times[i];
        if (time > times[i] && times[i] > 0.1 && times[i] < 2.0) {
            time = times[i];
        }
    }
    
    double freq = 1300000.0 / time * 1000.0;
    return freq;
}

+ (CGImageRef) imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer CPUorGPU:(BOOL)xpu {
    if (xpu) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        size_t width, height, bytesPerRow;
        width = CVPixelBufferGetWidth(pixelBuffer);
        height = CVPixelBufferGetHeight(pixelBuffer);
        bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        CGColorSpaceRef colorSpace;
        CGContextRef cgContext;
        colorSpace = CGColorSpaceCreateDeviceRGB();
        cgContext = CGBitmapContextCreate((uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer),
                                          width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        CGImageRef cgImage;
        
        cgImage = CGBitmapContextCreateImage(cgContext);
        
        CGContextRelease(cgContext);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        return cgImage;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    CGRect rect = CGRectMake(0, 0, width, height);
    CIImage *ciimage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [[CIContext alloc] init];
    CGImageRef cgImage = [context createCGImage:ciimage fromRect:rect];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    return cgImage;
}

+ (NSString *)getDeviceHardwareInfo {
    struct utsname systemInfo;
    uname(&systemInfo);
    std::map<std::string, std::string> machine_to_hardwareinfo = {
        // Simulator Series
        {"i386",   "iPhone Simulator"},
        {"x86_64", "iPhone Simulator"},
        // iPhone Series
        {"iPhone1,1",  "iPhone"},
        {"iPhone1,2",  "iPhone 3G"},
        {"iPhone2,1",  "iPhone 3GS1"},
        {"iPhone3,1",  "iPhone 4"},
        {"iPhone3,2",  "iPhone 4 GSM Rev A"},
        {"iPhone3,3",  "iPhone 4 CDMA"},
        {"iPhone4,1",  "iPhone 4S"},
        {"iPhone5,1",  "iPhone 5 (GSM)"},
        {"iPhone5,2",  "iPhone 5 (GSM+CDMA)"},
        {"iPhone5,3",  "iPhone 5C (GSM)"},
        {"iPhone5,4",  "iPhone 5C (Global)"},
        {"iPhone6,1",  "iPhone 5S (GSM)"},
        {"iPhone6,2",  "iPhone 5S (Global)"},
        {"iPhone7,1",  "iPhone 6 Plus"},
        {"iPhone7,2",  "iPhone 6"},
        {"iPhone8,1",  "iPhone 6s"},
        {"iPhone8,2",  "iPhone 6s Plus"},
        {"iPhone8,4",  "iPhone SE (GSM)"},
        {"iPhone9,1",  "iPhone 7"},
        {"iPhone9,2",  "iPhone 7 Plus"},
        {"iPhone9,3",  "iPhone 7"},
        {"iPhone9,4",  "iPhone 7 Plus"},
        {"iPhone10,1", "iPhone 8"},
        {"iPhone10,2", "iPhone 8 Plus"},
        {"iPhone10,3", "iPhone X Global"},
        {"iPhone10,4", "iPhone 8"},
        {"iPhone10,5", "iPhone 8 Plus"},
        {"iPhone10,6", "iPhone X GSM"},
        {"iPhone11,2", "iPhone XS"},
        {"iPhone11,4", "iPhone XS Max"},
        {"iPhone11,6", "iPhone XS Max Global"},
        {"iPhone11,8", "iPhone XR"},
        {"iPhone12,1", "iPhone 11"},
        {"iPhone12,3", "iPhone 11 Pro"},
        {"iPhone12,5", "iPhone 11 Pro Max"},
        {"iPhone12,8", "iPhone SE 2nd Gen"},
        // iPod Series
        {"iPod1,1", "1st Gen iPod"},
        {"iPod2,1", "2nd Gen iPod"},
        {"iPod3,1", "3rd Gen iPod"},
        {"iPod4,1", "4th Gen iPod"},
        {"iPod5,1", "5th Gen iPod"},
        {"iPod7,1", "6th Gen iPod"},
        {"iPod9,1", "7th Gen iPod"},
        // iPad Series
        {"iPad1,1",  "iPad"},
        {"iPad1,2",  "iPad 3G"},
        {"iPad2,1",  "2nd Gen iPad"},
        {"iPad2,2",  "2nd Gen iPad GSM"},
        {"iPad2,3",  "2nd Gen iPad CDMA"},
        {"iPad2,4",  "2nd Gen iPad New Revision"},
        {"iPad3,1",  "3rd Gen iPad"},
        {"iPad3,2",  "3rd Gen iPad CDMA"},
        {"iPad3,3",  "3rd Gen iPad GSM"},
        {"iPad2,5",  "iPad mini"},
        {"iPad2,6",  "iPad mini GSM+LTE"},
        {"iPad2,7",  "iPad mini CDMA+LTE"},
        {"iPad3,4",  "4th Gen iPad"},
        {"iPad3,5",  "4th Gen iPad GSM+LTE"},
        {"iPad3,6",  "4th Gen iPad CDMA+LTE"},
        {"iPad4,1",  "iPad Air (WiFi)"},
        {"iPad4,2",  "iPad Air (GSM+CDMA)"},
        {"iPad4,3",  "1st Gen iPad Air (China)"},
        {"iPad4,4",  "iPad mini Retina (WiFi)"},
        {"iPad4,5",  "iPad mini Retina (GSM+CDMA)"},
        {"iPad4,6",  "iPad mini Retina (China)"},
        {"iPad4,7",  "iPad mini 3 (WiFi)"},
        {"iPad4,8",  "iPad mini 3 (GSM+CDMA)"},
        {"iPad4,9",  "iPad Mini 3 (China)"},
        {"iPad5,1",  "iPad mini 4 (WiFi)"},
        {"iPad5,2",  "4th Gen iPad mini (WiFi+Cellular)"},
        {"iPad5,3",  "iPad Air 2 (WiFi)"},
        {"iPad5,4",  "iPad Air 2 (Cellular)"},
        {"iPad6,3",  "iPad Pro (9.7 inch, WiFi)"},
        {"iPad6,4",  "iPad Pro (9.7 inch, WiFi+LTE)"},
        {"iPad6,7",  "iPad Pro (12.9 inch, WiFi)"},
        {"iPad6,8",  "iPad Pro (12.9 inch, WiFi+LTE)"},
        {"iPad6,11", "iPad (2017)"},
        {"iPad6,12", "iPad (2017)"},
        {"iPad7,1",  "iPad Pro 2nd Gen (WiFi)"},
        {"iPad7,2",  "iPad Pro 2nd Gen (WiFi+Cellular)"},
        {"iPad7,3",  "iPad Pro 10.5-inch"},
        {"iPad7,4",  "iPad Pro 10.5-inch"},
        {"iPad7,5",  "iPad 6th Gen (WiFi)"},
        {"iPad7,6",  "iPad 6th Gen (WiFi+Cellular)"},
        {"iPad7,11", "iPad 7th Gen 10.2-inch (WiFi)"},
        {"iPad7,12", "iPad 7th Gen 10.2-inch (WiFi+Cellular)"},
        {"iPad8,1",  "iPad Pro 11 inch (WiFi)"},
        {"iPad8,2",  "iPad Pro 11 inch (1TB, WiFi)"},
        {"iPad8,3",  "iPad Pro 11 inch (WiFi+Cellular)"},
        {"iPad8,4",  "iPad Pro 11 inch (1TB, WiFi+Cellular)"},
        {"iPad8,5",  "iPad Pro 12.9 inch 3rd Gen (WiFi)"},
        {"iPad8,6",  "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)"},
        {"iPad8,7",  "iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)"},
        {"iPad8,8",  "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)"},
        {"iPad8,9",  "iPad Pro 11 inch 2nd Gen (WiFi)"},
        {"iPad8,10", "iPad Pro 11 inch 2nd Gen (WiFi+Cellular)"},
        {"iPad8,11", "iPad Pro 12.9 inch 4th Gen (WiFi)"},
        {"iPad8,12", "iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)"},
        {"iPad11,1", "iPad mini 5th Gen (WiFi)"},
        {"iPad11,2", "iPad mini 5th Gen"},
        {"iPad11,3", "iPad Air 3rd Gen (WiFi)"},
        {"iPad11,4", "iPad Air 3rd Gen"},
        // Apple Watch Series
        {"Watch1,1", "Apple Watch 38mm case"},
        {"Watch1,2", "Apple Watch 42mm case"},
        {"Watch2,6", "Apple Watch Series 1 38mm case"},
        {"Watch2,7", "Apple Watch Series 1 42mm case"},
        {"Watch2,3", "Apple Watch Series 2 38mm case"},
        {"Watch2,4", "Apple Watch Series 2 42mm case"},
        {"Watch3,1", "Apple Watch Series 3 38mm case (GPS+Cellular)"},
        {"Watch3,2", "Apple Watch Series 3 42mm case (GPS+Cellular)"},
        {"Watch3,3", "Apple Watch Series 3 38mm case (GPS)"},
        {"Watch3,4", "Apple Watch Series 3 42mm case (GPS)"},
        {"Watch4,1", "Apple Watch Series 4 40mm case (GPS)"},
        {"Watch4,2", "Apple Watch Series 4 44mm case (GPS)"},
        {"Watch4,3", "Apple Watch Series 4 40mm case (GPS+Cellular)"},
        {"Watch4,4", "Apple Watch Series 4 44mm case (GPS+Cellular)"},
        {"Watch5,1", "Apple Watch Series 5 40mm case (GPS)"},
        {"Watch5,2", "Apple Watch Series 5 44mm case (GPS)"},
        {"Watch5,3", "Apple Watch Series 5 40mm case (GPS+Cellular)"},
        {"Watch5,4", "Apple Watch Series 5 44mm case (GPS+Cellular)"},
    };
    NSString *platform = [NSString stringWithUTF8String:machine_to_hardwareinfo[systemInfo.machine].c_str()];
    return platform;
}

+ (id<MTLTexture>)UIImage2MTLTexture_With_UIImage:(UIImage *)uiimage
                                        MTLDevice:(id<MTLDevice>)mtlDev
                                   MTLTextureType:(MTLTextureType)mtlTexType
                                   MTLPixelFormat:(MTLPixelFormat)mtlPixFormat
                                         IfMipmap:(BOOL)ifMipmap
                                           IfFlip:(BOOL)ifFlip
{
    if (!uiimage) {
        return  nil;
    }
    
    size_t width = CGImageGetWidth(uiimage.CGImage);
    size_t height = CGImageGetHeight(uiimage.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    imgContext = CGBitmapContextCreate(NULL,
                                                       width,
                                                       height,
                                                       8,
                                                       width * 4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (!imgContext) {
        return nil;
    }
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, width, height);
    CGContextClearRect(imgContext, bounds);
    
    if (ifFlip) {
        CGContextTranslateCTM(imgContext, width, height);
        CGContextScaleCTM(imgContext, -1.0, -1.0);
    }
    
    CGContextDrawImage(imgContext, bounds, uiimage.CGImage);
    
    id<MTLTexture> texture = [mtlDev newTextureWithDescriptor:[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:mtlPixFormat width:width height:height mipmapped:ifMipmap]];
    
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
               mipmapLevel:0
                 withBytes:CGBitmapContextGetData(imgContext)
               bytesPerRow:width * 4];
    
    CGContextRelease(imgContext);
    
    return texture;
}

+ (UIImage *)scaleToSize_WithUIImage:(UIImage *)img Size:(CGSize)size
{
    // Scalling selected image to targeted size
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    if (img.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM(context, -M_PI_2);
        CGContextTranslateCTM(context, -size.height, 0.0f);
        CGContextDrawImage(context, CGRectMake(0, 0, size.height, size.width), img.CGImage);
    }
    else {
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), img.CGImage);
    }
    CGImageRef scaledImage=CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    UIImage *image = [UIImage imageWithCGImage: scaledImage];
    CGImageRelease(scaledImage);
    return image;
}

+ (bool)compileShader_With_ShaderHandle:(GLuint *)shader ShadeType:(GLenum)type ShaderContent:(NSString *)content
{
    //get utf8 type string(char *)
    const GLchar *content_utf8 = [content UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &content_utf8, NULL);
    glCompileShader(*shader);
    
    GLint status;
    
#ifdef VN_DEBUG
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log: \n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (0 == status) {
        glDeleteShader(*shader);
        return false;
    }
    
    return true;
}

+ (GLuint)loadShaders_With_VertexShader:(NSString *)vsPath FragmentShader:(NSString *)fsPath
{
    GLuint vertShaderHandle, fragShaderHandle;
    GLint program = glCreateProgram();
    NSError *error;
    
    if (vsPath) {
        //load vs file:
        //read nsstring from a file:
        NSString *content = [NSString stringWithContentsOfFile:vsPath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"Error: fail to read the file {%@}", vsPath);
        }
        //compile
        bool ifsucceed = [self compileShader_With_ShaderHandle:&vertShaderHandle ShadeType:GL_VERTEX_SHADER ShaderContent:content];
        if (!ifsucceed) {
            NSLog(@"Error: fail to compile the file {%@}", vsPath);
        }
        //attach to program handle
        glAttachShader(program, vertShaderHandle);
        //release unused shader handle
        glDeleteShader(vertShaderHandle);
    }
    
    if (fsPath) {
        //load fs file:
        //read nsstring from a file:
        NSString *content = [NSString stringWithContentsOfFile:fsPath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"Error: fail to read the file {%@}", fsPath);
        }
        //compile
        bool ifsucceed = [self compileShader_With_ShaderHandle:&fragShaderHandle ShadeType:GL_FRAGMENT_SHADER ShaderContent:content];
        if (!ifsucceed) {
            NSLog(@"Error: fail to compile the file {%@}", fsPath);
        }
        //attach to program handle
        glAttachShader(program, fragShaderHandle);
        //release unused shader handle
        glDeleteShader(fragShaderHandle);
    }
    
    return program;
}

+ (bool)linkProgram:(GLuint)program
{
    glLinkProgram(program);
    
#ifdef VN_DEBUG
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error(%@) in link the program.", messageString);
        return false;
    }
    NSLog(@"link ok");
    glUseProgram(program);
    return true;
}

+ (bool)createPixelBufferPool:(CVPixelBufferPoolRef *)pool width:(int)width height:(int)height
{
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL, NULL, 0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    
    SInt32 cvPixelFormatTypeValue = kCVPixelFormatType_32BGRA;
    CFNumberRef cfPixelFormat = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void *)(&(cvPixelFormatTypeValue)));
    
    SInt32 cvWidthValue = width;
    CFNumberRef cfWidth = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void *)(&(cvWidthValue)));
    SInt32 cvHeightValue = height;
    CFNumberRef cfHeight = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void *)(&(cvHeightValue)));
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      4,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(attrs, kCVPixelBufferPixelFormatTypeKey, cfPixelFormat);
    CFDictionarySetValue(attrs, kCVPixelBufferWidthKey, cfWidth);
    CFDictionarySetValue(attrs, kCVPixelBufferHeightKey, cfHeight);
    
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attrs, pool);
    
    CFRelease(attrs);
    CFRelease(empty);
    CFRelease(cfPixelFormat);
    CFRelease(cfWidth);
    CFRelease(cfHeight);
    
    if (ret != kCVReturnSuccess) {
        return false;
    }
    
    return true;
}

+ (void)destroyPixelBufferPool:(CVPixelBufferPoolRef *)pool {
    CVPixelBufferPoolRelease(*pool);
    *pool = nil;
}

+ (CVPixelBufferRef)imageToYUVPixelBuffer:(UIImage *)image {
#if 0
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height,kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)options,&pxbuffer);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddressOfPlane(pxbuffer,0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height,8,CVPixelBufferGetBytesPerRowOfPlane(pxbuffer, 0),colorSpace,kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image.CGImage),CGImageGetHeight(image.CGImage)), image.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
#endif
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image.CGImage),CGImageGetHeight(image.CGImage));
    NSDictionary *options =
    [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,[NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status =
    CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height,kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height,8, CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image.CGImage),CGImageGetHeight(image.CGImage)), image.CGImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

+ (NSArray *)getPathList:(NSString *)list_path {
    NSMutableArray *arr = [NSMutableArray array];
    std::ifstream listfile(list_path.UTF8String);
    std::string fileanme;
    while (std::getline(listfile, fileanme)) {
        [arr addObject:[NSString stringWithFormat:@"%s",fileanme.c_str()]];
    }
    listfile.close();
    return [NSArray arrayWithArray:arr];
}

+ (NSString *)getWLANIpAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    CGSize frameSize = CGSizeMake(CGImageGetWidth(img.CGImage),CGImageGetHeight(img.CGImage));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,
                             @{}, kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status =
    CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height,kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height,8, CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(img.CGImage),CGImageGetHeight(img.CGImage)), img.CGImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}


+ (void) resizeBilinear_U8_C3_Image:(unsigned char *)src srch:(int)srch srcw: (int)srcw dstImage:(unsigned char *)dst dsth:(int)dsth dstw: (int)dstw
{

#define SATURATE_CAST_SHORT(X) (short)::std::min(::std::max((int)(X + (X >= 0.f ? 0.5f : -0.5f)), SHRT_MIN), SHRT_MAX)
#define Align4Up(X) (((X + 3) >> 2) << 2)
    
    const int INTER_RESIZE_COEF_BITS=11;
    const int INTER_RESIZE_COEF_SCALE=1 << INTER_RESIZE_COEF_BITS;

    double scale_x = (double)srcw / dstw;
    double scale_y = (double)srch / dsth;

    int* buf = (int *)calloc(dstw + dsth + dstw + dsth, sizeof(int));
    
    int* xofs = buf;//new int[w];
    int* yofs = buf + dstw;//new int[h];

    short* ialpha = (short*)(buf + dstw + dsth);//new short[w * 2];
    short* ibeta = (short*)(buf + dstw + dsth + dstw);//new short[h * 2];

    float fx;
    float fy;
    int sx;
    int sy;


    for (int dx = 0; dx < dstw; dx++) {
        fx = (float)((dx + 0.5) * scale_x - 0.5);
        sx = floor(fx);
        fx -= sx;

        if (sx < 0) {
            sx = 0;
            fx = 0.f;
        }
        if (sx >= srcw - 1) {
            sx = srcw - 2;
            fx = 1.f;
        }

        xofs[dx] = sx*3;

        float a0 = (1.f - fx) * INTER_RESIZE_COEF_SCALE;
        float a1 =        fx  * INTER_RESIZE_COEF_SCALE;

        ialpha[dx*2    ] = SATURATE_CAST_SHORT(a0);
        ialpha[dx*2 + 1] = SATURATE_CAST_SHORT(a1);
    }

    for (int dy = 0; dy < dsth; dy++) {
        fy = (float)((dy + 0.5) * scale_y - 0.5);
        sy = floor(fy);
        fy -= sy;

        if (sy < 0) {
            sy = 0;
            fy = 0.f;
        }
        if (sy >= srch - 1) {
            sy = srch - 2;
            fy = 1.f;
        }

        yofs[dy] = sy*3;

        float b0 = (1.f - fy) * INTER_RESIZE_COEF_SCALE;
        float b1 =        fy  * INTER_RESIZE_COEF_SCALE;

        ibeta[dy*2    ] = SATURATE_CAST_SHORT(b0);
        ibeta[dy*2 + 1] = SATURATE_CAST_SHORT(b1);
    }

    short* rows0 = (short*)malloc( Align4Up( (dstw*3 >> 1) + 3 ) * sizeof(float) ); // rowsbuf0.data;
    short* rows1 = (short*)malloc( Align4Up( (dstw*3 >> 1) + 3 ) * sizeof(float) ); // rowsbuf1.data;

    int prev_sy1 = -1;

    for (int dy = 0; dy < dsth; dy++ ) {
        int sy = yofs[dy];

        if (sy == prev_sy1) {
            // hresize one row
            short* rows0_old = rows0;
            rows0 = rows1;
            rows1 = rows0_old;
            const unsigned char *S1 = src + srcw * (sy+3);

            const short* ialphap = ialpha;
            short* rows1p = rows1;
            for ( int dx = 0; dx < dstw; dx++ ) {
                int sx = xofs[dx];
                short a0 = ialphap[0];
                short a1 = ialphap[1];

                const unsigned char* S1p = S1 + sx;

                rows1p[0] = (S1p[0]*a0 + S1p[3]*a1) >> 4;
                rows1p[1] = (S1p[1]*a0 + S1p[4]*a1) >> 4;
                rows1p[2] = (S1p[2]*a0 + S1p[5]*a1) >> 4;

                ialphap += 2;
                rows1p += 3;
            }
        }
        else {
            // hresize two rows
            const unsigned char *S0 = src + srcw * (sy);
            const unsigned char *S1 = src + srcw * (sy+3);

            const short* ialphap = ialpha;
            short* rows0p = rows0;
            short* rows1p = rows1;
            for ( int dx = 0; dx < dstw; dx++ ) {
                int sx = xofs[dx];
                short a0 = ialphap[0];
                short a1 = ialphap[1];

                const unsigned char* S0p = S0 + sx;
                const unsigned char* S1p = S1 + sx;

                rows0p[0] = (S0p[0]*a0 + S0p[3]*a1) >> 4;
                rows0p[1] = (S0p[1]*a0 + S0p[4]*a1) >> 4;
                rows0p[2] = (S0p[2]*a0 + S0p[5]*a1) >> 4;
                rows1p[0] = (S1p[0]*a0 + S1p[3]*a1) >> 4;
                rows1p[1] = (S1p[1]*a0 + S1p[4]*a1) >> 4;
                rows1p[2] = (S1p[2]*a0 + S1p[5]*a1) >> 4;

                ialphap += 2;
                rows0p += 3;
                rows1p += 3;
            }
        }

        prev_sy1 = sy + 1;

        // vresize
        short b0 = ibeta[0];
        short b1 = ibeta[1];

        short* rows0p = rows0;
        short* rows1p = rows1;
        unsigned char* Dp = dst + dstw * 3 * (dy);
        
        int nn = 0;
        int remain = (dstw * 3) - (nn << 3);

        for ( ; remain; --remain ) {
            *Dp++ = (unsigned char)(( (short)((b0 * (short)(*rows0p++)) >> 16) + (short)((b1 * (short)(*rows1p++)) >> 16) + 2)>>2);
        }

        ibeta += 2;
    }

    free(rows0);
    free(rows1);
    free(buf);
#undef SATURATE_CAST_SHORT
#undef Align4Up
}

+ (void) resizeBilinear_U8_C1_Image:(unsigned char *)src srch:(int)srch srcw: (int)srcw dstImage:(unsigned char *)dst dsth:(int)dsth dstw: (int)dstw
{
    
#define SATURATE_CAST_SHORT(X) (short)::std::min(::std::max((int)(X + (X >= 0.f ? 0.5f : -0.5f)), SHRT_MIN), SHRT_MAX)
    
#define Align4Up(X) (((X + 3) >> 2) << 2)
    
    const int INTER_RESIZE_COEF_BITS=11;
    const int INTER_RESIZE_COEF_SCALE=1 << INTER_RESIZE_COEF_BITS;
    
    double scale_y = double(srch) / dsth;
    double scale_x = double(srcw) / dstw;
    
    int* buf = (int *)calloc(dstw + dsth + dstw + dsth, sizeof(int));
    
    int* xofs = buf;//new int[w];
    int* yofs = buf + dstw;//new int[h];
    
    short* ialpha = (short*)(buf + dstw + dsth);//new short[w * 2];
    short* ibeta = (short*)(buf + dstw + dsth + dstw);//new short[h * 2];
    
    float fx;
    float fy;
    int sx;
    int sy;
    
    for (int dx = 0; dx < dstw; dx++) {
        fx = (float)((dx + 0.5) * scale_x - 0.5);
        sx = floor(fx);
        fx -= sx;
        
        if (sx < 0) {
            sx = 0;
            fx = 0.f;
        }
        if (sx >= srcw - 1) {
            sx = srcw - 2;
            fx = 1.f;
        }
        
        xofs[dx] = sx;
        
        float a0 = (1.f - fx) * INTER_RESIZE_COEF_SCALE;
        float a1 =        fx  * INTER_RESIZE_COEF_SCALE;
        
        ialpha[dx*2    ] = SATURATE_CAST_SHORT(a0);
        ialpha[dx*2 + 1] = SATURATE_CAST_SHORT(a1);
    }
    
    for (int dy = 0; dy < dsth; dy++) {
        fy = (float)((dy + 0.5) * scale_y - 0.5);
        sy = floor(fy);
        fy -= sy;
        
        if (sy < 0) {
            sy = 0;
            fy = 0.f;
        }
        if (sy >= srch - 1) {
            sy = srch - 2;
            fy = 1.f;
        }
        
        yofs[dy] = sy;
        
        float b0 = (1.f - fy) * INTER_RESIZE_COEF_SCALE;
        float b1 =        fy  * INTER_RESIZE_COEF_SCALE;
        
        ibeta[dy*2    ] = SATURATE_CAST_SHORT(b0);
        ibeta[dy*2 + 1] = SATURATE_CAST_SHORT(b1);
    }
    
    short* rows0 = (short*)malloc( Align4Up((dstw >> 1) + 1) * sizeof(float) ); // rowsbuf0.data;
    short* rows1 = (short*)malloc( Align4Up((dstw >> 1) + 1) * sizeof(float) ); // rowsbuf1.data;
    
    int prev_sy1 = -1;
    
    for (int dy = 0; dy < dsth; dy++ ) {
        
        int sy = yofs[dy];
        
        if (sy == prev_sy1) {
            // hresize one row
            short* rows0_old = rows0;
            rows0 = rows1;
            rows1 = rows0_old;
            const unsigned char *S1 = src + srcw * (sy+1);
            
            const short* ialphap = ialpha;
            short* rows1p = rows1;
            for ( int dx = 0; dx < dstw; dx++ ) {
                int sx = xofs[dx];
                short a0 = ialphap[0];
                short a1 = ialphap[1];
                
                const unsigned char* S1p = S1 + sx;
                rows1p[dx] = (S1p[0]*a0 + S1p[1]*a1) >> 4;
                
                ialphap += 2;
            }
        }
        else {
            // hresize two rows
            const unsigned char *S0 = src + srcw * (sy);
            const unsigned char *S1 = src + srcw * (sy+1);
            
            const short* ialphap = ialpha;
            short* rows0p = rows0;
            short* rows1p = rows1;
            for ( int dx = 0; dx < dstw; dx++ ) {
                int sx = xofs[dx];
                short a0 = ialphap[0];
                short a1 = ialphap[1];
                
                const unsigned char* S0p = S0 + sx;
                const unsigned char* S1p = S1 + sx;
                rows0p[dx] = (S0p[0]*a0 + S0p[1]*a1) >> 4;
                rows1p[dx] = (S1p[0]*a0 + S1p[1]*a1) >> 4;
                
                ialphap += 2;
            }
        }
        
        prev_sy1 = sy + 1;
        
        // vresize
        short b0 = ibeta[0];
        short b1 = ibeta[1];
        
        short* rows0p = rows0;
        short* rows1p = rows1;
        unsigned char* Dp = dst + dstw * (dy);
        
        int nn = 0;
        int remain = dstw - (nn << 3);
        
        for ( ; remain; --remain ) {
            *Dp++ = (unsigned char)(( (short)((b0 * (short)(*rows0p++)) >> 16) + (short)((b1 * (short)(*rows1p++)) >> 16) + 2)>>2);
        }
        
        ibeta += 2;
    }
    
    free(rows0);
    free(rows1);
    free(buf);
#undef SATURATE_CAST_SHORT
#undef Align4Up
}

+ (unsigned char *) allocMaskBy:(const VNN_Image &)faceMask
                        onImage:(const VNN_Image &) frameImg {
    
    // map maskRect to frameImg coords
    float crop_left_f = faceMask.rect.x0;
    float crop_top_f = faceMask.rect.y0;
    float crop_right_f = faceMask.rect.x1;
    float crop_bottom_f = faceMask.rect.y1;
    int crop_left_int = (int(crop_left_f * frameImg.width) >> 1) << 1;
    int crop_top_int = (int(crop_top_f * frameImg.height) >> 1) << 1;
    int crop_right_int = (int(crop_right_f * frameImg.width) >> 1) << 1;
    int crop_bottom_int = (int(crop_bottom_f * frameImg.height) >> 1) << 1;
    int crop_width = crop_right_int - crop_left_int + 1;
    int crop_height = crop_bottom_int - crop_top_int + 1;
    unsigned int crop_left_onImage = std::min(std::max(crop_left_int, 0), frameImg.width-1);
    unsigned int crop_top_onImage = std::min(std::max(crop_top_int, 0), frameImg.height-1);
    unsigned int crop_right_onImage = std::min(std::max(crop_right_int, 0), frameImg.width-1);
    unsigned int crop_bottom_onImage = std::min(std::max(crop_bottom_int, 0), frameImg.height-1);
    
    unsigned char *resizedMask = (unsigned char *) malloc(crop_width * crop_height);
    if (!resizedMask) {
        printf("resizedMask malloc failed\n");
        NSAssert(false, @"Error malloc resizedMask");
        return nil;
    }
    
    //     resize mask.data to resizedMask
    [self resizeBilinear_U8_C1_Image:(unsigned char*)faceMask.data srch:faceMask.height srcw:faceMask.width dstImage:resizedMask dsth:crop_height dstw:crop_width];
    
    unsigned char *maskOnImage = (unsigned char *) malloc(frameImg.width * frameImg.height);
    if (!maskOnImage) {
        printf("resizedMask malloc failed\n");
        NSAssert(maskOnImage != nil, @"Error malloc maskOnImage");
        return nil;
    }
    
    memset(maskOnImage, 0, frameImg.width * frameImg.height);
    int crop_left_onMask = crop_left_int < 0 ? 0 - crop_left_int : 0;
    int crop_top_onMask = crop_top_int < 0 ? 0 - crop_top_int : 0;
    int crop_width_onImage = crop_right_onImage - crop_left_onImage + 1;
    for (int h = 0; h < frameImg.height; ++h) {
        if (h < crop_top_onImage)    { continue; }
        if (h > crop_bottom_onImage) { break; }
        int h_onMask = (h - crop_top_onImage) + crop_top_onMask;
        memcpy(maskOnImage + h * frameImg.width + crop_left_onImage,
               resizedMask +  h_onMask * crop_width + crop_left_onMask,
               crop_width_onImage);
    }
    
    if (resizedMask) {
        free(resizedMask);
        resizedMask = nil;
    }
    
    return maskOnImage;
}

+ (unsigned char *) allocRGBFaceBy:(const VNN_Image &)faceData
                        onImage:(const VNN_Image &) frameImg {
    
    // map maskRect to frameImg coords
    float crop_left_f = faceData.rect.x0;
    float crop_top_f = faceData.rect.y0;
    float crop_right_f = faceData.rect.x1;
    float crop_bottom_f = faceData.rect.y1;
    int crop_left_int = (int(crop_left_f * frameImg.width) >> 1) << 1;
    int crop_top_int = (int(crop_top_f * frameImg.height) >> 1) << 1;
    int crop_right_int = (int(crop_right_f * frameImg.width) >> 1) << 1;
    int crop_bottom_int = (int(crop_bottom_f * frameImg.height) >> 1) << 1;
    int crop_width = crop_right_int - crop_left_int + 1;
    int crop_height = crop_bottom_int - crop_top_int + 1;
    unsigned int crop_left_onImage = std::min(std::max(crop_left_int, 0), frameImg.width-1);
    unsigned int crop_top_onImage = std::min(std::max(crop_top_int, 0), frameImg.height-1);
    unsigned int crop_right_onImage = std::min(std::max(crop_right_int, 0), frameImg.width-1);
    unsigned int crop_bottom_onImage = std::min(std::max(crop_bottom_int, 0), frameImg.height-1);
    
    unsigned char *resizedFace = (unsigned char *) malloc(crop_width * crop_height * 3);
    if (!resizedFace) {
        printf("resizedMask malloc failed\n");
        NSAssert(false, @"Error malloc resizedMask");
        return nil;
    }
    
    //     resize mask.data to resizedMask
    [self resizeBilinear_U8_C3_Image:(unsigned char*)faceData.data srch:faceData.height srcw:faceData.width dstImage:resizedFace dsth:crop_height dstw:crop_width];
    
    unsigned char *faceOnImage = (unsigned char *) malloc(frameImg.width * frameImg.height * 3);
    if (!faceOnImage) {
        printf("resizedMask malloc failed\n");
        NSAssert(faceOnImage != nil, @"Error malloc maskOnImage");
        return nil;
    }

    memset(faceOnImage, 0, frameImg.width * frameImg.height * 3);
    int crop_left_onMask = crop_left_int < 0 ? 0 - crop_left_int : 0;
    int crop_top_onMask = crop_top_int < 0 ? 0 - crop_top_int : 0;
    int crop_width_onImage = crop_right_onImage - crop_left_onImage + 1;
    for (int h = 0; h < frameImg.height; ++h) {
        if (h < crop_top_onImage)    { continue; }
        if (h > crop_bottom_onImage) { break; }
        int h_onMask = (h - crop_top_onImage) + crop_top_onMask;
        memcpy(faceOnImage + (h * frameImg.width + crop_left_onImage) * 3,
               resizedFace +  (h_onMask * crop_width + crop_left_onMask) * 3,
               crop_width_onImage *3);
    }
    
    if (resizedFace) {
        free(resizedFace);
        resizedFace = nil;
    }
    
    unsigned char *rgbaFaceOnImage = (unsigned char *) malloc(frameImg.width * frameImg.height * 4);
    const int n_pixel = frameImg.width * frameImg.height;
    for(int i = 0; i < n_pixel; i++){
        rgbaFaceOnImage[i*4] = faceOnImage[i*3];
        rgbaFaceOnImage[i*4 + 1] = faceOnImage[i*3 + 1];
        rgbaFaceOnImage[i*4 + 2] = faceOnImage[i*3 + 2];
        rgbaFaceOnImage[i*4 + 3] = 255;
    }
    
    if (faceOnImage) {
        free(faceOnImage);
        faceOnImage = nil;
    }
    
    return rgbaFaceOnImage;
}

+ (void) replaceRGBFaceBy:(const VNN_Image &)faceData
                 refImage:(const VNN_Image &) frameImg
                 onBuffer:(unsigned char *)buffer
               outputBGRA:(bool)outputBGRA{
    
    // map maskRect to frameImg coords
    const int n_pixel = frameImg.width * frameImg.height;
    float crop_left_f = faceData.rect.x0;
    float crop_top_f = faceData.rect.y0;
    float crop_right_f = faceData.rect.x1;
    float crop_bottom_f = faceData.rect.y1;
    int crop_left_int = (int(crop_left_f * frameImg.width) >> 1) << 1;
    int crop_top_int = (int(crop_top_f * frameImg.height) >> 1) << 1;
    int crop_right_int = (int(crop_right_f * frameImg.width) >> 1) << 1;
    int crop_bottom_int = (int(crop_bottom_f * frameImg.height) >> 1) << 1;
    int crop_width = crop_right_int - crop_left_int + 1;
    int crop_height = crop_bottom_int - crop_top_int + 1;
    unsigned int crop_left_onImage = std::min(std::max(crop_left_int, 0), frameImg.width-1);
    unsigned int crop_top_onImage = std::min(std::max(crop_top_int, 0), frameImg.height-1);
    unsigned int crop_right_onImage = std::min(std::max(crop_right_int, 0), frameImg.width-1);
    unsigned int crop_bottom_onImage = std::min(std::max(crop_bottom_int, 0), frameImg.height-1);
    
    unsigned char *resizedFace = (unsigned char *) malloc(crop_width * crop_height * 3);
    if (!resizedFace) {
        printf("resizedMask malloc failed\n");
        NSAssert(false, @"Error malloc resizedMask");
    }
    
    //     resize mask.data to resizedMask
    [self resizeBilinear_U8_C3_Image:(unsigned char*)faceData.data srch:faceData.height srcw:faceData.width dstImage:resizedFace dsth:crop_height dstw:crop_width];
    
    unsigned char *faceOnImage = (unsigned char *) malloc(frameImg.width * frameImg.height * 3);
    if (!faceOnImage) {
        printf("resizedMask malloc failed\n");
        NSAssert(faceOnImage != nil, @"Error malloc maskOnImage");
    }

    for(int i=0; i < n_pixel; i++){
        faceOnImage[i*3] = buffer[i*4];
        faceOnImage[i*3 + 1] = buffer[i*4 + 1];
        faceOnImage[i*3 + 2] = buffer[i*4 + 2];
    }
    
    int crop_left_onMask = crop_left_int < 0 ? 0 - crop_left_int : 0;
    int crop_top_onMask = crop_top_int < 0 ? 0 - crop_top_int : 0;
    int crop_width_onImage = crop_right_onImage - crop_left_onImage + 1;
    for (int h = 0; h < frameImg.height; ++h) {
        if (h < crop_top_onImage)    { continue; }
        if (h > crop_bottom_onImage) { break; }
        int h_onMask = (h - crop_top_onImage) + crop_top_onMask;
        memcpy(faceOnImage + (h * frameImg.width + crop_left_onImage) * 3,
               resizedFace +  (h_onMask * crop_width + crop_left_onMask) * 3,
               crop_width_onImage *3);
    }
        
    if (resizedFace) {
        free(resizedFace);
        resizedFace = nil;
    }
    
    unsigned char *rgbaFaceOnImage = buffer;
    if(outputBGRA){
        for(int i = 0; i < n_pixel; i++){
            rgbaFaceOnImage[i*4] = faceOnImage[i*3 + 2];
            rgbaFaceOnImage[i*4 + 1] = faceOnImage[i*3 + 1];
            rgbaFaceOnImage[i*4 + 2] = faceOnImage[i*3];
            rgbaFaceOnImage[i*4 + 3] = 255;
        }
    }
    else{
        for(int i = 0; i < n_pixel; i++){
            rgbaFaceOnImage[i*4] = faceOnImage[i*3];
            rgbaFaceOnImage[i*4 + 1] = faceOnImage[i*3 + 1];
            rgbaFaceOnImage[i*4 + 2] = faceOnImage[i*3 + 2];
            rgbaFaceOnImage[i*4 + 3] = 255;
        }
    }
    
    if (faceOnImage) {
        free(faceOnImage);
        faceOnImage = nil;
    }
}

+ (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp) {
        return aImage;
    }
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (UIImage *) resizePad:(UIImage *)oriImage withHeight:(int) h withWidth:(int)w {
    
    CGFloat frameH = w;
    CGFloat frameW = h;
    
    CGFloat oriW = CGImageGetWidth(oriImage.CGImage);
    CGFloat oriH = CGImageGetHeight(oriImage.CGImage);
    
    CGFloat targetH = frameH;
    CGFloat targetW = oriW *  targetH / oriH;
    if(targetW > frameW){
        targetW = frameW;
        targetH = oriH * targetW / oriW;
    }
    
    CGFloat x, y;
    if(targetW == frameW){
        x = 0;
        CGFloat padding = frameH - targetH;
        y = padding / 2;
    }else{
        y = 0;
        CGFloat padding = frameW - targetW;
        x = padding / 2;
    }
    UIColor *borderColor = UIColorFromRGB(0x292a2f);
    
    UIGraphicsBeginImageContext(CGSizeMake(frameW, frameH));
    CGContextRef context = UIGraphicsGetCurrentContext();
    [borderColor setFill];
    CGContextFillRect(context, CGRectMake(0, 0, frameW, frameH));
    
    [oriImage drawInRect:CGRectMake(x, y, targetW, targetH)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
}

@end

