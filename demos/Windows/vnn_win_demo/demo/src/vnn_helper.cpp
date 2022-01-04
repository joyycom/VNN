//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
#include "vnn_helper.h"
#include <string>
#include "vnn_face.h"
#include "vnn_faceparser.h"
#include "vnn_stylizing.h"
#include "vnn_face_reenactment.h"
#include "vnn_gesture.h"
#include "vnn_objtracking.h"
#include "vnn_objcount.h"
#include "vnn_general.h"
#include "vnn_classifying.h"
#include "vnn_pose.h"
using namespace std;
static cv::Mat trackingImg;
static CvPoint prePoint = { -1,-1 };
static CvPoint curPoint = { -1,-1 };
static bool getBox = false;
static VNN_Rect2D objBox;
static bool readyTrack = false;
void drawFaceResult(cv::Mat used_img, VNN_FaceFrameDataArr faceDetectionFrameData);
void drawMaskArr(cv::Mat used_img, VNN_ImageArr mask_arr);
void drawBlendMaskArrImageArr(cv::Mat used_img, VNN_ImageArr mask_arr, VNN_ImageArr img_arr);
void drawGestureResult(cv::Mat used_img, VNN_GestureFrameDataArr gestureFrameData);
void on_mouse(int event, int x, int y, int flags, void* param);//mouse event
void drawObjCountResult(cv::Mat used_img, VNN_ObjCountDataArr objCountDataArr);
void drawMaskArrSimple(VNN_ImageArr mask_arr);
void drawRGBImage(VNN_Image rgb_img);
void drawClassificationResult(cv::Mat used_img, VNN_MultiClsTopNAccArr cls_result);
void drawPoseResult(cv::Mat used_img, VNN_BodyFrameDataArr pose_result);
int VNNHelper::createVNN(VNN_EFFECT_MODE effectMode) {
	int ret;
	string folder_path = "./vnn_models/";
	switch (effectMode) {
	case VNN_FACE_KEYPOINTS: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret =  VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		//cout << "mVnnID:" << mVnnID << endl;
		return 0;
		break;
	}
	case VNN_FACE_MASK: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		string mask_model_path = folder_path + "vnn_face_mask_data/face_mask[1.0.0].vnnmodel";
		const char* arg_mask_model[] = {
			mask_model_path.c_str()
		};
		const int argc_mask = 1;
		VNN_Result creat_mask_ret = VNN_Create_FaceParser(&mVnnMaskID, argc_mask, (const void**)arg_mask_model);
		if (VNN_Result_Success != creat_mask_ret || 0 == mVnnMaskID) {
			return -1;
		}
		mOutImgWidth = 128;
		mOutImgHeight = 128;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mImageArr.imgsArr[i].width = mOutImgWidth;
			mImageArr.imgsArr[i].height = mOutImgHeight;
			mImageArr.imgsArr[i].pix_fmt = VNN_PIX_FMT_GRAY8;
			mImageArr.imgsArr[i].data = mMaskMemory + i * mOutPixelNum;
		}
		return 0;
		break;
	}
	case VNN_DISNEY_FACE: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		string mask_model_path = folder_path + "vnn_face_mask_data/face_mask[1.0.0].vnnmodel";
		const char* arg_mask_model[] = {
			mask_model_path.c_str()
		};
		const int argc_mask = 1;
		VNN_Result creat_mask_ret = VNN_Create_FaceParser(&mVnnMaskID, argc_mask, (const void**)arg_mask_model);
		if (VNN_Result_Success != creat_mask_ret || 0 == mVnnMaskID) {
			return -1;
		}

		mOutImgWidth = 128;
		mOutImgHeight = 128;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mImageArr.imgsArr[i].width = mOutImgWidth;
			mImageArr.imgsArr[i].height = mOutImgHeight;
			mImageArr.imgsArr[i].pix_fmt = VNN_PIX_FMT_GRAY8;
			mImageArr.imgsArr[i].data = mMaskMemory + i * mOutPixelNum;
		}

		string disney_model_path = folder_path + "vnn_disney_data/face_disney[1.0.0].vnnmodel";
		const char* arg_disney_model[] = {
			disney_model_path.c_str()
		};
		const int argc_disney = 1;
		VNN_Result creat_disney_ret = VNN_Create_FaceParser(&mVnnDisneyID, argc_disney, (const void**)arg_disney_model);
		if (VNN_Result_Success != creat_disney_ret || 0 == mVnnDisneyID) {
			return -1;
		}

		mDisneyImgWidth = 512;
		mDisneyImgHeight = 512;
		mDisneyImgChannel = 3;
		mDisneyMemory = new unsigned char[mDisneyImgChannel * mDisneyImgWidth * mDisneyImgHeight * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mDisneyDataArr.imgsArr[i].width = mDisneyImgWidth;
			mDisneyDataArr.imgsArr[i].height = mDisneyImgHeight;
			mDisneyDataArr.imgsArr[i].channels = mDisneyImgChannel;
			mDisneyDataArr.imgsArr[i].data = mDisneyMemory + i * mDisneyImgChannel * mDisneyImgWidth * mDisneyImgHeight;
		}
		return 0;
		break;
	}
	case VNN_3DGAME_FACE: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}

		string game_model_path = folder_path + "vnn_3dgame_data/face_3dgame[1.0.0].vnnmodel";
		const char* arg_game_model[] = {
			game_model_path.c_str()
		};
		const int argc_game = 1;
		VNN_Result creat_game_ret = VNN_Create_Stylizing(&mVnn3DGameID, argc_game, (const void**)arg_game_model);
		if (VNN_Result_Success != creat_game_ret || 0 == mVnn3DGameID) {
			return -1;
		}

		mOutImgWidth = 512;
		mOutImgHeight = 512;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mImageArr.imgsArr[i].width = mOutImgWidth;
			mImageArr.imgsArr[i].height = mOutImgHeight;
			mImageArr.imgsArr[i].data = mMaskMemory + i * mOutPixelNum;
			mImageArr.imgsArr[i].pix_fmt = VNN_PIX_FMT_GRAY8;
		}

		m3dGameImgChannel = 3;
		m3dGameMemory = new unsigned char[m3dGameImgChannel * mOutPixelNum * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mGame3dDataArr.imgsArr[i].width = mOutImgWidth;
			mGame3dDataArr.imgsArr[i].height = mOutImgHeight;
			mGame3dDataArr.imgsArr[i].channels = m3dGameImgChannel;
			mGame3dDataArr.imgsArr[i].data = m3dGameMemory + i * m3dGameImgChannel * mOutPixelNum;
		}
		return 0;
		break;
	}
	case VNN_FACE_REENACT: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}

		string reenact_model_path = folder_path + "vnn_face_reenactment_data/face_reenactment[1.0.0].vnnmodel";
		const char* arg_reenact_model[] = {
			reenact_model_path.c_str()
		};
		const int argc_reenact = 1;
		VNN_Result creat_reenact_ret = VNN_Create_FaceReenactment(&mVnnReenactID, argc_reenact, (const void**)arg_reenact_model);
		if (VNN_Result_Success != creat_reenact_ret || 0 == mVnnReenactID) {
			return -1;
		}
		mOutImgWidth = 256;
		mOutImgHeight = 256;
		break;
	}
	case VNN_GESTURE: {
		string model_path = folder_path + "vnn_gesture_data/gesture[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Gesture(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		break;
	}
	case VNN_OBJECT_TRACKING: {
		string model_path = folder_path + "vnn_objtracking_data/object_tracking[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_ObjTracking(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 289;
		mOutImgHeight = 289;
		break;
	}
	case VNN_FACE_COUNT: {
		string model_path = folder_path + "vnn_face_count_data/face_count[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_ObjCount(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		break;
	}
	case VNN_QR_CODE: {
		string model_path = folder_path + "vnn_qrcode_detection_data/qrcode_detection[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_ObjCount(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		break;
	}
	case VNN_PORTRAIT_SEG: {
		string model_path = folder_path + "vnn_portraitseg_data/seg_portrait_picture[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_portraitseg_data/seg_portrait_picture[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 384;
		mOutImgHeight = 512;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_VIDEO_PORTRAIT_SEG: {
		string model_path = folder_path + "vnn_portraitseg_data/seg_portrait_video[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_portraitseg_data/seg_portrait_video[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 128;
		mOutImgHeight = 128;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_SKY_SEG: {
		string model_path = folder_path + "vnn_skyseg_data/sky_segment[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_skyseg_data/sky_segment[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 512;
		mOutImgHeight = 512;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_CLOTHES_SEG: {
		string model_path = folder_path + "vnn_clothesseg_data/clothes_segment[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_clothesseg_data/clothes_segment[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 384;
		mOutImgHeight = 512;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_ANIMAL_SEG: {
		string model_path = folder_path + "vnn_animalseg_data/animal_segment[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_animalseg_data/animal_segment[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 384;
		mOutImgHeight = 512;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_HAIR_SEG: {
		string model_path = folder_path + "vnn_hairseg_data/hair_segment[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_hairseg_data/hair_segment[1.0.0]_process_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 256;
		mOutImgHeight = 384;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum];
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_GRAY8;
		break;
	}
	case VNN_HEAD_SEG: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}

		string head_model_path = folder_path + "vnn_headseg_data/head_segment[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_headseg_data/head_segment[1.0.0]_process_config.json";
		const char* arg_head_model[] = {
			head_model_path.c_str(),
			process_path.c_str()
		};
		const int argc_head = 2;
		VNN_Result creat_head_ret = VNN_Create_General(&mVnnHeadSegID, argc_head, (const void**)arg_head_model);
		if (VNN_Result_Success != creat_head_ret || 0 == mVnnHeadSegID) {
			return -1;
		}
		mOutImgWidth = 256;
		mOutImgHeight = 256;
		mOutChannel = 1;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * VNN_FRAMEDATAARR_MAX_FACES_NUM];
		for (int i = 0; i < VNN_FRAMEDATAARR_MAX_FACES_NUM; i++) {
			mImageArr.imgsArr[i].width = mOutImgWidth;
			mImageArr.imgsArr[i].height = mOutImgHeight;
			mImageArr.imgsArr[i].data = mMaskMemory + i * mOutPixelNum;
			mImageArr.imgsArr[i].pix_fmt = VNN_PIX_FMT_GRAY8;
		}
		break;
	}
	case VNN_COMIC: {
		string model_path = folder_path + "vnn_comic_data/stylize_comic[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_comic_data/stylize_comic[1.0.0]_proceess_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 384;
		mOutImgHeight = 512;
		mOutChannel = 3;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * mOutChannel];
		memset(&mImageArr, 0x00, sizeof(VNN_ImageArr));
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].channels = mOutChannel;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_RGB888;
		break;
	}
	case VNN_CARTOON: {
		string model_path = folder_path + "vnn_cartoon_data/stylize_cartoon[1.0.0].vnnmodel";
		string process_path = folder_path + "vnn_cartoon_data/stylize_cartoon[1.0.0]_proceess_config.json";
		const char* arg_model[] = {
			model_path.c_str(),
			process_path.c_str()
		};
		const int argc = 2;
		VNN_Result creat_ret = VNN_Create_General(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		mOutImgWidth = 512;
		mOutImgHeight = 512;
		mOutChannel = 3;
		mOutPixelNum = mOutImgWidth * mOutImgHeight;
		mMaskMemory = new unsigned char[mOutPixelNum * mOutChannel];
		memset(&mImageArr, 0x00, sizeof(VNN_ImageArr));
		mImageArr.imgsNum = 1;
		mImageArr.imgsArr[0].width = mOutImgWidth;
		mImageArr.imgsArr[0].height = mOutImgHeight;
		mImageArr.imgsArr[0].data = mMaskMemory;
		mImageArr.imgsArr[0].pix_fmt = VNN_PIX_FMT_RGB888;
		break;
	}
	case VNN_OBJECT_CLASSIFICATION: {
		string model_path = folder_path + "vnn_classification_data/object_classification[1.0.0].vnnmodel";
		string label_path = folder_path + "vnn_classification_data/object_classification[1.0.0]_label.json";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Classifying(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		VNN_Set_Classifying_Attr(mVnnID, "_classLabelPath", label_path.c_str());
		break;
	}
	case VNN_SCENE_WEATHER: {
		string model_path = folder_path + "vnn_classification_data/scene_weather[1.0.0].vnnmodel";
		string label_path = folder_path + "vnn_classification_data/scene_weather[1.0.0]_label.json";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Classifying(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		VNN_Set_Classifying_Attr(mVnnID, "_classLabelPath", label_path.c_str());
		break;
	}
	case VNN_PERSON_ATTRIBUTE: {
		string model_path = folder_path + "vnn_face278_data/face_pc[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Face(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}

		string attrib_model_path = folder_path + "vnn_classification_data/person_attribute[1.0.0].vnnmodel";
		string label_path = folder_path + "vnn_classification_data/person_attribute[1.0.0]_label.json";
		const char* arg_attrib_model[] = {
			attrib_model_path.c_str()
		};
		const int argc_attrib = 1;
		VNN_Result creat_attrib_ret = VNN_Create_Classifying(&mVnnPersonAttribID, argc_attrib, (const void**)arg_attrib_model);
		if (VNN_Result_Success != creat_attrib_ret || 0 == mVnnPersonAttribID) {
			return -1;
		}
		VNN_Set_Classifying_Attr(mVnnID, "_classLabelPath", label_path.c_str());
		break;
	}
	case VNN_POSE_LANDMARKS: {
		string model_path = folder_path + "vnn_pose_data/pose_landmarks[1.0.0].vnnmodel";
		const char* arg_model[] = {
			model_path.c_str()
		};
		const int argc = 1;
		VNN_Result creat_ret = VNN_Create_Pose(&mVnnID, argc, (const void**)arg_model);
		if (VNN_Result_Success != creat_ret || 0 == mVnnID) {
			return -1;
		}
		break;
	}
	}
	return 0;
}

int VNNHelper::destroyVNN(VNN_EFFECT_MODE effectMode) {
	VNN_Result ret = VNN_Result_Success;
	switch (effectMode) {
	case VNN_FACE_KEYPOINTS: {
		ret = VNN_Destroy_Face(&mVnnID);
		break;
	}
	case VNN_FACE_MASK: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_FaceParser(&mVnnMaskID);
		if (mMaskMemory != nullptr) {
			delete[]mMaskMemory;
		}
		mMaskMemory = nullptr;
		break;
	}
	case VNN_DISNEY_FACE: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_FaceParser(&mVnnMaskID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_FaceParser(&mVnnDisneyID);

		if (mMaskMemory != nullptr) {
			delete[]mMaskMemory;
		}
		mMaskMemory = nullptr;
		if (mDisneyMemory != nullptr) {
			delete[]mDisneyMemory;
		}
		mDisneyMemory = nullptr;
		break;
	}
	case VNN_3DGAME_FACE: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_Stylizing(&mVnn3DGameID);
		if (mMaskMemory != nullptr) {
			delete[]mMaskMemory;
		}
		mMaskMemory = nullptr;
		if (m3dGameMemory != nullptr) {
			delete[]m3dGameMemory;
		}
		m3dGameMemory = nullptr;
		break;
	}
	case VNN_FACE_REENACT: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_FaceReenactment(&mVnnReenactID);
		break;
	}
	case VNN_GESTURE: {
		ret = VNN_Destroy_Gesture(&mVnnID);
		break;
	}
	case VNN_OBJECT_TRACKING: {
		ret = VNN_Destroy_ObjTracking(&mVnnID);
		break;
	}
	case VNN_FACE_COUNT: {
		ret = VNN_Destroy_ObjCount(&mVnnID);
		break;
	}
	case VNN_QR_CODE: {
		ret = VNN_Destroy_ObjCount(&mVnnID);
		break;
	}
	case VNN_PORTRAIT_SEG:
	case VNN_VIDEO_PORTRAIT_SEG:
	case VNN_SKY_SEG:
	case VNN_CLOTHES_SEG:
	case VNN_ANIMAL_SEG:
	case VNN_HAIR_SEG:
	case VNN_COMIC:
	case VNN_CARTOON: {
		ret = VNN_Destroy_General(&mVnnID);
		if (mMaskMemory != nullptr) {
			delete[]mMaskMemory;
		}
		mMaskMemory = nullptr;
		break;
	}
	case VNN_HEAD_SEG: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_General(&mVnnHeadSegID);
		if (mMaskMemory != nullptr) {
			delete[]mMaskMemory;
		}
		mMaskMemory = nullptr;
		break;
	}
	case VNN_OBJECT_CLASSIFICATION: {
		ret = VNN_Destroy_Classifying(&mVnnID);
		break;
	}
	case VNN_SCENE_WEATHER: {
		ret = VNN_Destroy_Classifying(&mVnnID);
		break;
	}
	case VNN_PERSON_ATTRIBUTE: {
		ret = VNN_Destroy_Face(&mVnnID);
		if (VNN_Result_Success != ret) {
			return -1;
		}
		ret = VNN_Destroy_Classifying(&mVnnPersonAttribID);
		break;
	}
	case VNN_POSE_LANDMARKS: {
		ret = VNN_Destroy_Pose(&mVnnID);
		break;
	}			   
	}
	if (VNN_Result_Success != ret) {
		return -1;
	}
	return 0;
}

