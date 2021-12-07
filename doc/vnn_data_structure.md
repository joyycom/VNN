# VNN 输入输出数据结构
- [VNN 输入输出数据结构](#vnn-输入输出数据结构)
  - [概述](#概述)
  - [常量](#常量)
  - [VNN_Image](#vnn_image)
  - [VNN_ImageArr](#vnn_imagearr)
  - [VNN_Rect2D](#vnn_rect2d)
  - [VNN_Point2D](#vnn_point2d)
  - [VNN_ObjCountDataArr_Free](#vnn_objcountdataarr_free)
  - [VNN_FaceFrameData](#vnn_faceframedata)
  - [VNN_FaceFrameDataArr](#vnn_faceframedataarr)
  - [VNN_GestureFrameData](#vnn_gestureframedata)
  - [VNN_Point2D](#vnn_point2d-1)
  - [VNN_ClsTopNAcc](#vnn_clstopnacc)
  - [VNN_ClsTopNAccArr](#vnn_clstopnaccarr)
  - [VNN_MultiClsTopNAccArr](#vnn_multiclstopnaccarr)
  - [VNN_MultiClsTopNAccArr](#vnn_multiclstopnaccarr-1)
  - [VNN_BodyFrameDataArr](#vnn_bodyframedataarr)

## 概述
本页是VNN全部SDK所使用数据结构的参考    
如果输入SDK图像与显示图像存在旋转和镜像关系，可使用[VNN工具函数](./vnn_kit_fun.md)对数据结构进行相应的变换，以保证显示正确
## 常量
| 常量                                 | 含义                           | 值  |
| ------------------------------------ | ------------------------------ | --- |
| VNN_FRAMEDATAARR_MAX_FACES_NUM       | 最大记录人脸数                 | 5   |
| VNN_FRAMEDATA_MAX_FACE_LANDMARKS_NUM | 最大记录人脸关键点数           | 278 |
| VNN_FRAMEDATAARR_MAX_GESTURE_NUM     | 最大记录手势数                 | 15  |
| VNN_CLASSIFICATION_ACC_TOP_N         | 最大记录分类概率最大的标签个数 | 5   |
| VNN_MAX_MULTI_CLASSFICATION_NUM      | 最大记录多分类的标签组个数     | 10  |
| VNN_MAX_LABEL_LENGTH                 | 最大记录标签长度               | 100 |
| VNN_FRAMEDATA_MAX_BODYLANDMARKS_NUM  | 最大记录人体关键点个数         | 22  |
| VNN_FRAMEDATAARR_MAX_BODYS_NUM       | 最大记录人体检测个数           | 5   |

## VNN_Image
参考[链接](./how_to_use_vnn_image.md)

## VNN_ImageArr
**说明**   
用于记录多个输出图像   
**定义**
``` cpp
typedef struct _VNN_ImageArr {
    VNNInt32     imgsNum;
    VNN_Image    imgsArr[VNN_FRAMEDATAARR_MAX_FACES_NUM];
}VNN_ImageArr;
```
**成员解释**   

| 成员      | 含义                            |
| --------- | ------------------------------- |
| imgsNum   | VNN_Image数组内实际有效的对象数 |
| imgsArr[] | VNN_Image数组，定长             |

## VNN_Rect2D
**说明**   
用于记录矩形框   
**定义**
``` cpp
typedef struct _VNN_Rect2D {
    VNNFloat32 x0;	/* left 	*/
    VNNFloat32 y0; 	/* top 		*/
    VNNFloat32 x1; 	/* right 	*/
    VNNFloat32 y1; 	/* bottom	*/
} VNN_Rect2D;
```
**成员解释**   

| 成员 | 含义                   |
| ---- | ---------------------- |
| x0   | 左上角横坐标（left）   |
| y0   | 左上角纵坐标（top）    |
| x1   | 右下角横坐标（right）  |
| y1   | 右下角纵坐标（bottom） |

## VNN_Point2D
**说明**   
用于描述坐标点   
**定义**
``` cpp
typedef struct _VNN_Point2D {
    VNNFloat32 x;
    VNNFloat32 y;
} VNN_Point2D;
```
**成员解释**   

| 成员 | 含义   |
| ---- | ------ |
| x    | 横坐标 |
| y    | 纵坐标 |

## VNN_ObjCountDataArr_Free
**说明**   
用于记录不确定个数的目标检测位置结果   
使用完毕后需调用 ```VNN_ObjCountDataArr_Free``` 释放申请的内存，以避免内存泄露   
**定义**
``` cpp
typedef struct _VNN_ObjectCountDataArr {
    VNNInt32     count;
    VNN_Rect2D * objRectArr;
} VNN_ObjCountDataArr;
```
**成员解释**   

| 成员       | 含义                             |
| ---------- | -------------------------------- |
| count      | 检测结果个数                     |
| objRectArr | 检测位置结果数组的首地址，不定长 |

## VNN_FaceFrameData
**说明**   
用于记录单个人脸关键点检测结果   
**定义**
``` cpp
typedef struct _VNN_FaceFrameData {
    VNNFloat32      faceScore;
    VNN_Rect2D      faceRect;
    VNNUInt32       inputWidth;
    VNNUInt32       inputHeight;
    VNNUInt32       faceLandmarksNum;
    VNN_Point2D     faceLandmarks[VNN_FRAMEDATA_MAX_FACE_LANDMARKS_NUM];
    VNNFloat32      faceLandmarkScores[VNN_FRAMEDATA_MAX_FACE_LANDMARKS_NUM];
    VNNBool         ifCloseLeftEye;
    VNNBool         ifCloseRightEye;
    VNNBool         ifBlinkLeftEye;
    VNNBool         ifBlinkRightEye;
    VNNBool         ifOpenMouth;
    VNNBool         ifShakeHead;
    VNNBool         ifNodHead;
    VNNBool         ifOpenCloseMouth;
    VNNFloat32      smileScore;
    VNNFloat32      faceYaw;
} VNN_FaceFrameData;
```
**成员解释**   

| 成员             | 含义                                              |
| ---------------- | ------------------------------------------------- |
| faceScore        | 检测结果整体置信度                                |
| faceRect         | 人脸在画面中的位置（归一化0~1）                   |
| inputWidth       | SDK内部使用                                       |
| inputHeight      | SDK内部使用                                       |
| faceLandmarksNum | 实际检测到的关键点个数                            |
| faceLandmarks[]  | 实际检测到的关键点位置                            |
| ifCloseLeftEye   | 闭左眼                                            |
| ifCloseRightEye  | 闭右眼                                            |
| ifBlinkLeftEye   | 眨左眼                                            |
| ifBlinkRightEye  | 眨右眼                                            |
| ifOpenMouth      | 张嘴                                              |
| ifShakeHead      | 摇头                                              |
| ifNodHead        | 点头                                              |
| ifOpenCloseMouth | 张闭嘴                                            |
| smileScore       | 数值<25表示“没笑”，25~70表示“微笑”，>70表示“大笑” |
| faceYaw          | 脸部左右偏转程度                                  |

## VNN_FaceFrameDataArr
**说明**   
用于记录多个人脸关键点检测结果   
**定义**
``` cpp
typedef struct _VNN_FaceFrameDataArr {
    VNNUInt32           facesNum;
    VNN_FaceFrameData   facesArr[VNN_FRAMEDATAARR_MAX_FACES_NUM];
} VNN_FaceFrameDataArr;
```
**成员解释**   

| 成员       | 含义                           |
| ---------- | ------------------------------ |
| facesNum   | facesArr[]数组内实际有效对象数 |
| facesArr[] | VNN_FaceFrameData数组，定长    |

## VNN_GestureFrameData
**说明**   
用于记录单个手势检测结果   
**定义**
``` cpp
typedef struct _VNN_GestureFrameData {
    VNN_GestureType     type;   /* Gesture type */
    VNN_Rect2D          rect;   /* Gesture rect, left-top-right-bottom */
    VNNFloat32          score;  /* Gesture confidence socre */
} VNN_GestureFrameData;
```
**成员解释**   

| 成员  | 含义                                    |
| ----- | --------------------------------------- |
| type  | 手势类型，具体类型见 **手势类型枚举值** |
| rect  | 手势位置                                |
| score | 检测结果置信度                          |

**手势类型枚举值**
``` cpp
typedef enum _VNN_GestureType {
    VNN_GestureType_Unknow       = 0x00, // 检测到手但手势不明
    VNN_GestureType_V            = 0x01, // 剪刀手
    VNN_GestureType_ThumbUp      = 0x02, // 点赞
    VNN_GestureType_OneHandHeart = 0x03, // 单手比心
    VNN_GestureType_SpiderMan    = 0x04, // 蜘蛛侠
    VNN_GestureType_Lift         = 0x05, // 托举
    VNN_GestureType_666          = 0x06, // “666”
    VNN_GestureType_TwoHandHeart = 0x07, // 双手比心
    VNN_GestureType_PalmTogether = 0x08, // 抱拳
    VNN_GestureType_PalmOpen     = 0x09, // 张开手掌
    VNN_GestureType_ZuoYi        = 0x0a, // 作揖
    VNN_GestureType_OK           = 0x0b, // “OK”
    VNN_GestureType_ERROR        = 0xff, // 异常情况
} VNN_GestureType;
```
## VNN_Point2D
**说明**   
用于记录多个手势检测结果   
**定义**
``` cpp
typedef struct _VNN_GestureFrameDataArr {
    VNNUInt32               gestureNum;
    VNN_GestureFrameData    gestureArr[VNN_FRAMEDATAARR_MAX_GESTURE_NUM];
} VNN_GestureFrameDataArr;
```
**成员解释**   

| 成员          | 含义                           |
| ------------- | ------------------------------ |
| gestureNum    | 实际检测到的手势数             |
| gestureArr[ ] | VNN_GestureFrameData数组，定长 |

## VNN_ClsTopNAcc
**说明**   
用于记录单分类下前 ```usedTopN``` 个概率最大的分类标签   
**定义**
``` cpp
typedef struct _VNN_Classification_Accuracy_Top_N {
    VNNUInt32   categories[VNN_CLASSIFICATION_ACC_TOP_N];
    char        labels[VNN_CLASSIFICATION_ACC_TOP_N][VNN_MAX_LABEL_LENGTH];
    VNNFloat32  probabilities[VNN_CLASSIFICATION_ACC_TOP_N];
    VNNInt32    usedTopN;
} VNN_ClsTopNAcc;
```
**成员解释**   

| 成员            | 含义                     |
| --------------- | ------------------------ |
| categories[]    | 分类TopN的分类下标，定长 |
| labels[][]      | 分类TopN的文本标签，定长 |
| probabilities[] | 分类TopN的概率值，定长   |
| usedTopN        | 分类TopN的实际值         |

## VNN_ClsTopNAccArr
**说明**   
用于记录多分类的分类结果（如一个模型同时分类出场景和天气）   
**定义**
``` cpp
typedef struct _VNN_ClassificationTopNDataArr {
    VNNUInt32           numCls;
    VNN_ClsTopNAcc      clsArr[VNN_MAX_MULTI_CLASSFICATION_NUM];
} VNN_ClsTopNAccArr;
```
**成员解释**   

| 成员     | 含义                 |
| -------- | -------------------- |
| numCls   | 多分类个数           |
| clsArr[] | 每个单分类的分类结果 |

## VNN_MultiClsTopNAccArr
**说明**   
人物属性识别SDK专用，用于记录多个人物各自的属性识别（多分类）结果   
**定义**
``` cpp
typedef struct _VNN_MultiClassificationTopNDataArr {
    VNNUInt32               numOut;
    VNN_ClsTopNAccArr       multiClsArr[VNN_FRAMEDATAARR_MAX_FACES_NUM];
} VNN_MultiClsTopNAccArr;
```
**成员解释**   

| 成员          | 含义                                 |
| ------------- | ------------------------------------ |
| numOut        | 实际人物个数                         |
| multiClsArr[] | 每个人物各自的属性识别（多分类）结果 |

## VNN_MultiClsTopNAccArr
**说明**   
用于记录单个人体姿态关键点检测结果   
**定义**
``` cpp
typedef struct _VNN_BodyFrameData {
    VNNFloat32          bodyScore;
    VNN_Rect2D          bodyRect;
    VNNUInt32           bodyLandmarksNum;
    VNN_Point2D         bodyLandmarks[VNN_FRAMEDATA_MAX_BODYLANDMARKS_NUM];
    VNNFloat32          bodyLandmarkScores[VNN_FRAMEDATA_MAX_BODYLANDMARKS_NUM];
    VNNUInt32	        isWriggleWaist;
    VNNUInt32	        isCrouch;
    VNNUInt32	        isRun;
    VNN_BodyResultDesc  bodyResultDesc;
} VNN_BodyFrameData;
```
**成员解释**   

| 成员                 | 含义                                       |
| -------------------- | ------------------------------------------ |
| bodyScore            | 人体检测整体置信度                         |
| bodyRect             | 人体位置                                   |
| bodyLandmarksNum     | 实际检测到的人体关键点                     |
| bodyLandmarks[]      | 各人体关键点的位置                         |
| bodyLandmarkScores[] | 各人体关键点的置信度                       |
| isWriggleWaist       | 扭腰动作                                   |
| isCrouch             | 蹲下动作                                   |
| isRun                | 奔跑动作                                   |
| bodyResultDesc       | 人体检测结果描述，见**人体姿态描述枚举值** |

**人体检测结果描述枚举值**
``` cpp
typedef enum _VNN_BodyResultDesc {
    VNN_BodyResultDesc_Normal = 0,              // 正常
    VNN_BodyResultDesc_NoPerson = 1,            // 没有人
    VNN_BodyResultDesc_MorethanOnePerson = 2,	// 注意：仅支持1人
    VNN_BodyResultDesc_NoKneeSeen = 3,		    // 看不到膝盖，请退后
    VNN_BodyResultDesc_NoFootSeen = 4,			// 看不到脚部，请退后
    VNN_BodyResultDesc_NoHipSeen = 5            // 看不到腰部，请退后
}VNN_BodyResultDesc;
```
## VNN_BodyFrameDataArr
**说明**   
用于记录多个人体姿态关键点检测结果   
**定义**
``` cpp
typedef struct _VNN_BodyFrameDataArr {
    VNNUInt32         bodiesNum;
    VNN_BodyFrameData bodiesArr[VNN_FRAMEDATAARR_MAX_BODYS_NUM];
} VNN_BodyFrameDataArr;
```
**成员解释**   

| 成员        | 含义                 |
| ----------- | -------------------- |
| bodiesNum   | 实际检测到的人体个数 |
| bodiesArr[] | 每个人体的检测结果   |
