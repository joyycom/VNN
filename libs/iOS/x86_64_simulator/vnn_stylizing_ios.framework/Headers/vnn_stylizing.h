#ifndef VNN_STYLIZING_H
#define VNN_STYLIZING_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_Stylizing( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_Stylizing( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_Stylizing_CPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Apply_Stylizing_GPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Set_Stylizing_Attr( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_Stylizing_Attr( VNNHandle handle, const char * name, void * value );

#ifdef __cplusplus
}
#endif

#endif /* VNN_STYLIZING_H */

