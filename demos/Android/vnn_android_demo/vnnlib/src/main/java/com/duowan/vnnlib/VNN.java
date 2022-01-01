package com.duowan.vnnlib;

public class VNN {

    public static final int VNN_INVALID_HANDLE = 0;
    public static class VNN_MODE_FMT {
        public static final int VNN_MODE_FMT_VIDEO = 0;
        public static final int VNN_MODE_FMT_PICTURE = 1;
        public static final int VNN_MODE_FMT_DEFAULT = 2;
    }

    public class VNN_PixelFormat {
        public static final int VNN_PIX_FMT_UNKNOW = 0; /*  Unknow pixel format, as a cube */
        public static final int VNN_PIX_FMT_YUVI420 = 1; /*  Image Format for PC*/
        public static final int VNN_PIX_FMT_YUV420F =
                2; /*  YUV  4:2:0   12bpp ( 2 planes, ios FullRange, the first is Y - luminance channel,
                the other channel was UV alternate permutation.) */
        public static final int VNN_PIX_FMT_YUV420V =
                3; /*  YUV  4:2:0   12bpp ( 2 planes, ios VideoRange, the first is Y - luminance channel,
                the other channel was UV alternate permutation.) */
        public static final int VNN_PIX_FMT_YUV420P_888_SKIP1 =
                4;  /*  YUV  4:2:0   12bpp ( 3 planes, android Camera2, the first is Y - luminance channel,
                the second is U channel with skip 1, the third is V channel with skip 1.) */
        public static final int VNN_PIX_FMT_BGRA8888 = 5; /*  BGRA 8:8:8:8 32bpp ( 4 channel, 8x4=32bit BGRA pixel ) */
        public static final int VNN_PIX_FMT_RGBA8888 = 6; /*  RGBA 8:8:8:8 32bpp ( 4 channel, 8x4=32bit RGBA pixel ) */
        public static final int VNN_PIX_FMT_GRAY8 = 7; /*  Y    1        8bpp ( 1 channel, 8bit luminance pixel ) */
        public static final int VNN_PIX_FMT_NV12 =
                8; /*  YUV  4:2:0   12bpp ( 2 planes, the first is Y - luminance channel,
                the other channel was UV alternate permutation ) */
        public static final int VNN_PIX_FMT_NV21 =
                9; /*  YUV  4:2:0   12bpp ( 2 planes, andoird default, the first is Y - luminance channel,
                the other channel was VU alternate permutation ) */
        public static final int VNN_PIX_FMT_BGR888 = 10; /*  BGR  8:8:8   24bpp ( 3 channel, 8x3=24bit BGR pixel ) */
        public static final int VNN_PIX_FMT_RGB888 = 11; /*  RGB  8:8:8   24bpp ( 3 channel, 8x3=24bit RGB pixel ) */
        public static final int VNN_PIX_FMT_GRAY32 =
                12; /*  Y    1        8bpp ( 1 channel, 32bit float luminance pixel ) */
        public static final int VNN_PIX_FMT_CHW_U8 =
                13; /*  As a cube , data layerout was chw, data type was unsigned char */
        public static final int VNN_PIX_FMT_CHW_F32 =
                14; /*  As a cube , data layerout was chw, data type was float 32 */
        public static final int VNN_PIX_FMT_CHW_F16 =
                15; /*  As a cube , data layerout was chw, data type was float 16 */
        public static final int VNN_PIX_FMT_CHW_S16 = 16; /*  As a cube , data layerout was chw, data type was int 16 */
        public static final int VNN_PIX_FMT_ERROR = 17;  /*  Error pixel format */
    }

