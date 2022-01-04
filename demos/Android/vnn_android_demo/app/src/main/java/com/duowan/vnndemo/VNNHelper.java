//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.Rect;
import android.util.Log;

import androidx.annotation.ColorInt;

import com.duowan.vnnlib.VNN;


public class VNNHelper {
    private static final String TAG = "VNNHelper";
    public static class VNN_EFFECT_MODE {
        public static final int VNN_FACE_KEYPOINTS = 0;
        public static final int VNN_FACE_MASK = 1;
        public static final int VNN_DISNEY_FACE = 2;
        public static final int VNN_3DGAME_FACE = 3;
        public static final int VNN_FACE_REENACT = 4;
        public static final int VNN_GESTURE = 5;
        public static final int VNN_OBJECT_TRACKING = 6;
        public static final int VNN_FACE_COUNT = 7;
        public static final int VNN_QR_CODE = 8;
        public static final int VNN_DOCUMENT_RECT = 9;
        public static final int VNN_PORTRAIT_SEG = 10;
        public static final int VNN_SKY_SEG = 11;
        public static final int VNN_CLOTHES_SEG = 12;
        public static final int VNN_ANIMAL_SEG = 13;
        public static final int VNN_HEAD_SEG = 14;
        public static final int VNN_HAIR_SEG = 15;
        public static final int VNN_COMIC = 16;
        public static final int VNN_CARTOON = 17;
        public static final int VNN_OBJECT_CLASSIFICATION = 18;
        public static final int VNN_SCENE_WEATHER = 19;
        public static final int VNN_PERSON_ATTRIBUTE = 20;
        public static final int VNN_VIDEO_PORTRAIT_SEG = 21;
        public static final int VNN_POSE_LANDMARKS = 22;
    }
    private Context mContext;
    public int mVnnID = VNN.VNN_INVALID_HANDLE;
    public int mVnnMaskID = VNN.VNN_INVALID_HANDLE;
    public int mVnnDisneyID = VNN.VNN_INVALID_HANDLE;
    public int mVnn3DGameID = VNN.VNN_INVALID_HANDLE;
    public int mVnnReenactID = VNN.VNN_INVALID_HANDLE;
    public int mVnnHeadSegID = VNN.VNN_INVALID_HANDLE;
    public int mVnnPersonAttribID = VNN.VNN_INVALID_HANDLE;
    private int mScreenOrientation = 0;
    private Paint mPaint = new Paint();
    public VNN.VNN_FaceFrameDataArr faceDetectionFrameData = new VNN.VNN_FaceFrameDataArr();
    public VNN.VNN_FaceFrameDataArr faceDetectionRect = new VNN.VNN_FaceFrameDataArr();
    public VNN.VNN_ImageArr imageArr = new VNN.VNN_ImageArr();
    public VNN.VNN_ImageArr disneyDataArr = new VNN.VNN_ImageArr();
    public VNN.VNN_ImageArr game3dDataArr = new VNN.VNN_ImageArr();
    public VNN.VNN_ImageArr game3dMaskDataArr = new VNN.VNN_ImageArr();
    //    private VNN.VNN_ImageArr imageArr = new VNN.VNN_ImageArr();
    private VNN.VNN_GestureFrameDataArr gestureFrameData = new VNN.VNN_GestureFrameDataArr();
    private VNN.VNN_ObjCountDataArr objCountDataArr = new VNN.VNN_ObjCountDataArr();
    private VNN.VNN_MultiClsTopNAccArr multiClsDataArr = new VNN.VNN_MultiClsTopNAccArr();
    private VNN.VNN_BodyFrameDataArr bodyFrameDataArr = new VNN.VNN_BodyFrameDataArr();
    public int mOutImgWidth, mOutImgHeight;
    private int mDisneyImgWidth, mDisneyImgHeight;
    private int m3dGameImgWidth, m3dGameImgHeight, m3dGameImgChannel, m3dGameMaskChannel;

    private Bitmap mBackgroundImage = null;

    private int[] pa = {1, 1, 2, 3, 5, 6, 1, 8, 9, 1, 11, 12, 1, 0, 15, 0, 14, 2, 5, 4, 7, 10, 13, 8};
    private int[] pb = {2, 5, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 0, 15, 17, 14, 16, 16, 17, 18, 19, 20, 21, 11};

    public VNNHelper(Context context) {
        mContext = context;
    }