int VNNHelper::applyVNN(VNN_EFFECT_MODE effectMode, cv::Mat used_img, int mode) {
	cv::Mat rgba_image;
	cv::cvtColor(used_img, rgba_image, cv::COLOR_BGR2RGBA);
	VNN_Image in_image;
	in_image.height = used_img.rows;
	in_image.width = used_img.cols;
	in_image.data = (void*)rgba_image.data;
	in_image.pix_fmt = VNN_PIX_FMT_RGBA8888;
	in_image.ori_fmt = VNN_ORIENT_FMT::VNN_ORIENT_FMT_DEFAULT;
	in_image.channels = in_image.pix_fmt == VNN_PIX_FMT_RGB888 || in_image.pix_fmt == VNN_PIX_FMT_BGR888 ? 3 : 4;
	in_image.mode_fmt = (mode == 0 ? VNN_MODE_FMT_VIDEO : VNN_MODE_FMT_PICTURE);
	VNN_Result ret;
	switch (effectMode)
	{
	case VNN_FACE_KEYPOINTS: {
		if (mVnnID != 0) {
			mFaceDetectionFrameData.facesNum = 0;
			int _use_278pts = 1;
			VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
			ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
			//cout << "face count ��" << mFaceDetectionFrameData.facesNum << endl;
			drawFaceResult(used_img, mFaceDetectionFrameData);
		}
		return ret;
		break;
	}
	case VNN_FACE_MASK: {
		if (mVnnID != 0 && mVnnMaskID != 0) {
			mFaceDetectionFrameData.facesNum = 0;
			int _use_278pts = 1;
			VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
			ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
			if (mFaceDetectionFrameData.facesNum > 0 && VNN_Result_Success == ret) {
				ret = VNN_Apply_FaceParser_CPU(mVnnMaskID, &in_image, &mFaceDetectionFrameData, &mImageArr);
			}
			if (VNN_Result_Success == ret) {
				drawMaskArr(used_img, mImageArr);
			}
		}
		break;
	}
	case VNN_DISNEY_FACE: {
		mFaceDetectionFrameData.facesNum = 0;
		int _use_278pts = 1;
		VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
		ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
		if (mFaceDetectionFrameData.facesNum > 0 && VNN_Result_Success == ret) {
			ret = VNN_Apply_FaceParser_CPU(mVnnMaskID, &in_image, &mFaceDetectionFrameData, &mImageArr);
			if (VNN_Result_Success == ret) {
				ret = VNN_Apply_FaceParser_CPU(mVnnDisneyID, &in_image, &mFaceDetectionFrameData, &mDisneyDataArr);
			}
		}
		if (VNN_Result_Success == ret) {
			drawBlendMaskArrImageArr(used_img, mImageArr, mDisneyDataArr);
		}
		break;
	}
	case VNN_3DGAME_FACE: {
		mFaceDetectionFrameData.facesNum = 0;
		int _use_278pts = 1;
		VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
		ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
		if (mFaceDetectionFrameData.facesNum > 0 && VNN_Result_Success == ret) {
			ret = VNN_Apply_Stylizing_CPU(mVnn3DGameID, &in_image, &mFaceDetectionFrameData, &mGame3dDataArr);
			if (VNN_Result_Success == ret) {
				VNN_Get_Stylizing_Attr(mVnn3DGameID, "_Mask", &mImageArr);
			}
		}
		if (VNN_Result_Success == ret) {
			drawBlendMaskArrImageArr(used_img, mImageArr, mGame3dDataArr);
		}
		break;
	}
	case VNN_FACE_REENACT: {
		if (mVnnID != 0 && mVnnReenactID != 0) {
			int _use_278pts = 1;
			VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
			ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
			VNN_Get_Face_Attr(mVnnID, "_detection_data", &mFaceDetectionRect);
			VNN_Set_FaceReenactment_Attr(mVnnReenactID, "_kpJsonsPath", "./vnn_models/vnn_face_reenactment_data/driving.kps.json");
			VNN_Set_FaceReenactment_Attr(mVnnReenactID, "_faceRect", &(mFaceDetectionRect.facesArr[0].faceRect));//only procees the first detected face
			VNN_Set_FaceReenactment_Attr(mVnnReenactID, "_targetImage", &in_image);
			int frame_count = 0;
			VNN_Get_FaceReenactment_Attr(mVnnReenactID, "_frameCount", &frame_count);
			int pixel_num = mOutImgHeight * mOutImgWidth;
			cv::Mat rgb_img = cv::Mat(mOutImgHeight, mOutImgWidth, CV_8UC3);
			cv::Mat show_img;
			VNN_Image* result_imgs = new VNN_Image[frame_count];
			for (int i = 1; i <= frame_count; i++) { // start from 1
				result_imgs[i - 1].data = new unsigned char[pixel_num * 3];
				result_imgs[i - 1].width = mOutImgWidth;
				result_imgs[i - 1].height = mOutImgHeight;
				result_imgs[i - 1].pix_fmt = VNN_PIX_FMT_RGB888;
				VNN_Apply_FaceReenactment_CPU(mVnnReenactID, &i, &(result_imgs[i - 1]));
				memcpy(rgb_img.data, result_imgs[i - 1].data, pixel_num * 3);
				cv::cvtColor(rgb_img, show_img, cv::COLOR_RGB2BGR);

				cv::Point text_pos(5, mOutImgHeight - 5);
				char text[100];
				sprintf(text, "progress: %d\%%", i * 100 / frame_count);
				cv::putText(show_img, text, text_pos, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(50, 50, 255), 1, 8, 0);
				cv::imshow("Show", show_img);
				
				if (cv::waitKey(1) == 27) {
					cvDestroyWindow("Show");
					break;
				}
			}
			bool go_out = false;
			while (1) {
				for (int i = 0; i < frame_count; i++) {
					memcpy(rgb_img.data, result_imgs[i].data, pixel_num * 3);
					cv::cvtColor(rgb_img, show_img, cv::COLOR_RGB2BGR);
					cv::Point text_pos(5, mOutImgHeight - 5);
					cv::putText(show_img, "Press Esc to exit", text_pos, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(50, 50, 255), 1, 8, 0);
					cv::imshow("Show", show_img);
					_sleep(30);
					if (cv::waitKey(1) == 27) {
						go_out = true;
						cvDestroyWindow("Show");
						break;
					}
				}
				if (go_out) {
					break;
				}
			}
			for (int i = 0; i < frame_count; i++) {
				delete[] result_imgs[i].data;
			}
			delete[] result_imgs;
		}
		break;
	}
	case VNN_GESTURE: {
		mGestureFrameData.gestureNum = 0; //memset(&mGestureFrameData, 0x00, sizeof(VNN_GestureFrameDataArr));
		ret = VNN_Apply_Gesture_CPU(mVnnID, &in_image, &mGestureFrameData);
		if (VNN_Result_Success == ret) {
			drawGestureResult(used_img, mGestureFrameData);
		}
		break;
	}
	case VNN_OBJECT_TRACKING: {
		trackingImg = used_img;
		if (mVnnID != 0) {
			int pixel_num = mOutImgHeight * mOutImgWidth;
			if (getBox) {
				getBox = false;
				readyTrack = true;
				bool clean = true;
				VNN_Set_ObjTracking_Attr(mVnnID, "_clearImage", &clean);
				VNN_Set_ObjTracking_Attr(mVnnID, "_targetImage", &in_image);
				VNN_Set_ObjTracking_Attr(mVnnID, "_objRect", &objBox);
			}
			else if (readyTrack) {
				ret = VNN_Apply_ObjTracking_CPU(mVnnID, &in_image, &mTrackingDataArr);
				auto left = mTrackingDataArr.objRectArr[0].x0 * used_img.cols;
				auto right = mTrackingDataArr.objRectArr[0].x1 * used_img.cols;
				auto bottom = mTrackingDataArr.objRectArr[0].y0 * used_img.rows;
				auto top = mTrackingDataArr.objRectArr[0].y1 * used_img.rows;
				cv::rectangle(used_img, cvPoint(left, top), cvPoint(right, bottom), CV_RGB(0, 0, 255), 3, 8, 0);
				VNN_ObjCountDataArr_Free(&mTrackingDataArr);
			}
		}
		cv::Point text_pos(5, used_img.rows - 5);
		cv::putText(used_img, "Slide over the screen to select the target", text_pos, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(50, 50, 255), 1, 8, 0);
		cv::imshow("Show", used_img);
		cvSetMouseCallback("Show", on_mouse, 0);
		
		break;
	}
	case VNN_FACE_COUNT:
	case VNN_QR_CODE: {
		memset(&mObjCountDataArr, 0x00, sizeof(VNN_ObjCountDataArr));
		ret = VNN_Apply_ObjCount_CPU(mVnnID, &in_image, &mObjCountDataArr);
		drawObjCountResult(used_img, mObjCountDataArr);
		VNN_ObjCountDataArr_Free(&mObjCountDataArr);
		break;
	}
	case VNN_PORTRAIT_SEG:
	case VNN_VIDEO_PORTRAIT_SEG:
	case VNN_SKY_SEG:
	case VNN_CLOTHES_SEG:
	case VNN_ANIMAL_SEG:
	case VNN_HAIR_SEG: {
		if (mVnnID != 0) {
			ret = VNN_Apply_General_CPU(mVnnID, &in_image, nullptr, &mImageArr);
			drawMaskArr(used_img, mImageArr);
			
			//drawMaskArrSimple(mImageArr);
		}
		cv::imshow("Origin", used_img);
		break;
	}
	case VNN_HEAD_SEG: {
		if (mVnnID != 0 && mVnnHeadSegID != 0) {
			int _use_278pts = 1;
			VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
			ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
			VNN_Get_Face_Attr(mVnnID, "_detection_data", &mFaceDetectionRect);
			if (VNN_Result_Success == ret) {
				ret = VNN_Apply_General_CPU(mVnnID, &in_image, &mFaceDetectionRect, &mImageArr);
				drawMaskArr(used_img, mImageArr);
				cv::imshow("Origin", used_img);
			}
		}
		break;
	}
	case VNN_COMIC:
	case VNN_CARTOON: {
		if (mVnnID != 0) {
			VNN_ImageArr out_img;
			out_img.imgsNum = 1;
			out_img.imgsArr[0].width = mOutImgWidth;
			out_img.imgsArr[0].height = mOutImgHeight;
			out_img.imgsArr[0].channels = 3;
			out_img.imgsArr[0].pix_fmt = VNN_PIX_FMT_RGB888;
			out_img.imgsArr[0].data = new unsigned char[mOutImgWidth * mOutImgHeight * 3];
			ret = VNN_Apply_General_CPU(mVnnID, &in_image, nullptr, &out_img);
			drawRGBImage(out_img.imgsArr[0]);
			delete[]out_img.imgsArr[0].data;
		}
		cv::imshow("Origin", used_img);
		break;
	}
	case VNN_OBJECT_CLASSIFICATION:
	case VNN_SCENE_WEATHER: {
		if (mVnnID != 0) {
			ret = VNN_Apply_Classifying_CPU(mVnnID, &in_image, NULL, &mMultiClsDataArr);
			drawClassificationResult(used_img, mMultiClsDataArr);
		}
		break;
	}
	case VNN_PERSON_ATTRIBUTE: {
		if (mVnnID != 0 || mVnnPersonAttribID != 0) {
			int _use_278pts = 1;
			VNN_Set_Face_Attr(mVnnID, "_use_278pts", &_use_278pts);
			ret = VNN_Apply_Face_CPU(mVnnID, &in_image, &mFaceDetectionFrameData);
			VNN_Get_Face_Attr(mVnnID, "_detection_data", &mFaceDetectionRect);
			ret = VNN_Apply_Classifying_CPU(mVnnID, &in_image, &mFaceDetectionRect, &mMultiClsDataArr);
			drawClassificationResult(used_img, mMultiClsDataArr);
		}
		break;
	}
	case VNN_POSE_LANDMARKS: {
		if (mVnnID != 0) {
			mPoseDataArr.bodiesNum = 0;
			ret = VNN_Apply_Pose_CPU(mVnnID, &in_image, &mPoseDataArr);
			drawPoseResult(used_img, mPoseDataArr);
		}
		break;
	}
	default:
		break;
	}
	return 0;
}
void drawFaceResult(cv::Mat used_img, VNN_FaceFrameDataArr faceDetectionFrameData) {
	for (int faceIndex = 0; faceIndex < faceDetectionFrameData.facesNum; faceIndex++) {
		auto left = faceDetectionFrameData.facesArr[faceIndex].faceRect.x0 * used_img.cols;
		auto right = faceDetectionFrameData.facesArr[faceIndex].faceRect.x1 * used_img.cols;
		auto bottom = faceDetectionFrameData.facesArr[faceIndex].faceRect.y0 * used_img.rows;
		auto top = faceDetectionFrameData.facesArr[faceIndex].faceRect.y1 * used_img.rows;
		//cv::rectangle(used_img, cvPoint(left, top), cvPoint(right, bottom), CV_RGB(10, 141, 255), 3, 8, 0);

		cv::Point face_point;
		for (int point_index = 0; point_index < faceDetectionFrameData.facesArr[faceIndex].faceLandmarksNum; point_index++) {
			face_point.x = faceDetectionFrameData.facesArr[faceIndex].faceLandmarks[point_index].x * used_img.cols;
			face_point.y = faceDetectionFrameData.facesArr[faceIndex].faceLandmarks[point_index].y * used_img.rows;
			if (point_index < 104) {
				cv::circle(used_img, face_point, 1, cv::Scalar(255, 0, 0), -1, cv::LINE_AA);
				continue;
			}
			if (point_index < 238) {
				cv::circle(used_img, face_point, 1, cv::Scalar(0, 255, 255), -1, cv::LINE_AA);
				continue;
			}
			if (point_index < 278) {
				cv::circle(used_img, face_point, 1, cv::Scalar(0, 255, 0), -1, cv::LINE_AA);
			}

		}
	}
	cv::imshow("Show", used_img);
	//cv::imwrite("E:/face_keypoints.jpg", used_img);
}
void drawMaskArr(cv::Mat used_img, VNN_ImageArr mask_arr) {
	uint32_t frame_width = used_img.cols;
	uint32_t frame_height = used_img.rows;
	cv::Mat show_img = cv::Mat(frame_height, frame_width, CV_8UC1);
	memset(show_img.data, 0, frame_width * frame_height);
	for (int i = 0; i < mask_arr.imgsNum; i++) {
		float crop_left_f = mask_arr.imgsArr[i].rect.x0;
		float crop_top_f = mask_arr.imgsArr[i].rect.y0;
		float crop_right_f = mask_arr.imgsArr[i].rect.x1;
		float crop_bottom_f = mask_arr.imgsArr[i].rect.y1;
		int crop_left_int = int(crop_left_f * (frame_width - 1));
		int crop_top_int = int(crop_top_f * (frame_height - 1));
		int crop_right_int = int(crop_right_f * (frame_width - 1));
		int crop_bottom_int = int(crop_bottom_f * (frame_height - 1));
		int crop_width = crop_right_int - crop_left_int + 1;
		int crop_height = crop_bottom_int - crop_top_int + 1;

		cv::Mat out_mask_mat = cv::Mat(mask_arr.imgsArr[i].height, mask_arr.imgsArr[i].width, CV_8UC1);
		cv::Mat crop_mask_mat = cv::Mat(crop_height, crop_width, CV_8UC1);
			
		memcpy(out_mask_mat.data, mask_arr.imgsArr[i].data, mask_arr.imgsArr[i].height * mask_arr.imgsArr[i].width * sizeof(unsigned char));
		cv::resize(out_mask_mat, crop_mask_mat, crop_mask_mat.size(), 0, 0);
		unsigned char* used_mask = crop_mask_mat.data;
		unsigned char* show_data = show_img.data;
		for (int h = 0; h < crop_height; ++h) {
			int start_ori_h = crop_top_int + h;

			if (start_ori_h < 0) {
				continue;
			}
			if (start_ori_h >= frame_height) {
				break;
			}
			int idy_crop = h * crop_width;
			int idy_ori = start_ori_h * frame_width;
			for (int w = 0; w < crop_width; ++w) {
				int start_ori_w = crop_left_int + w;
				if (start_ori_w < 0) {
					continue;
				}
				if (start_ori_w >= frame_width) {
					break;
				}
				int idx_crop = idy_crop + w;
				int idx_ori = idy_ori + start_ori_w;
				//cout << idx_crop << "," << idx_ori << endl;
				float mask_v = used_mask[idx_crop] / 255.f;
				int show_v = show_data[idx_ori];
					
				float alpha = 1.0f - mask_v;
				int dst_v = show_v * alpha + mask_v * 255;
				dst_v = std::min(255, dst_v);
				show_data[idx_ori] = dst_v;
			}
		}
	}
	cv::imshow("Show", show_img);
}