    public class VNN_OrientationFormat {
        public static final int VNN_ORIENT_FMT_DEFAULT =
                0x00000000;      /*  Unknow orientated format, as a default option, no rotate and no flip */
        public static final int VNN_ORIENT_FMT_ROTATE_90L = 0x00000001;      /*  anticlockwise rotate 90 degree  */
        public static final int VNN_ORIENT_FMT_ROTATE_90R = 0x00000002;      /*  clockwise rotate 90 degree  */
        public static final int VNN_ORIENT_FMT_ROTATE_180 = 0x00000004;      /*  rotate 180 degree  */
        public static final int VNN_ORIENT_FMT_FLIP_V = 0x00000008;      /*  flip vertically */
        public static final int VNN_ORIENT_FMT_FLIP_H = 0x00000010;      /*  flip horizontally */
        public static final int VNN_ORIENT_FMT_ROTATE_360 =
                0x00000020;      /*  android case: post carma orientation = 270 degree */
        public static final int VNN_ORIENT_FMT_ROTATE_180L =
                0x00000040;      /*  android case: post carma orientation = 270 degree */
        public static final int VNN_ORIENT_FMT_ERROR = 0xFFFFFFFF;      /*  ERROR */
    }
    public static class VNN_Image {
        public long ori_fmt; /* orientation format enum of img*/
        public int pix_fmt;    /* pixel format enum of img */
        public int mode_fmt;	 /* mode format enum of detection, can use video/picture/default */
        public int width;               //image width
        public int height;              //image height
        public int channels;             //image channel
        public byte[] data;             //cpu data
        public float[] rect;
        public int[] texture;           /* if is cpu-backend, texture is NULL. But if is gpu-backend, texture may be a VNN_Texture(android|ios) or a CVPixelbuffer(ios). */
    }
    public static class VNN_ImageArr {
        public int           imgsNum;
        public VNN_Image[]   imgsArr;
    }
    public static class VNN_FaceFrameData {
        public float[] faceLandmarks;
        public float[] faceLandmarkScores;
        public float[] faceRect;
        public int inputWidth;
        public int inputHeight;
        public int faceLandmarksNum;
        public float faceScore;
        public boolean closeLeftEye;
        public boolean closeRightEye;
        public boolean blinkLeftEye;
        public boolean blinkRightEye;
        public boolean openMouth;
        public boolean shakeHead;
        public boolean nodHead;
        public boolean openCloseMouth;
        public float smileScore;
        public float faceYaw;
    }
    public static class VNN_FaceFrameDataArr {
        public VNN_FaceFrameData[] facesArr;
        public int facesNum;
    }

    public static class VNN_GestureFrameData {
        public int type;           /* gesture type */
        public float[] rect;
        public float score;      /* score of gesture */
    }

    public static class VNN_GestureFrameDataArr {
        public int count;
        public VNN_GestureFrameData[] arr;
    }

    public static class VNN_Rect2D {
        public float x0;   /* left 	*/
        public float y0;   /* top 	*/
        public float x1;   /* right 	*/
        public float y1;   /* bottom 	*/
    }
    public static class VNN_ObjCountDataArr {
        public int count;
        public VNN_Rect2D[] objRectArr;
    }

    public static class VNN_ClsTopNAcc {
        public int[] categories;
        public float[] probabilities;
        public String[] labels;
    }
    public static class VNN_ClsTopNAccArr {
        public int numCls;
        public VNN_ClsTopNAcc[] clsArr;
    }
    public static class VNN_MultiClsTopNAccArr {
        public int numOut;
        public VNN_ClsTopNAccArr[] multiClsArr;
    }

    public static class VNN_BodyFrameData {
        public float bodyScore;
        public int bodyLandmarksNum;
        public float[] bodyPoints;
        public float[] bodyPointsScore;
        public float[] bodyRect; //x0,y0,x1,y1
        public int isWriggleWaist;
        public int isCrouch;
        public int isRun;
        public int bodyResultDesc;
    }

    public static class VNN_BodyFrameDataArr {
        public VNN_BodyFrameData[] bodyArr;
        public int bodyCount;
    }
    
    //                   //
    //  face keypoints   //
    //                   //
    public static native int createFace(String[] modelPath);

    public static native int setFacePoints(int faceID, int pointsNum);

    public static native int applyFaceCpu(
            int faceID,
            VNN_Image inputData,
            VNN_FaceFrameDataArr outData);
    public static native int processFaceResultRotate(int faceID, VNN_FaceFrameDataArr outData, int rotate);
    public static native int destroyFace(int faceID);
    public static native int getFaceDetectionRect(int faceID, VNN_FaceFrameDataArr outDetectionData);
    //                //
    //  face parser   //
    //                //
    public static native int createFaceParser(String[] modelPath);
    public static native int destroyFaceParser(int faceID);

    public static native int applyFaceParserCpu(
            int faceID,
            VNN_Image inputData,
            VNN_FaceFrameDataArr faceArr,
            VNN_ImageArr outFaceMaskArr);