    public void createModels(int effectMode) {
        String sdcard = mContext.getExternalFilesDir(null).getAbsolutePath() + "/vnn_models";
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_KEYPOINTS) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            //VNN.javaTest();
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_MASK) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);

            String[] facemask_modelPath = {
                    sdcard + "/vnn_face_mask_data/face_mask[1.0.0].vnnmodel"
            };
            mVnnMaskID = VNN.createFaceParser(facemask_modelPath);
            Log.i(TAG, "mVnnMaskID: " + mVnnMaskID);
            mOutImgWidth = 128;
            mOutImgHeight = 128;


            imageArr.imgsArr = new VNN.VNN_Image[5];
            for(int i = 0; i < 5; i++) {
                imageArr.imgsArr[i] = new VNN.VNN_Image();
                imageArr.imgsArr[i].data = new byte[mOutImgWidth * mOutImgHeight];
                imageArr.imgsArr[i].rect = new float[4];
                imageArr.imgsArr[i].width = mOutImgWidth;
                imageArr.imgsArr[i].height = mOutImgHeight;
            }
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_DISNEY_FACE) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);

            String[] facemask_modelPath = {
                    sdcard + "/vnn_face_mask_data/face_mask[1.0.0].vnnmodel"
            };
            mVnnMaskID = VNN.createFaceParser(facemask_modelPath);
            Log.i(TAG, "mVnnMaskID: " + mVnnMaskID);

            mOutImgWidth = 128;
            mOutImgHeight = 128;


            imageArr.imgsArr = new VNN.VNN_Image[5];
            for(int i = 0; i < 5; i++) {
                imageArr.imgsArr[i] = new VNN.VNN_Image();
                imageArr.imgsArr[i].data = new byte[mOutImgWidth * mOutImgHeight];
                imageArr.imgsArr[i].rect = new float[4];
                imageArr.imgsArr[i].width = mOutImgWidth;
                imageArr.imgsArr[i].height = mOutImgHeight;
            }

            String[] disney_modelPath = {
                    sdcard + "/vnn_disney_data/face_disney[1.0.0].vnnmodel"
            };
            mVnnDisneyID = VNN.createFaceParser(disney_modelPath);
            Log.i(TAG, "mVnnDisneyID: " + mVnnDisneyID);
            mDisneyImgWidth = 512;
            mDisneyImgHeight = 512;
            disneyDataArr.imgsArr = new VNN.VNN_Image[5];
            for(int i = 0; i < 5; i++) {
                disneyDataArr.imgsArr[i] = new VNN.VNN_Image();
                disneyDataArr.imgsArr[i].data = new byte[mDisneyImgWidth * mDisneyImgHeight * 3];
                disneyDataArr.imgsArr[i].rect = new float[4];
                disneyDataArr.imgsArr[i].width = mDisneyImgWidth;
                disneyDataArr.imgsArr[i].height = mDisneyImgHeight;
            }
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_3DGAME_FACE) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);

            String[] game3d_modelPath = {
                    sdcard + "/vnn_3dgame_data/face_3dgame[1.0.0].vnnmodel"
            };
            mVnn3DGameID = VNN.createStylizing(game3d_modelPath);
            Log.i(TAG, "mVnn3DGameID: " + mVnn3DGameID);
            m3dGameImgWidth = 512;
            m3dGameImgHeight = 512;
            m3dGameImgChannel = 3;
            m3dGameMaskChannel = 1;
            game3dDataArr.imgsArr = new VNN.VNN_Image[5];
            for(int i = 0; i < 5; i++) {
                game3dDataArr.imgsArr[i] = new VNN.VNN_Image();
                game3dDataArr.imgsArr[i].data = new byte[m3dGameImgWidth * m3dGameImgHeight * m3dGameImgChannel];
                game3dDataArr.imgsArr[i].rect = new float[4];
                game3dDataArr.imgsArr[i].width = m3dGameImgWidth;
                game3dDataArr.imgsArr[i].height = m3dGameImgHeight;
            }
            game3dMaskDataArr.imgsArr = new VNN.VNN_Image[5];
            for(int i = 0; i < 5; i++) {
                game3dMaskDataArr.imgsArr[i] = new VNN.VNN_Image();
                game3dMaskDataArr.imgsArr[i].data = new byte[m3dGameImgWidth * m3dGameImgHeight * m3dGameMaskChannel];
                game3dMaskDataArr.imgsArr[i].rect = new float[4];
                game3dMaskDataArr.imgsArr[i].width = m3dGameImgWidth;
                game3dMaskDataArr.imgsArr[i].height = m3dGameImgHeight;
            }
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_REENACT) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);

            String[] reenact_modelPath = {
                    sdcard + "/vnn_face_reenactment_data/face_reenactment[1.0.0].vnnmodel"
            };

            mVnnReenactID = VNN.createFaceReenactment(reenact_modelPath);
            Log.i(TAG, "mVnnReenactID: " + mVnnReenactID);
            mOutImgWidth = 256;
            mOutImgHeight = 256;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_GESTURE) {
            String[] modelPath = {
                    sdcard + "/vnn_gesture_data/gesture[1.0.0].vnnmodel"
            };

            mVnnID = VNN.createGesture(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_OBJECT_TRACKING) {
            String[] modelPath = {
                    sdcard + "/vnn_objtracking_data/object_tracking[1.0.0].vnnmodel"
            };

            mVnnID = VNN.createObjectTracking(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_FACE_COUNT) {
            String[] modelPath = {
                    sdcard + "/vnn_face_count_data/face_count[1.0.0].vnnmodel"
            };

            mVnnID = VNN.createObjCount(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_QR_CODE) {
            String[] modelPath = {
                    sdcard + "/vnn_qrcode_detection_data/qrcode_detection[1.0.0].vnnmodel"
            };

            mVnnID = VNN.createObjCount(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_DOCUMENT_RECT) {
            String[] modelPath = {
                    sdcard + "/vnn_docrect_data/document_rectification[1.0.0].vnnmodel"
            };

            mVnnID = VNN.createDocRect(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_PORTRAIT_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_portraitseg_data/seg_portrait_picture[1.0.0].vnnmodel",
                    sdcard + "/vnn_portraitseg_data/seg_portrait_picture[1.0.0]_process_config.json"
            };

            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 384;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_VIDEO_PORTRAIT_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_portraitseg_data/seg_portrait_video[1.0.0].vnnmodel",
                    sdcard + "/vnn_portraitseg_data/seg_portrait_video[1.0.0]_process_config.json"
            };

            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 128;
            mOutImgHeight = 128;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_SKY_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_skyseg_data/sky_segment[1.0.0].vnnmodel",
                    sdcard + "/vnn_skyseg_data/sky_segment[1.0.0]_process_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 512;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_CLOTHES_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_clothesseg_data/clothes_segment[1.0.0].vnnmodel",
                    sdcard + "/vnn_clothesseg_data/clothes_segment[1.0.0]_process_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 384;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_ANIMAL_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_animalseg_data/animal_segment[1.0.0].vnnmodel",
                    sdcard + "/vnn_animalseg_data/animal_segment[1.0.0]_process_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 384;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_HAIR_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_hairseg_data/hair_segment[1.0.0].vnnmodel",
                    sdcard + "/vnn_hairseg_data/hair_segment[1.0.0]_process_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 256;
            mOutImgHeight = 384;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_HEAD_SEG) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);
            String[] headModelPath = {
                    sdcard + "/vnn_headseg_data/head_segment[1.0.0].vnnmodel",
                    sdcard + "/vnn_headseg_data/head_segment[1.0.0]_process_config.json"
            };
            mVnnHeadSegID = VNN.createGeneral(headModelPath);
            Log.i(TAG, "mVnnID: " + mVnnHeadSegID);
            mOutImgWidth = 256;
            mOutImgHeight = 256;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_COMIC) {
            String[] modelPath = {
                    sdcard + "/vnn_comic_data/stylize_comic[1.0.0].vnnmodel",
                    sdcard + "/vnn_comic_data/stylize_comic[1.0.0]_proceess_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 384;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_CARTOON) {
            String[] modelPath = {
                    sdcard + "/vnn_cartoon_data/stylize_cartoon[1.0.0].vnnmodel",
                    sdcard + "/vnn_cartoon_data/stylize_cartoon[1.0.0]_proceess_config.json"
            };
            mVnnID = VNN.createGeneral(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
            mOutImgWidth = 512;
            mOutImgHeight = 512;
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_OBJECT_CLASSIFICATION) {
            String[] modelPath = {
                    sdcard + "/vnn_classification_data/object_classification[1.0.0].vnnmodel"
            };
            String lablePath = sdcard + "/vnn_classification_data/object_classification[1.0.0]_label.json";
            mVnnID = VNN.createClassifying(modelPath);
            if(mVnnID != -1) {
                VNN.setStringClassifying(mVnnID, "_classLabelPath", lablePath);
            }
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_SCENE_WEATHER) {
            String[] modelPath = {
                    sdcard + "/vnn_classification_data/scene_weather[1.0.0].vnnmodel"
            };
            String lablePath = sdcard + "/vnn_classification_data/scene_weather[1.0.0]_label.json";
            mVnnID = VNN.createClassifying(modelPath);
            if(mVnnID != -1) {
                VNN.setStringClassifying(mVnnID, "_classLabelPath", lablePath);
            }
            Log.i(TAG, "mVnnID: " + mVnnID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE) {
            String[] modelPath = {
                    sdcard + "/vnn_face278_data/face_mobile[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createFace(modelPath);
            Log.i(TAG, "createModels: mVnnID = " + mVnnID);
            String[] clsModelPath = {
                    sdcard + "/vnn_classification_data/person_attribute[1.0.0].vnnmodel"
            };
            String lablePath = sdcard + "/vnn_classification_data/person_attribute[1.0.0]_label.json";
            mVnnPersonAttribID = VNN.createClassifying(clsModelPath);
            if(mVnnPersonAttribID != -1) {
                VNN.setStringClassifying(mVnnPersonAttribID, "_classLabelPath", lablePath);
            }
            Log.i(TAG, "mVnnPersonAttribID: " + mVnnPersonAttribID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_POSE_LANDMARKS) {
            String[] modelPath = {
                    sdcard + "/vnn_pose_data/pose_landmarks[1.0.0].vnnmodel"
            };
            mVnnID = VNN.createPoseLandmarks(modelPath);
            Log.i(TAG, "mVnnID: " + mVnnID);
        }


    }
    public void destroyVNN(int effectMode){
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_KEYPOINTS) {
            VNN.destroyFace(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_MASK) {
            VNN.destroyFace(mVnnID);
            VNN.destroyFaceParser(mVnnMaskID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_DISNEY_FACE) {
            VNN.destroyFace(mVnnID);
            VNN.destroyFaceParser(mVnnMaskID);
            VNN.destroyFaceParser(mVnnDisneyID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_3DGAME_FACE) {
            VNN.destroyFace(mVnnID);
            VNN.destroyStylizing(mVnn3DGameID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_REENACT) {
            VNN.destroyFace(mVnnID);
            VNN.destroyFaceReenactment(mVnnReenactID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_GESTURE) {
            VNN.destroyGesture(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_OBJECT_TRACKING) {
            VNN.destroyObjectTracking(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_FACE_COUNT || effectMode == VNN_EFFECT_MODE.VNN_QR_CODE) {
            VNN.destroyObjCount(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_DOCUMENT_RECT) {
            VNN.destroyDocRect(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_PORTRAIT_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_VIDEO_PORTRAIT_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_SKY_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_CLOTHES_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_ANIMAL_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_HAIR_SEG ||
                effectMode == VNN_EFFECT_MODE.VNN_COMIC ||
                effectMode == VNN_EFFECT_MODE.VNN_CARTOON) {
            VNN.destroyGeneral(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_HEAD_SEG) {
            VNN.destroyFace(mVnnID);
            VNN.destroyGeneral(mVnnHeadSegID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_OBJECT_CLASSIFICATION ||
                effectMode == VNN_EFFECT_MODE.VNN_SCENE_WEATHER ||
                effectMode == VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE) {
            VNN.destroyClassifying(mVnnID);
        }
        if (effectMode == VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE) {
            VNN.destroyFace(mVnnID);
            VNN.destroyClassifying(mVnnPersonAttribID);
        }
        if(effectMode == VNN_EFFECT_MODE.VNN_POSE_LANDMARKS) {
            VNN.destroyPoseLandmarks(mVnnID);
        }
    }
    public long getImageOrientationFmt(boolean mirrorFlag, int cameraOrientation, int screenOrientation) {
        mScreenOrientation = screenOrientation;
        long oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90R;
        if (mirrorFlag) {
            if (cameraOrientation == 270) {
                switch (screenOrientation) {
                    case 0:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90R |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;

                    case 90:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;
                    case 180:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90L |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;
                    case 270:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_180 |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;

                        break;
                    default:
                        break;
                }
            }
            if (cameraOrientation == 90) {
                switch (screenOrientation) {
                    case 0:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90L |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;

                    case 90:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_180 |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;
                    case 180:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;
                    case 270:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90R |
                                VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_FLIP_V;
                        break;
                    default:
                        break;
                }
            }
        } else {
            if (cameraOrientation == 270) {
                switch (screenOrientation) {
                    case 0:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90L;
                        break;
                    case 90:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_DEFAULT;
                        break;
                    case 180:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90R;
                        break;
                    case 270:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_180;
                        break;
                    default:
                        break;
                }
            }
            if (cameraOrientation == 90) {
                switch (screenOrientation) {
                    case 0:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90R;
                        break;
                    case 90:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_180;
                        break;
                    case 180:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_ROTATE_90L;
                        break;
                    case 270:
                        oriFmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_DEFAULT;
                        break;
                    default:
                        break;
                }
            }

        }
        return oriFmt;
    }
    public void apply(int effectMode, VNN.VNN_Image inputImage, Canvas canvas){
        int rotate = 0;
        switch (mScreenOrientation) {
            case 0:
                rotate = 0;
                break;
            case 90:
                rotate = 270;
                break;
            case 180:
                rotate = 180;
                break;
            case 270:
                rotate = 90;
                break;
            default:
                rotate = 0;
                break;
        }
        switch (effectMode) {
            case VNN_EFFECT_MODE.VNN_FACE_KEYPOINTS: {
                if (mVnnID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    int ret = VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_VIDEO)
                        VNN.processFaceResultRotate(mVnnID, faceDetectionFrameData, rotate);
                    drawFaceKeyPoints(canvas);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_FACE_MASK: {
                if (mVnnID != -1 && mVnnMaskID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);

                    imageArr.imgsNum = faceDetectionFrameData.facesNum;
                    VNN.applyFaceParserCpu(mVnnMaskID, inputImage, faceDetectionFrameData, imageArr);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_DISNEY_FACE: {
                if (mVnnID != -1 && mVnnMaskID != -1 && mVnnDisneyID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);

                    imageArr.imgsNum = faceDetectionFrameData.facesNum;
                    VNN.applyFaceParserCpu(mVnnMaskID, inputImage, faceDetectionFrameData, imageArr);

                    disneyDataArr.imgsNum = faceDetectionFrameData.facesNum;
                    VNN.applyFaceParserCpu(mVnnDisneyID, inputImage, faceDetectionFrameData, disneyDataArr);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_PICTURE) {
                        blendForegroundBackground(canvas, mBackgroundImage, disneyDataArr, imageArr);
                    }
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_3DGAME_FACE: {
                if (mVnnID != -1 && mVnn3DGameID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);

                    game3dDataArr.imgsNum = faceDetectionFrameData.facesNum;
                    VNN.applyStylizingCpu(mVnn3DGameID, inputImage, faceDetectionFrameData, game3dDataArr);
                    VNN.getImageArrStylizing(mVnn3DGameID, "_Mask", game3dMaskDataArr);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_PICTURE) {
                        blendForegroundBackground(canvas, mBackgroundImage, game3dDataArr, game3dMaskDataArr);
                    }
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_GESTURE: {
                if (mVnnID != -1) {
                    gestureFrameData.count = 0;
                    int ret = VNN.applyGestureCpu(mVnnID, inputImage, gestureFrameData);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_VIDEO) {
                        VNN.processGestureResultRotate(mVnnID, gestureFrameData, rotate);
                    }
                    drawGesture(canvas);
                }

                break;
            }
            case VNN_EFFECT_MODE.VNN_OBJECT_TRACKING: {
                if (mVnnID != -1) {
                    VNN.applyObjectTrackingCpu(mVnnID, inputImage, objCountDataArr);
                    drawObjCount(canvas);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_FACE_COUNT:
            case VNN_EFFECT_MODE.VNN_QR_CODE: {
                if (mVnnID != -1) {
                    VNN.applyObjCountCpu(mVnnID, inputImage, objCountDataArr);
                    VNN.processObjectCountResultRotate(mVnnID, objCountDataArr, rotate);
                    drawObjCount(canvas);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_DOCUMENT_RECT: {
                if (mVnnID != -1) {
                    float[] points = new float[8];
                    VNN.applyDocRectCpu(mVnnID, inputImage, points);
                    drawDocumentPoints(canvas, points);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_PORTRAIT_SEG:
            case VNN_EFFECT_MODE.VNN_VIDEO_PORTRAIT_SEG:
            case VNN_EFFECT_MODE.VNN_SKY_SEG:
            case VNN_EFFECT_MODE.VNN_CLOTHES_SEG:
            case VNN_EFFECT_MODE.VNN_ANIMAL_SEG:
            case VNN_EFFECT_MODE.VNN_HAIR_SEG: {
                if (mVnnID != -1) {
                    imageArr.imgsNum = 1;
                    imageArr.imgsArr = new VNN.VNN_Image[imageArr.imgsNum];
                    for(int i = 0; i < imageArr.imgsNum; i++) {
                        imageArr.imgsArr[i] = new VNN.VNN_Image();
                        imageArr.imgsArr[i].data = new byte[mOutImgWidth * mOutImgHeight];
                        imageArr.imgsArr[i].rect = new float[4];
                        imageArr.imgsArr[i].width = mOutImgWidth;
                        imageArr.imgsArr[i].height = mOutImgHeight;
                    }
                    VNN.applyGeneralSegmentCpu(mVnnID, inputImage, null, imageArr);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_PICTURE) {
                        drawSegmentResult(canvas, 0, inputImage.width, inputImage.height);
                    }
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_HEAD_SEG: {
                if (mVnnID != -1 && mVnnHeadSegID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    int ret = VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);
                    faceDetectionRect.facesNum = 0;
                    VNN.getFaceDetectionRect(mVnnID, faceDetectionRect);
                    imageArr.imgsNum = faceDetectionRect.facesNum;
                    imageArr.imgsArr = new VNN.VNN_Image[imageArr.imgsNum];
                    for (int i = 0; i < imageArr.imgsNum; i++) {
                        imageArr.imgsArr[i] = new VNN.VNN_Image();
                        imageArr.imgsArr[i].data = new byte[mOutImgWidth * mOutImgHeight];
                        imageArr.imgsArr[i].rect = new float[4];
                        imageArr.imgsArr[i].width = mOutImgWidth;
                        imageArr.imgsArr[i].height = mOutImgHeight;
                    }
                    VNN.applyGeneralSegmentCpu(mVnnHeadSegID, inputImage, faceDetectionRect, imageArr);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_COMIC:
            case VNN_EFFECT_MODE.VNN_CARTOON:{
                if (mVnnID != -1) {
                    imageArr.imgsNum = 1;
                    imageArr.imgsArr = new VNN.VNN_Image[imageArr.imgsNum];
                    for (int i = 0; i < imageArr.imgsNum; i++) {
                        imageArr.imgsArr[i] = new VNN.VNN_Image();
                        imageArr.imgsArr[i].data = new byte[mOutImgWidth * mOutImgHeight * 3];
                        imageArr.imgsArr[i].rect = new float[4];
                        imageArr.imgsArr[i].width = mOutImgWidth;
                        imageArr.imgsArr[i].height = mOutImgHeight;
                    }
                    VNN.applyGeneralSegmentCpu(mVnnID, inputImage, null, imageArr);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_PICTURE) {
                        drawSegmentResult(canvas, 1, inputImage.width, inputImage.height);
                    }
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_OBJECT_CLASSIFICATION:
            case VNN_EFFECT_MODE.VNN_SCENE_WEATHER: {
                if (mVnnID != -1) {
                    multiClsDataArr.numOut = 0;
                    int ret = VNN.applyClassifyingCpu(mVnnID, inputImage, null, multiClsDataArr);
                    drawMultiClassificationResult(canvas, effectMode);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE: {
                if (mVnnID != -1 && mVnnPersonAttribID != -1) {
                    faceDetectionFrameData.facesNum = 0;
                    VNN.setFacePoints(mVnnID, 278);
                    int ret = VNN.applyFaceCpu(mVnnID, inputImage, faceDetectionFrameData);
                    faceDetectionRect.facesNum = 0;
                    VNN.getFaceDetectionRect(mVnnID, faceDetectionRect);
                    multiClsDataArr.numOut = 0;
                    ret = VNN.applyClassifyingCpu(mVnnID, inputImage, faceDetectionRect, multiClsDataArr);
                    drawMultiClassificationResult(canvas, effectMode);
                }
                break;
            }
            case VNN_EFFECT_MODE.VNN_POSE_LANDMARKS: {
                if (mVnnID != -1) {
                    bodyFrameDataArr.bodyCount = 0;
                    int ret = VNN.applyPoseLandmarksCpu(mVnnID, inputImage, bodyFrameDataArr);
                    if(inputImage.mode_fmt == VNN.VNN_MODE_FMT.VNN_MODE_FMT_VIDEO) {
                        VNN.processPoseResultRotate(mVnnID, bodyFrameDataArr, rotate);
                    }
                    drawPoseLandmarks(canvas);
                }

                break;
            }

            default: return;
        }
        return;
    }
    public void getBackgroundImage(Bitmap bitmap) {
        mBackgroundImage = bitmap;
    }
    public void drawFaceKeyPoints(Canvas canvas) {
        if (canvas == null) {
            return;
        }

        if (faceDetectionFrameData.facesNum > 0) {

            int width = canvas.getWidth();
            int height = canvas.getHeight();
            int strokeWidth = width / 200;
            strokeWidth = strokeWidth > 0 ? strokeWidth : 1;
            mPaint.setStrokeWidth(strokeWidth);

            for (int i = 0; i < faceDetectionFrameData.facesNum; i++) {
                Rect faceRect = new Rect();
                faceRect.left = (int) (faceDetectionFrameData.facesArr[i].faceRect[0] * width);
                faceRect.top = (int) (faceDetectionFrameData.facesArr[i].faceRect[1] * height);
                faceRect.right = (int) (faceDetectionFrameData.facesArr[i].faceRect[2] * width);
                faceRect.bottom = (int) (faceDetectionFrameData.facesArr[i].faceRect[3] * height);
                mPaint.setColor(Color.parseColor("#0a8dff"));
                mPaint.setStyle(Paint.Style.STROKE);
                canvas.drawRect(faceRect, mPaint);
                mPaint.setColor(Color.parseColor("#0aff8d"));
                mPaint.setStyle(Paint.Style.FILL);
                for (int j = 0; j < faceDetectionFrameData.facesArr[i].faceLandmarksNum; j++) {
                    float pointx = (faceDetectionFrameData.facesArr[i].faceLandmarks[j * 2] * width);
                    float pointy = (faceDetectionFrameData.facesArr[i].faceLandmarks[j * 2 + 1] * height);
                    canvas.drawCircle(pointx, pointy, strokeWidth, mPaint);
                }
            }
        }
    }
    public void drawGesture(Canvas canvas) {
        if (canvas == null) {
            return;
        }
        if (gestureFrameData.count > 0) {
            int width = canvas.getWidth();
            int height = canvas.getHeight();
            for (int i = 0; i < gestureFrameData.count; i++) {
                Rect handRect = new Rect();
                handRect.left = (int) (gestureFrameData.arr[i].rect[0] *
                        width);
                handRect.top = (int) (gestureFrameData.arr[i].rect[1] *
                        height);
                handRect.right = (int) (gestureFrameData.arr[i].rect[2] *
                        width);
                handRect.bottom = (int) (gestureFrameData.arr[i].rect[3] *
                        height);

                mPaint.setStyle(Paint.Style.STROKE);
                int strokeWidth = width / 200;
                strokeWidth = strokeWidth > 0 ? strokeWidth : 1;
                mPaint.setStrokeWidth(strokeWidth);
                mPaint.setColor(Color.parseColor("#0a8dff"));
                mPaint.setTextSize(50);
                canvas.drawRect(handRect, mPaint);


                switch (gestureFrameData.arr[i].type) {
                    case 0:
                        canvas.drawText("UnKnown", handRect.left, handRect.top, mPaint);
                        break;
                    case 1:
                        canvas.drawText("剪刀手", handRect.left, handRect.top, mPaint);
                        break;
                    case 2:
                        canvas.drawText("点赞", handRect.left, handRect.top, mPaint);
                        break;
                    case 3:
                        canvas.drawText("单手比心", handRect.left, handRect.top, mPaint);
                        break;
                    case 4:
                        canvas.drawText("蜘蛛侠", handRect.left, handRect.top, mPaint);
                        break;
                    case 5:
                        canvas.drawText("托举", handRect.left, handRect.top, mPaint);
                        break;
                    case 6:
                        canvas.drawText("666", handRect.left, handRect.top, mPaint);
                        break;
                    case 7:
                        canvas.drawText("双手比心", handRect.left, handRect.top, mPaint);
                        break;
                    case 8:
                        canvas.drawText("抱拳", handRect.left, handRect.top, mPaint);
                        break;
                    case 9:
                        canvas.drawText("手掌", handRect.left, handRect.top, mPaint);
                        break;
                    case 10:
                        canvas.drawText("双手合十", handRect.left, handRect.top, mPaint);
                        break;
                    case 11:
                        canvas.drawText("OK", handRect.left, handRect.top, mPaint);
                        break;
                    default:
                        break;
                }
            }
        }
    }

    private void drawObjCount(Canvas canvas) {
        if (canvas == null) {
            return;
        }

        if (objCountDataArr.count > 0) {
            int width = canvas.getWidth();
            int height = canvas.getHeight();
            mPaint.setStyle(Paint.Style.STROKE);
            int strokeWidth = width / 200;
            strokeWidth = strokeWidth > 0 ? strokeWidth : 1;
            mPaint.setStrokeWidth(strokeWidth);
            mPaint.setColor(Color.parseColor("#0a8dff"));
            for (int i = 0; i < objCountDataArr.count; i++) {
                Rect rect = new Rect();
                rect.left = (int) (objCountDataArr.objRectArr[i].x0 * width);
                rect.top = (int) (objCountDataArr.objRectArr[i].y0 * height);
                rect.right = (int) (objCountDataArr.objRectArr[i].x1 * width);
                rect.bottom = (int) (objCountDataArr.objRectArr[i].y1 * height);
                canvas.drawRect(rect, mPaint);
            }
        }
    }

    public void drawDocumentPoints(Canvas canvas, float[] points) {
        if (canvas == null) {
            return;
        }
        int width = canvas.getWidth();
        int height = canvas.getHeight();
        mPaint.setStyle(Paint.Style.STROKE);
        int strokeWidth = width / 100;
        strokeWidth = strokeWidth > 1 ? strokeWidth : 2;

        mPaint.setStyle(Paint.Style.FILL);
        for (int i = 0; i < 4; i++) {
            mPaint.setStrokeWidth(strokeWidth);
            mPaint.setColor(Color.parseColor("#0a8dff"));

            float px = points[i * 2] * width;
            float py = points[i * 2 + 1] * height;
            canvas.drawCircle(px, py, strokeWidth, mPaint);
            float nx, ny;
            if(i != 3) {
                nx = points[(i + 1) * 2] * canvas.getWidth();
                ny = points[(i + 1) * 2 + 1] * canvas.getHeight();
            }
            else {
                nx = points[0] * canvas.getWidth();
                ny = points[1] * canvas.getHeight();
            }


            mPaint.setStrokeWidth(strokeWidth / 2);
            mPaint.setColor(Color.parseColor("#fa0d0f"));
            canvas.drawLine(px, py, nx, ny, mPaint);
        }
    }

    public void drawMultiClassificationResult(Canvas canvas, int mEffectMode){
        if (canvas == null) {
            return;
        }

        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setColor(Color.parseColor("#ff0000"));
        float minSize = canvas.getWidth();
        if(canvas.getHeight() < canvas.getWidth()) minSize = canvas.getHeight();
        float textSize = minSize / 20;
        mPaint.setTextSize(textSize);
        //Log.d(TAG, "drawMultiClassificationResult: only Show 1 result!");
        if (mEffectMode == VNN_EFFECT_MODE.VNN_SCENE_WEATHER) {
            String label = "天气: " + multiClsDataArr.multiClsArr[0].clsArr[0].labels[0];
            String prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[0].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, canvas.getHeight() / 5 + 10, mPaint);

            label = "场景: " + multiClsDataArr.multiClsArr[0].clsArr[1].labels[0];
            prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[1].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, 2 * canvas.getHeight() / 5 + 10, mPaint);

        } else  if (mEffectMode == VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE) {
            String label = "性别: " + multiClsDataArr.multiClsArr[0].clsArr[0].labels[0];
            String prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[0].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, canvas.getHeight() / 5 + 10, mPaint);

            label = "颜值: " + multiClsDataArr.multiClsArr[0].clsArr[1].labels[0];
            prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[1].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, 2 * canvas.getHeight() / 5 + 10, mPaint);

            label = "年龄: " + multiClsDataArr.multiClsArr[0].clsArr[2].labels[0];
            prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[2].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, 3 * canvas.getHeight() / 5 + 10, mPaint);

        } else  if (mEffectMode == VNN_EFFECT_MODE.VNN_OBJECT_CLASSIFICATION) {
            String label = "标签: " + multiClsDataArr.multiClsArr[0].clsArr[0].labels[0];
            String prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[0].probabilities[0];
            canvas.drawText(label + "    " + prob, canvas.getWidth() / 20, canvas.getHeight() / 5 + 10, mPaint);
        }
        else {
            for (int i = 0; i < multiClsDataArr.multiClsArr[0].numCls; i++) {
                String label = "label: " + multiClsDataArr.multiClsArr[0].clsArr[i].labels[0];
                String prob = "probability: " + multiClsDataArr.multiClsArr[0].clsArr[i].probabilities[0];
                canvas.drawText(label + "    " + prob, canvas.getWidth() / 10, (i + 1) * canvas.getHeight() / 5, mPaint);
            }
        }
//        for(int k = 0; k < multiClsDataArr.numOut; k++) {
//            for (int i = 0; i < multiClsDataArr.multiClsArr[k].numCls; i++) {
//                String label = "label: " + multiClsDataArr.multiClsArr[k].clsArr[i].labels[0];
//                String prob = "probability: " + multiClsDataArr.multiClsArr[k].clsArr[i].probabilities[0];
//                canvas.drawText(label + "    " + prob, canvas.getWidth() / 10, (i + 1) * canvas.getHeight() / 5, mPaint);
//            }
//        }
    }
    private void drawSegmentResult(Canvas canvas, int mode, int showWidth, int showHeight) {
        if (canvas == null) {
            return;
        }
        if(imageArr.imgsNum > 0) {
            Bitmap bitmap;
            if(0 == mode) {
                bitmap = getBitmapImgFromMask(imageArr.imgsArr[0].data, imageArr.imgsArr[0].width, imageArr.imgsArr[0].height);
            }
            else {
                bitmap = getBitmapImgFromRGB(imageArr.imgsArr[0].data, imageArr.imgsArr[0].width, imageArr.imgsArr[0].height);
            }
            Bitmap drawImage = resizeBitmap(bitmap, showWidth, showHeight);

            canvas.drawBitmap(drawImage, 0, 0, mPaint);
        }

    }
    public Bitmap getBitmapImgFromMask(byte[] array, int width, int height) {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int b, g, r, a;
                int value = array[y * width + x];
                if (value < 0) {
                    value += 256;
                }
                a = 255;
                r = g = b = value;
                bitmap.setPixel(x, y, Color.argb(a, r, g, b));
            }
        }
        return bitmap;

    }
    public Bitmap getBitmapImgFromRGB(byte[] array, int width, int height) {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int idx = y * width * 3 + x * 3;
                int b, g, r, a;
                r = array[idx];
                if (r < 0) {
                    r += 256;
                }
                g = array[idx + 1];
                if (g < 0) {
                    g += 256;
                }
                b = array[idx + 2];
                if (b < 0) {
                    b += 256;
                }
                a = 255;
                bitmap.setPixel(x, y, Color.argb(a, r, g, b));
            }
        }
        return bitmap;

    }
    private Bitmap resizeBitmap(Bitmap bitmap, int newWidth, int newHeight) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        Matrix matrix = new Matrix();
        float scaleW = (float) newWidth / width;
        float scaleH = (float) newHeight / height;
        matrix.postScale(scaleW, scaleH);
        Bitmap resizeImage = Bitmap.createBitmap(bitmap, 0, 0, width, height, matrix, true);
        return resizeImage;
    }
    private void blendForegroundBackground(Canvas canvas, Bitmap backImg, VNN.VNN_ImageArr foreData, VNN.VNN_ImageArr maskData) {
        if (canvas == null) {
            return;
        }
        int width = backImg.getWidth();
        int height = backImg.getHeight();
        int totalPixels = width * height;
        @ColorInt int[] argbPixels = new int[totalPixels];
        backImg.getPixels(argbPixels, 0, width, 0, 0, width, height);
        for(int i = 0; i < foreData.imgsNum; i++) {
            float cropLeftFloat = foreData.imgsArr[i].rect[0];
            float cropTopFloat = foreData.imgsArr[i].rect[1];
            float cropRightFloat = foreData.imgsArr[i].rect[2];
            float cropBottomFloat = foreData.imgsArr[i].rect[3];
            int cropLeft = (int)(cropLeftFloat * (width - 1));
            int cropTop = (int)(cropTopFloat * (height - 1));
            int cropRight = (int)(cropRightFloat * (width - 1));
            int cropBottom = (int)(cropBottomFloat * (height - 1));
            int cropWidth = cropRight - cropLeft + 1;
            int cropHeight = cropBottom - cropTop + 1;
            Bitmap maskImg = getBitmapImgFromMask(maskData.imgsArr[i].data, maskData.imgsArr[i].width, maskData.imgsArr[i].height);
            Bitmap fgImg = getBitmapImgFromRGB(foreData.imgsArr[i].data, foreData.imgsArr[i].width, foreData.imgsArr[i].height);
            Bitmap resizeMaskImg = resizeBitmap(maskImg, cropWidth, cropHeight);
            Bitmap resizefgImg = resizeBitmap(fgImg, cropWidth, cropHeight);
            int cropPixels = cropWidth * cropHeight;
            @ColorInt int[] maskPixels = new int[cropPixels];
            @ColorInt int[] fgPixels = new int[cropPixels];
            resizeMaskImg.getPixels(maskPixels, 0, cropWidth, 0, 0, cropWidth, cropHeight);
            resizefgImg.getPixels(fgPixels, 0, cropWidth, 0, 0, cropWidth, cropHeight);
            for (int h = 0; h < cropHeight; ++h) {
                int startH = cropTop + h;

                if (startH < 0) {
                    continue;
                }
                if (startH >= height) {
                    break;
                }
                for (int w = 0; w < cropWidth; ++w) {
                    int startW = cropLeft + w;
                    if (startW < 0) {
                        continue;
                    }
                    if (startW >= width) {
                        break;
                    }
                    int idxBg =startH * width + startW;

                    @ColorInt int bgPixel = argbPixels[idxBg];
                    @ColorInt int maskPixel = maskPixels[h * cropWidth + w];
                    @ColorInt int fgPixel = fgPixels[h * cropWidth + w];
                    float mask_v = Color.red(maskPixel) / 255.f;
                    float alpha = 1.0f - mask_v;
                    int bgR = Color.red(bgPixel);
                    int bgG = Color.green(bgPixel);
                    int bgB = Color.blue(bgPixel);
                    int fgR = Color.red(fgPixel);
                    int fgG = Color.green(fgPixel);
                    int fgB = Color.blue(fgPixel);

                    int r = (int)(bgR * alpha + fgR * mask_v);
                    int g = (int)(bgG * alpha + fgG * mask_v);
                    int b = (int)(bgB * alpha + fgB * mask_v);
                    r = r > 255 ? 255 : r;
                    g = g > 255 ? 255 : g;
                    b = b > 255 ? 255 : b;

                    int  color = Color.argb(255, r, g, b);
                    argbPixels[idxBg] = color;
                }
            }

        }
        Bitmap bitmap = Bitmap.createBitmap(argbPixels, width, height, Bitmap.Config.ARGB_8888);

        canvas.drawBitmap(bitmap, 0, 0, mPaint);
    }

    private void drawPoseLandmarks(Canvas canvas) {

        if (canvas == null) {
            return;
        }


        if (bodyFrameDataArr.bodyCount > 0) {
            for (int i = 0; i < bodyFrameDataArr.bodyCount; i++) {
                int strokeWidth = 10;
                if (canvas.getWidth() != 1080) {
                    strokeWidth = (int) (strokeWidth * canvas.getWidth() / 1080);
                }
                Rect bodyRect = new Rect();
                bodyRect.left = (int) (bodyFrameDataArr.bodyArr[i].bodyRect[0] * canvas.getWidth());
                bodyRect.top = (int) (bodyFrameDataArr.bodyArr[i].bodyRect[1] * canvas.getHeight());
                bodyRect.right = (int) (bodyFrameDataArr.bodyArr[i].bodyRect[2] * canvas.getWidth());
                bodyRect.bottom = (int) (bodyFrameDataArr.bodyArr[i].bodyRect[3] * canvas.getHeight());
                mPaint.setStrokeWidth(strokeWidth);
                mPaint.setColor(Color.parseColor("#0a8dfd"));
                mPaint.setStyle(Paint.Style.STROKE);
                canvas.drawRect(bodyRect, mPaint);
                mPaint.setStrokeWidth(strokeWidth);
                mPaint.setStyle(Paint.Style.FILL);
                mPaint.setColor(Color.parseColor("#0a8dff"));
                for (int pairIdx = 0; pairIdx < bodyFrameDataArr.bodyArr[i].bodyPoints.length / 2; pairIdx++) {
                    int idxA = pa[pairIdx];
                    int idxB = pb[pairIdx];
                    if (bodyFrameDataArr.bodyArr[i].bodyPointsScore[idxB] > 0.3 &&
                            bodyFrameDataArr.bodyArr[i].bodyPointsScore[idxA] > 0.3) {
                        float pointAx = bodyFrameDataArr.bodyArr[i].bodyPoints[idxA * 2] * canvas.getWidth();
                        float pointAy = bodyFrameDataArr.bodyArr[i].bodyPoints[idxA * 2 + 1] * canvas.getHeight();
                        float pointBx = bodyFrameDataArr.bodyArr[i].bodyPoints[idxB * 2] * canvas.getWidth();
                        float pointBy = bodyFrameDataArr.bodyArr[i].bodyPoints[idxB * 2 + 1] * canvas.getHeight();

                        if ((int) pointAx > 0 && (int) pointAy > 0 && (int) pointBx > 0 && (int) pointBy > 0) {
//                            if((pointAx < 10 && pointAy < 10) || (pointBx < 10 && pointBy < 10)) {
//                                Log.e(TAG, "(" + pointAx + "," + pointAy + ") (" + pointBx + "," + pointBy + ")");
//                                Log.e(TAG, "score A:"+bodyFrameData.bodyArr[i].bodyPointsScore[idx_a]);
//                                Log.e(TAG, "score B:"+bodyFrameData.bodyArr[i].bodyPointsScore[idx_b]);
//                            }
                            canvas.drawLine(pointAx, pointAy, pointBx, pointBy, mPaint);
                        }
                    }
                }

                for (int j = 0; j < bodyFrameDataArr.bodyArr[i].bodyPoints.length / 2; j++) {
                    mPaint.setColor(Color.rgb(0, 218, 0));
                    float pointAx = bodyFrameDataArr.bodyArr[i].bodyPoints[j * 2] * canvas.getWidth();
                    float pointAy = bodyFrameDataArr.bodyArr[i].bodyPoints[j * 2 + 1] * canvas.getHeight();
                    if ((int) pointAx > 0 && (int) pointAy > 0) {
                        canvas.drawCircle(pointAx, pointAy, strokeWidth, mPaint);
                    }
                }
            }
        }

    }

}