void drawBlendMaskArrImageArr(cv::Mat used_img, VNN_ImageArr mask_arr, VNN_ImageArr effect_img_arr) {
	uint32_t frame_width = used_img.cols;
	uint32_t frame_height = used_img.rows;
	cv::Mat show_img = used_img.clone();
	for (int i = 0; i < mask_arr.imgsNum; i++) {
		float crop_left_f = mask_arr.imgsArr[i].rect.x0;
		float crop_top_f = mask_arr.imgsArr[i].rect.y0;
		float crop_right_f = mask_arr.imgsArr[i].rect.x1;
		float crop_bottom_f = mask_arr.imgsArr[i].rect.y1;
		int crop_left_int = int(crop_left_f * (frame_width - 1));
		int crop_top_int = int(crop_top_f * (frame_height - 1));
		int crop_right_int = int(crop_right_f * (frame_width - 1));
		int crop_bottom_int = int(crop_bottom_f * (frame_height - 1));
		int crop_width = crop_right_int - crop_left_int + 1;
		int crop_height = crop_bottom_int - crop_top_int + 1;

		cv::Mat out_mask_mat = cv::Mat(mask_arr.imgsArr[i].height, mask_arr.imgsArr[i].width, CV_8UC1);
		cv::Mat crop_mask_mat = cv::Mat(crop_height, crop_width, CV_8UC1);

		cv::Mat out_effect_mat = cv::Mat(effect_img_arr.imgsArr[i].height, effect_img_arr.imgsArr[i].width, CV_8UC3);
		cv::Mat crop_effect_mat = cv::Mat(crop_height, crop_width, CV_8UC3);

		memcpy(out_mask_mat.data, mask_arr.imgsArr[i].data, mask_arr.imgsArr[i].height * mask_arr.imgsArr[i].width * sizeof(unsigned char));
		memcpy(out_effect_mat.data, effect_img_arr.imgsArr[i].data, effect_img_arr.imgsArr[i].height * effect_img_arr.imgsArr[i].width * sizeof(unsigned char) * 3);
		cv::resize(out_mask_mat, crop_mask_mat, crop_mask_mat.size(), 0, 0);
		cv::resize(out_effect_mat, crop_effect_mat, crop_effect_mat.size(), 0, 0);
		/*cv::imshow("show_disney", crop_effect_mat);
		cv::imshow("show_mask", out_mask_mat);*/
		unsigned char* used_mask = crop_mask_mat.data;
		unsigned char* effect_data = crop_effect_mat.data;
		unsigned char* show_data = show_img.data;
		for (int h = 0; h < crop_height; ++h) {
			int start_ori_h = crop_top_int + h;

			if (start_ori_h < 0) {
				continue;
			}
			if (start_ori_h >= frame_height) {
				break;
			}
			int idy_crop = h * crop_width;
			int idy_ori = start_ori_h * frame_width;
			for (int w = 0; w < crop_width; ++w) {
				int start_ori_w = crop_left_int + w;
				if (start_ori_w < 0) {
					continue;
				}
				if (start_ori_w >= frame_width) {
					break;
				}
				int idx_crop = idy_crop + w;
				int idx_crop_effect = idx_crop * 3;
				int idx_ori = (idy_ori + start_ori_w) * 3;
				float mask_v = used_mask[idx_crop] / 255.f;
				float alpha = 1.0f - mask_v;
				int show_r0 = show_data[idx_ori + 2];
				int show_g0 = show_data[idx_ori + 1];
				int show_b0 = show_data[idx_ori + 0];
				int effect_r0 = effect_data[idx_crop_effect + 0];
				int effect_g0 = effect_data[idx_crop_effect + 1];
				int effect_b0 = effect_data[idx_crop_effect + 2];
				int r = show_r0 * alpha + effect_r0 * mask_v;
				int g = show_g0 * alpha + effect_g0 * mask_v;
				int b = show_b0 * alpha + effect_b0 * mask_v;
				r = std::min(255, r);
				g = std::min(255, g);
				b = std::min(255, b);

				show_data[idx_ori + 0] = b;
				show_data[idx_ori + 1] = g;
				show_data[idx_ori + 2] = r;
			}
		}
	}
	cv::imshow("Show", show_img);
}

