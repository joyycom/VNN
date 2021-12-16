#ifndef VNN_OBJTRACKING_H
#define VNN_OBJTRACKING_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_ObjTracking( VNNHandle * handle, const int argc, const void * argv[] );

VNN_API VNN_Result VNN_Destroy_ObjTracking( VNNHandle* handle );

VNN_API VNN_Result VNN_Apply_ObjTracking_CPU( VNNHandle handle, const void * input, void * output );

VNN_API VNN_Result VNN_Set_ObjTracking_Attr( VNNHandle handle, const char * name, const void * value );

VNN_API VNN_Result VNN_Get_ObjTracking_Attr( VNNHandle handle, const char * name, void * value );

#ifdef __cplusplus
}
#endif

#endif /* VNN_OBJTRACKING_H */

