//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#ifndef VNNIMAGE_MAC_KIT_H
#define VNNIMAGE_MAC_KIT_H

#import "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_Result VNN_Create_VNNImage_From_PixelBuffer(const void * i_cvpixelbuffer,  void * o_vnimage, const bool i_gpu_only);

VNN_Result VNN_Free_VNNImage(const void * i_cvpixelbuffer, void * io_vnimage, const bool i_gpu_only);

#ifdef __cplusplus
}
#endif

#endif // VNNIMAGE_MAC_KIT_H_