void drawGestureResult(cv::Mat used_img, VNN_GestureFrameDataArr gestureFrameData) {
	for (int gestureindex = 0; gestureindex < gestureFrameData.gestureNum; gestureindex++) {
		float left = gestureFrameData.gestureArr[gestureindex].rect.x0 * used_img.cols;
		float right = gestureFrameData.gestureArr[gestureindex].rect.x1 * used_img.cols;
		float bottom = gestureFrameData.gestureArr[gestureindex].rect.y1 * used_img.rows;
		float top = gestureFrameData.gestureArr[gestureindex].rect.y0 * used_img.rows;

		cv::rectangle(used_img, cvPoint(left, top), cvPoint(right, bottom), CV_RGB(0, 255, 0), 3, 8, 0);
		char gesture_type[256];

		switch (gestureFrameData.gestureArr[gestureindex].type) {

		case VNN_GestureType_Unknow:
			sprintf(gesture_type, "UnKnow");
			break;
		case VNN_GestureType_V:
			sprintf(gesture_type, "V");
			break;
		case VNN_GestureType_ThumbUp:
			sprintf(gesture_type, "ThumbUp");
			break;
		case VNN_GestureType_OneHandHeart:
			sprintf(gesture_type, "OneHandHeart");
			break;
		case VNN_GestureType_SpiderMan:
			sprintf(gesture_type, "SpiderMan");
			break;
		case VNN_GestureType_Lift:
			sprintf(gesture_type, "Lift");
			break;
		case VNN_GestureType_666:
			sprintf(gesture_type, "666");
			break;
		case VNN_GestureType_TwoHandHeart:
			sprintf(gesture_type, "TwoHandHeart");
			break;
		case VNN_GestureType_ZuoYi:
			sprintf(gesture_type, "ZuoYi");
			break;
		case VNN_GestureType_PalmOpen:
			sprintf(gesture_type, "PalmOpen");
			break;
		case VNN_GestureType_PalmTogether:
			sprintf(gesture_type, "PalmTogether");
			break;
		case VNN_GestureType_OK:
			sprintf(gesture_type, "OK");
			break;
		default:
			break;
		}

		cv::Point text_pos(left, top - 5);
		cv::putText(used_img, gesture_type, text_pos, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 255), 1, 8, 0);

	}
	cv::imshow("Show", used_img);

}

