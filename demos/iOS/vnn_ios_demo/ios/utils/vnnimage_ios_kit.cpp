//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#include <cstdio>
#include "vnn_common.h"
#include "vnnimage_ios_kit.h"

void _VN_Create_Image_From_PixelBuffer(const void *, void *, const bool);
void _VN_Free_Img(const void *, void *, const bool);

VNN_Result VNN_Create_VNNImage_From_PixelBuffer(const void *i_cvpixelbuffer, void *o_vnimage, const bool i_gpu_only) {
    try {
        _VN_Create_Image_From_PixelBuffer(i_cvpixelbuffer, o_vnimage, i_gpu_only);
    }
    catch (int err) {
        return VNN_Result_Failed;
    }
    return VNN_Result_Success;
}

VNN_Result VNN_Free_VNNImage(const void *i_pixelbuffer, void *io_vnimage, const bool i_gpu_only) {
    try {
        _VN_Free_Img(i_pixelbuffer, io_vnimage, i_gpu_only);
    }
    catch (int err) {
        return VNN_Result_Failed;
    }
    return VNN_Result_Success;
}