    //                //
    //    Stylizing   //
    //                //
    public static native int createStylizing(String[] modelPath);
    public static native int applyStylizingCpu(int vnnID, VNN_Image inputData, VNN_FaceFrameDataArr faceArr, VNN_ImageArr outData);
    public static native int getImageArrStylizing(int vnnID, String key, VNN_ImageArr maskDataArr);
    public static native int destroyStylizing(int segID);

    //                           //
    //    Face Reenactment       //
    //                           //
    public static native int createFaceReenactment(String[] modelPath);
    public static native int applyFaceReenactmentCpu(int fID, int frameIdx, VNN_Image outData);
    public static native int destroyFaceReenactment(int fID);
    public static native int getIntFaceReenactment(int fID, String key);
    public static native int setStringFaceReenactment(int fID, String key, String val);
    public static native int setImageFaceReenactment(int fID, String key, VNN_Image targetImage);
    public static native int setRectFaceReenactment(int fID, String key, float[] faceRect);


    //                //
    //  gesture       //
    //                //
    public static native int createGesture(String[] modelPath);


    public static native int applyGestureCpu(int gestureID,
                                             VNN_Image inputData,
                                             VNN_GestureFrameDataArr outData);

    public static native int destroyGesture(int gestureID);

    public static native int processGestureResultRotate(int objID, VNN_GestureFrameDataArr outData, int rotate);
    public static native int processGestureResultFlipV(int objID, VNN_GestureFrameDataArr outData);
    public static native int processGestureResultMirror(int objID, VNN_GestureFrameDataArr outData);

    //                           //
    //    Object Tracking        //
    //                           //
    public static native int createObjectTracking(String[] modelPath);
    public static native int applyObjectTrackingCpu(int vID, VNN_Image inputData, VNN_ObjCountDataArr outData);
    public static native int destroyObjectTracking(int vID);
    public static native int setClearImageObjectTracking(int vID);
    public static native int setImageObjectTracking(int vID, String key, VNN_Image targetImage);
    public static native int setRectObjectTracking(int vID, String key, float[] objRect);

    public static native int createObjCount(String[] modelPath);

    //                           //
    //    Object Count           //
    //                           //
    public static native int applyObjCountCpu(
            int objID,
            VNN_Image inputData,
            VNN_ObjCountDataArr outData);

    public static native int destroyObjCount(int objID);
    public static native int processObjectCountResultRotate(int objID, VNN_ObjCountDataArr outData, int rotate);
    public static native int processObjectCountResultFlipV(int objID, VNN_ObjCountDataArr outData);
    public static native int processObjectCountResultMirror(int objID, VNN_ObjCountDataArr outData);


    //                              //
    //    Document Rectification    //
    //                              //
    public static native int createDocRect(String[] modelPath);

    public static native int applyDocRectCpu(
            int dID,
            VNN_Image inputData,
            float[] outData);

    public static native int destroyDocRect(int dID);

    //                              //
    //    General                   //
    //                              //
    public static native int createGeneral(String[] modelPath);
    public static native int applyGeneralSegmentCpu(int segID,
                                                    VNN_Image inputData,
                                                    VNN_FaceFrameDataArr faceArr,
                                                    VNN_ImageArr outData);
    public static native int destroyGeneral(int segID);
    public static native int getGeneralInt(int segID, String name);

    //                //
    //    Classfying  //
    //                //
    public static native int createClassifying(String[] modelPath);
    public static native int applyClassifyingCpu(int cID, VNN_Image inputData, VNN_FaceFrameDataArr faceArr, VNN_MultiClsTopNAccArr outData);
    public static native int destroyClassifying(int cID);
    public static native int setStringClassifying(int fID, String key, String val);

    //                //
    // Pose Landmarks //
    //                //
    public static native int createPoseLandmarks(String[] modelPath);


    public static native int applyPoseLandmarksCpu(int vnnID,
                                                   VNN_Image inputData,
                                                   VNN_BodyFrameDataArr outData);

    public static native int destroyPoseLandmarks(int gestureID);

    public static native int processPoseResultRotate(int vnnID, VNN_BodyFrameDataArr outData, int rotate);
    public static native int processPoseResultFlipV(int vnnID, VNN_BodyFrameDataArr outData);
    public static native int processPoseResultMirror(int vnnID, VNN_BodyFrameDataArr outData);
//    public static native int javaTest();
    static {
        try {
            System.loadLibrary("vnnjni");
        } catch (UnsatisfiedLinkError e) {
            e.printStackTrace();
        }
    }
}