void on_mouse(int event, int x, int y, int flags, void* param)
{
	CvFont font;
	cvInitFont(&font, CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, 0, 1, CV_AA);
	char temp[16];


	if ((event == CV_EVENT_LBUTTONDOWN) && (flags)) {
		getBox = false;
		readyTrack = false;
		prePoint = cvPoint(x, y);
		cv::putText(trackingImg, temp, prePoint, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 0, 255), 1);
		cv::circle(trackingImg, prePoint, 1, cv::Scalar(0, 255, 0), -1, cv::LINE_AA);
		cv::imshow("Show", trackingImg);
	}
	else if ((event == CV_EVENT_MOUSEMOVE) && (flags & CV_EVENT_LBUTTONDOWN)) {
		sprintf(temp, "(%d,%d)", x, y);
		curPoint = cvPoint(x, y);
		cv::putText(trackingImg, temp, prePoint, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 0, 255), 1);
		cv::rectangle(trackingImg, prePoint, curPoint, CV_RGB(0, 0, 255), 3, 8, 0);
		cv::imshow("Show", trackingImg);
	}
	else if (event == CV_EVENT_LBUTTONUP) {
		curPoint = cvPoint(x, y);
		objBox.x0 = (float)prePoint.x / trackingImg.cols;
		objBox.y0 = (float)prePoint.y / trackingImg.rows;
		objBox.x1 = (float)curPoint.x / trackingImg.cols;
		objBox.y1 = (float)curPoint.y / trackingImg.rows;
		getBox = true;
	}

}

