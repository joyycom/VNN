//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "vnn_common.h"
#import "vnnimage_ios_kit.h"

#import <CoreVideo/CoreVideo.h>
#import <algorithm>
#import <mutex>

struct VideoBuffer {
    uint8_t * _buffer=NULL;
    size_t    _bytes=0;

    VideoBuffer() {
        _buffer = NULL;
        _bytes = 0;
    }

    ~VideoBuffer() {
        if (_buffer) {
            free(_buffer);
            _buffer = NULL;
        }
    }
};

static std::mutex  VNVideoBufferLocker;
static VideoBuffer VNVideoBuffer;

void _VN_Create_Image_From_PixelBuffer(const void *__pixelbuffer,  void *__vnimage, const bool i_gpu_only) {
    CVPixelBufferRef inputPixBuffer = (CVPixelBufferRef)__pixelbuffer;
    CVPixelBufferLockBaseAddress(inputPixBuffer, kCVPixelBufferLock_ReadOnly);
    VNN_Image *image =(VNN_Image *)__vnimage;
	memset(image, 0x00, sizeof(VNN_Image));
    image->texture = inputPixBuffer;
	if (CVPixelBufferGetPlaneCount(inputPixBuffer) == 0) {
		size_t iHeight = (int)CVPixelBufferGetHeight(inputPixBuffer);
		size_t iWidth = (int)CVPixelBufferGetWidth(inputPixBuffer);
		size_t bytesPerRow = CVPixelBufferGetBytesPerRow(inputPixBuffer);
		uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(inputPixBuffer);
		image->width = (int)iWidth;
		image->height = (int)iHeight;
		image->channels = 4;
		image->pix_fmt = VNN_PIX_FMT_BGRA8888;
        if (i_gpu_only) {
            return;
        }
		if (bytesPerRow != iWidth * 4) {
            while (!VNVideoBufferLocker.try_lock()) { continue; }
            size_t current_bytes = iHeight * iWidth * 4;
            if (VNVideoBuffer._buffer == NULL) {
                VNVideoBuffer._bytes = current_bytes;
                VNVideoBuffer._buffer = (uint8_t *)malloc(current_bytes);
            }
            else {
                if (VNVideoBuffer._bytes < current_bytes) {
                    free(VNVideoBuffer._buffer);
                    VNVideoBuffer._bytes = current_bytes;
                    VNVideoBuffer._buffer = (uint8_t *)malloc(current_bytes);
                }
            }
			unsigned char *ptr_indata = VNVideoBuffer._buffer;
			unsigned char *ptr_indata_temp = ptr_indata;
			unsigned char *ptr_pixbuf_temp = baseAddress;
			for (int r = 0; r < iHeight; r++) {
				memcpy(ptr_indata_temp, ptr_pixbuf_temp, iWidth * 4);
				ptr_indata_temp += iWidth * 4;
				ptr_pixbuf_temp += bytesPerRow;
			}
			image->data = ptr_indata;
            VNVideoBufferLocker.unlock();
		} else {
			image->data = baseAddress;
		}
	}
	else {
		size_t iHeight = (int)CVPixelBufferGetHeight(inputPixBuffer);
		size_t iWidth = (int)CVPixelBufferGetWidth(inputPixBuffer);
		size_t bytePerRowPlane0 = CVPixelBufferGetBytesPerRowOfPlane(inputPixBuffer, 0);
		size_t bytePerRowPlane1 = CVPixelBufferGetBytesPerRowOfPlane(inputPixBuffer, 1);
		uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(inputPixBuffer);
		uint8_t *baseAddress_plane0 = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(inputPixBuffer, 0);
		uint8_t *baseAddress_plane1 = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(inputPixBuffer, 1);
		image->width    = (int)iWidth;
		image->height   = (int)iHeight;
		image->channels = 0;
		switch (CVPixelBufferGetPixelFormatType(inputPixBuffer)) {
			case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
				image->pix_fmt  = VNN_PIX_FMT_YUV420F;
				break;
			case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
				image->pix_fmt  = VNN_PIX_FMT_YUV420V;
				break;
			default:
				break;
		}
        if (i_gpu_only) {
            return;
        }
		if (iWidth != bytePerRowPlane0 || iWidth != bytePerRowPlane1 || baseAddress != baseAddress_plane0 || baseAddress + iHeight * iWidth != baseAddress_plane1) {
            while (!VNVideoBufferLocker.try_lock()) { continue; }
            size_t current_bytes = iHeight * iWidth + ((iHeight * iWidth) >> 1);
            if (VNVideoBuffer._buffer == NULL) {
                VNVideoBuffer._bytes = current_bytes;
                VNVideoBuffer._buffer = (uint8_t *)malloc(current_bytes);
            }
            else {
                if (VNVideoBuffer._bytes < current_bytes) {
                    free(VNVideoBuffer._buffer);
                    VNVideoBuffer._bytes = current_bytes;
                    VNVideoBuffer._buffer = (uint8_t *)malloc(current_bytes);
                }
            }
            unsigned char *ptr_indata = VNVideoBuffer._buffer;
			if (1) {
				unsigned char *ptr_indata_temp = ptr_indata;
				unsigned char *ptr_pixdata_temp0 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(inputPixBuffer, 0);
				for (int r = 0; r < iHeight; r++) {
					memcpy(ptr_indata_temp, ptr_pixdata_temp0, iWidth);
					ptr_indata_temp += iWidth;
					ptr_pixdata_temp0 += bytePerRowPlane0;
				}
			}
			if (1) {
				unsigned char *ptr_indata_temp = ptr_indata + iWidth * iHeight;
				unsigned char *ptr_pixdata_temp1 = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(inputPixBuffer, 1);
				for (int r = 0; r < iHeight / 2; r++) {
					memcpy(ptr_indata_temp, ptr_pixdata_temp1, iWidth);
					ptr_indata_temp += iWidth;
					ptr_pixdata_temp1 += bytePerRowPlane1;
				}
			}
			image->data = ptr_indata;
            VNVideoBufferLocker.unlock();
		}
		else {
			image->data = baseAddress;
		}
	}
}


void _VN_Free_Img(const void *__pixelbuffer,  void *__vnimage, const bool i_gpu_only) {
	CVPixelBufferRef inputPixBuffer = (CVPixelBufferRef)__pixelbuffer;
    CVPixelBufferUnlockBaseAddress(inputPixBuffer, kCVPixelBufferLock_ReadOnly);
}
