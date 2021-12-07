#ifndef VNN_FACEPARSER_H
#define VNN_FACEPARSER_H

#include "vnn_common.h"

#ifdef __cplusplus
extern "C" {
#endif

VNN_API VNN_Result VNN_Create_FaceParser(VNNHandle* handle, const int argc, const void* argv[]);

VNN_API VNN_Result VNN_Destroy_FaceParser(VNNHandle* handle);

VNN_API VNN_Result VNN_Apply_FaceParser_CPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Apply_FaceParser_GPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Set_FaceParser_Attr(VNNHandle handle, const char* name, const void* value);

VNN_API VNN_Result VNN_Get_FaceParser_Attr(VNNHandle handle, const char* name, void* value);

VNN_API VNN_Result VNN_Create_CartFaceMaker(VNNHandle* handle, const int argc, const void* argv[]);

VNN_API VNN_Result VNN_Destroy_CartFaceMaker(VNNHandle* handle);

VNN_API VNN_Result VNN_Apply_CartFaceMaker_CPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Apply_CartFaceMaker_GPU(VNNHandle handle, const void* in_image, const void* face_data, void* output);

VNN_API VNN_Result VNN_Set_CartFaceMaker(VNNHandle handle, const char* name, const void* value);

VNN_API VNN_Result VNN_Get_CartFaceMaker(VNNHandle handle, const char* name, void* value);

#ifdef __cplusplus
}
#endif


#endif