void drawObjCountResult(cv::Mat used_img, VNN_ObjCountDataArr objCountDataArr) {
	for (int i = 0; i < objCountDataArr.count; i++) {
		float left = objCountDataArr.objRectArr[i].x0 * used_img.cols;
		float right = objCountDataArr.objRectArr[i].x1 * used_img.cols;
		float bottom = objCountDataArr.objRectArr[i].y1 * used_img.rows;
		float top = objCountDataArr.objRectArr[i].y0 * used_img.rows;
		cv::rectangle(used_img, cvPoint(left, top), cvPoint(right, bottom), CV_RGB(0, 255, 0), 3, 8, 0);
	}
	cv::imshow("Show", used_img);
}

void drawMaskArrSimple(VNN_ImageArr mask_arr) {
	if (mask_arr.imgsNum > 0) {
		cv::Mat out_mask_mat = cv::Mat(mask_arr.imgsArr[0].height, mask_arr.imgsArr[0].width, CV_8UC1);
		memcpy(out_mask_mat.data, mask_arr.imgsArr[0].data, mask_arr.imgsArr[0].height * mask_arr.imgsArr[0].width * sizeof(unsigned char));
		cv::imshow("Show", out_mask_mat);
	}
}
void drawRGBImage(VNN_Image rgb_img) {
	cv::Mat out_mat = cv::Mat(rgb_img.height, rgb_img.width, CV_8UC3);
	memcpy(out_mat.data, rgb_img.data, rgb_img.width * rgb_img.height * 3);
	cv::Mat bgr_mat;
	cv::cvtColor(out_mat, bgr_mat, cv::COLOR_RGB2BGR);
	cv::imshow("Show", bgr_mat);
}
void drawClassificationResult(cv::Mat used_img, VNN_MultiClsTopNAccArr cls_result) {
	if (cls_result.numOut > 0) {
		int width = used_img.cols;
		int height = used_img.rows;
		int num_imgs = cls_result.numOut;
		int num_cls = cls_result.multiClsArr[0].numCls;
		int total_num = num_imgs * num_cls;
		int margin = (height - 40) / (total_num);

		
		for (int i = 0; i < cls_result.numOut; i++) {
			for (int j = 0; j < cls_result.multiClsArr[i].numCls; j++) {
				int top = 20 + (i * num_cls + j) * margin;
				int left = width / 10;
				cv::Point text_pos(left, top);
				std::string cls_string = cls_result.multiClsArr[i].clsArr[j].labels[0];
				cls_string += ": ";
				cls_string += to_string(cls_result.multiClsArr[i].clsArr[j].probabilities[0]);
				cv::putText(used_img, cls_string, text_pos, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(50, 50, 255), 1, 8, 0);
			}
		}
	}
	cv::imshow("Show", used_img);
	
}

