#include "vnn_define.h"
#include "vnn_common.h"
#include <opencv2/opencv.hpp>
typedef enum _VNN_EFFECT_MODE {
	VNN_FACE_KEYPOINTS = 0,
	VNN_FACE_MASK,
	VNN_DISNEY_FACE,
	VNN_3DGAME_FACE,
	VNN_FACE_REENACT,
	VNN_GESTURE,
	VNN_OBJECT_TRACKING,
	VNN_FACE_COUNT,
	VNN_QR_CODE,
	VNN_DOCUMENT_RECT,
	VNN_PORTRAIT_SEG,
	VNN_VIDEO_PORTRAIT_SEG,
	VNN_SKY_SEG,
	VNN_CLOTHES_SEG,
	VNN_ANIMAL_SEG,
	VNN_HAIR_SEG,
	VNN_HEAD_SEG,
	VNN_COMIC,
	VNN_CARTOON,
	VNN_OBJECT_CLASSIFICATION,
	VNN_SCENE_WEATHER,
	VNN_PERSON_ATTRIBUTE,
	VNN_POSE_LANDMARKS,
	VNN_EFFECT_COUNT  //used to count the number of enum types
}VNN_EFFECT_MODE;

class VNNHelper {
public:
	int createVNN(VNN_EFFECT_MODE effectMode);
	int destroyVNN(VNN_EFFECT_MODE effectMode);
	int applyVNN(VNN_EFFECT_MODE effectMode, cv::Mat used_img, int mode);
private:
	VNNHandle mVnnID = 0;
	VNNHandle mVnnMaskID = 0;
	VNNHandle mVnnDisneyID = 0;
	VNNHandle mVnn3DGameID = 0;
	VNNHandle mVnnReenactID = 0;
	VNNHandle mVnnHeadSegID = 0;
	VNNHandle mVnnPersonAttribID = 0;
	VNN_FaceFrameDataArr mFaceDetectionFrameData;
	VNN_FaceFrameDataArr mFaceDetectionRect;
	VNN_ImageArr mImageArr;
	VNN_ImageArr mDisneyDataArr;
	VNN_ImageArr mGame3dDataArr;
	VNN_GestureFrameDataArr mGestureFrameData;
	VNN_ObjCountDataArr mObjCountDataArr;
	VNN_ObjCountDataArr mTrackingDataArr;
	VNN_MultiClsTopNAccArr mMultiClsDataArr;
	VNN_BodyFrameDataArr mPoseDataArr;
	int mOutImgWidth, mOutImgHeight, mOutPixelNum, mOutChannel;
	int mDisneyImgWidth, mDisneyImgHeight, mDisneyImgChannel;
	int m3dGameImgWidth, m3dGameImgHeight, m3dGameImgChannel, m3dGameMaskChannel;
	unsigned char* mMaskMemory;
	unsigned char* mDisneyMemory;
	unsigned char* m3dGameMemory;
	

};
