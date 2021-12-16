#ifndef VNN_FACE_REENACTMENT_H
#define VNN_FACE_REENACTMENT_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_FaceReenactment( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_FaceReenactment( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_FaceReenactment_CPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Apply_FaceReenactment_GPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_FaceReenactment_Attr( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_FaceReenactment_Attr( VNNHandle handle, const char * name, void * value );

#ifdef __cplusplus
}
#endif

#endif /* VNN_FACE_REENACTMENT_H */

