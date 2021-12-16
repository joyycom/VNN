//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
#ifndef VNN_DOCRECT_H 
#define VNN_DOCRECT_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_DocRect( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_DocRect( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_DocRect_CPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_DocRect( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_DocRect( VNNHandle handle, const char * name, void * value );


#ifdef __cplusplus
}
#endif

#endif /* VNN_DOCRECT_H */

