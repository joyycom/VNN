//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
#ifndef VNN_OBJCOUNT_H
#define VNN_OBJCOUNT_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_ObjCount( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_ObjCount( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_ObjCount_CPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_ObjCount_Attr( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_ObjCount_Attr( VNNHandle handle, const char * name, void * value );


#ifdef __cplusplus
}
#endif

#endif /* VNN_OBJCOUNT_H */