const std::vector<std::vector<int>> skeleton = {
			{  0,  1 },
			{  1,  2 },
			{  2,  3 },
			{  3,  4 },
			{  4, 18 },
			{  1,  5 },
			{  5,  6 },
			{  6,  7 },
			{  7, 19 },
			{  2,  8 },
			{  8,  9 },
			{  9, 10 },
			{ 10, 20 },
			{  5, 11 },
			{ 11, 12 },
			{ 12, 13 },
			{ 13, 21 },
			{  0, 14 },
			{ 14, 16 },
			{  0, 15 },
			{ 15, 17 },
};

void drawPoseResult(cv::Mat used_img, VNN_BodyFrameDataArr pose_result) {
	const cv::Scalar color_point(0, 255, 0);
	cv::Point pose_point;
	if (pose_result.bodiesNum > 0) {
		for (int i = 0; i < pose_result.bodiesNum; i++) {
			auto left = pose_result.bodiesArr[i].bodyRect.x0 * used_img.cols;
			auto right = pose_result.bodiesArr[i].bodyRect.x1 * used_img.cols;
			auto bottom = pose_result.bodiesArr[i].bodyRect.y0 * used_img.rows;
			auto top = pose_result.bodiesArr[i].bodyRect.y1 * used_img.rows;

			cv::rectangle(used_img, cvPoint(left, top), cvPoint(right, bottom), CV_RGB(255, 0, 0), 3, 8, 0);

			for (int j = 0; j < pose_result.bodiesArr[i].bodyLandmarksNum; j++) {
				pose_point.x = pose_result.bodiesArr[i].bodyLandmarks[j].x * used_img.cols;
				pose_point.y = pose_result.bodiesArr[i].bodyLandmarks[j].y * used_img.rows;
				cv::circle(used_img, pose_point, 5, color_point, -1);
				std::string index = std::to_string(j);
				cv::putText(used_img, index, pose_point, cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);

			}
		}

		const cv::Scalar color_line(255, 0, 0);
		cv::Point line_point1;
		cv::Point line_point2;
		int idx[2];
		for (int i = 0; i < pose_result.bodiesNum; i++) {
			for (int j = 0; j < skeleton.size(); j++) {
				idx[0] = skeleton[j][0];
				idx[1] = skeleton[j][1];
				line_point1.x = pose_result.bodiesArr[i].bodyLandmarks[idx[0]].x * used_img.cols;
				line_point1.y = pose_result.bodiesArr[i].bodyLandmarks[idx[0]].y * used_img.rows;
				line_point2.x = pose_result.bodiesArr[i].bodyLandmarks[idx[1]].x * used_img.cols;
				line_point2.y = pose_result.bodiesArr[i].bodyLandmarks[idx[1]].y * used_img.rows;
				if (line_point1.x > 0 && line_point1.y > 0 && line_point2.x > 0 && line_point2.y > 0) {
					cv::line(used_img, line_point1, line_point2, color_line, 2);
				}
			}

			std::string isWriggleWaist = std::to_string(pose_result.bodiesArr[i].isWriggleWaist);
			cv::putText(used_img, "wriggle waist: " + isWriggleWaist, cvPoint(15, 30), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);

			VNN_BodyResultDesc result_desc = pose_result.bodiesArr[i].bodyResultDesc;
			switch (result_desc)
			{
			case VNN_BodyResultDesc::VNN_BodyResultDesc_NoPerson:
			{
				cv::putText(used_img, "Result Desc: NoPerson ", cvPoint(15, 60), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);
			}
			break;
			case VNN_BodyResultDesc::VNN_BodyResultDesc_MorethanOnePerson:
			{
				cv::putText(used_img, "Result Desc: MorethanOnePerson ", cvPoint(15, 60), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);
			}
			break;
			case VNN_BodyResultDesc::VNN_BodyResultDesc_NoKneeSeen:
			{
				cv::putText(used_img, "Result Desc: NoKneeSeen ", cvPoint(15, 60), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);
			}
			break;
			case VNN_BodyResultDesc::VNN_BodyResultDesc_NoFootSeen:
			{
				cv::putText(used_img, "Result Desc: NoFootSeen ", cvPoint(15, 60), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);
			}
			break;
			case VNN_BodyResultDesc::VNN_BodyResultDesc_Normal:
			{
				cv::putText(used_img, "Result Desc: Normal ", cvPoint(15, 60), cv::FONT_HERSHEY_COMPLEX_SMALL, 1.0, cv::Scalar(0, 255, 0), 1);
			}
			break;
			default:
				break;
			}
		}
	}
	cv::imshow("Show", used_img);
}