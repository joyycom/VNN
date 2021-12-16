//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#include <memory>

#define CURRENT_VIEW_W self.view.frame.size.width
#define CURRENT_VIEW_H self.view.frame.size.height
#define NSColorFromRGB(rgbValue) [NSColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface MyAnimator : NSObject <NSViewControllerPresentationAnimator>

@end

@interface OSXDemoHelper : NSObject

+ (CVPixelBufferRef)CreateCVPixelBufferRefFromNSImageRGBA:(NSImage *)image;
+ (NSImage *)U8RGBABufferToNSImage:(const unsigned char*)buffer withHeight:(const int)height withWidth:(const int)width;
+ (void)saveNSImage:(NSImage *)image atPath:(NSString *)path;
+(void) drawTextToNSImage: (CGContextRef) context WithText: (std::vector<std::string>) textVec FontSize: (CGFloat) fontSize FontR: (CGFloat) r FontG: (CGFloat) g FontB: (CGFloat) b FontX: (CGFloat) x FontY: (CGFloat) y;
@end

class VnnU8Buffer {
public:
    VnnU8Buffer(size_t dataSize){
        data = (unsigned char *)malloc(dataSize);
    }
    ~VnnU8Buffer(){
        if(data){
            free(data);
            data = nullptr;
        }
    }
    
public:
    unsigned char* data;
};
typedef std::shared_ptr<VnnU8Buffer> VnnU8BufferPtr;

void convertRGBToRGBA(VnnU8BufferPtr rgbbuffer, VnnU8BufferPtr rgbabuffer, size_t n_pixiel);
void reverseMask(VnnU8BufferPtr buffer, const size_t n_byte);
void tileGrayToBGRA(unsigned char* gray_ptr, unsigned char* bgra_ptr, const size_t n_pixel);
void convertRGBToBGRA(unsigned char* rgb_ptr, unsigned char* bgra_ptr, const size_t n_pixel);
