#ifndef VNN_GESTURE_H
#define VNN_GESTURE_H

#include "vnn_common.h"

#ifdef cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_Gesture(VNNHandle * handle, const int argc, const void **argv);

VNN_API VNN_Result VNN_Destroy_Gesture(VNNHandle * handle );

VNN_API VNN_Result VNN_Apply_Gesture_CPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Apply_Gesture_GPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_Gesture_Attr(VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_Gesture_Attr(VNNHandle handle, const char * name, void * value );

#ifdef cplusplus
}
#endif

#endif /* VNN_GESTURE_H */
