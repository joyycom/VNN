#ifndef VNN_GENERAL_H
#define VNN_GENERAL_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_General( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_General( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_General_CPU( VNNHandle handle, const void * input, const void* face_data, void * output );


VNN_API VNN_Result VNN_Apply_General_GPU( VNNHandle handle, const void * input, const void* face_data, void * output );

VNN_API VNN_Result VNN_Set_General_Attr( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_General_Attr( VNNHandle handle, const char * name, void * value );

#ifdef __cplusplus
}
#endif

#endif /* VNN_GENERAL_H */

