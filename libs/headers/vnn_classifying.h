//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#ifndef VNN_CLASSIFYING_H
#define VNN_CLASSIFYING_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif


VNN_API VNN_Result VNN_Create_Classifying( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_Classifying( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_Classifying_CPU( VNNHandle handle, const void * input, const void* face_data, void * output);

VNN_API VNN_Result VNN_Apply_VideoLabel_CPU( VNNHandle handle, const void * input, const void* frames, void * output);

VNN_API VNN_Result VNN_Apply_Classifying_GPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_Classifying_Attr(VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_Classifying_Attr(VNNHandle handle, const char * name, void * value );


#ifdef __cplusplus
}
#endif

#endif /* VNN_CLASSIFYING_H */

