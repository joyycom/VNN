#include <jni.h>
#include <android/log.h>
#include "string"
#include <vnn_define.h>
#include <vnn_kit.h>
#include <vnn_face.h>
#include <vnn_faceparser.h>
#include <vnn_stylizing.h>
#include <vnn_face_reenactment.h>
#include <vnn_gesture.h>
#include <vnn_objtracking.h>
#include <vnn_objcount.h>
#include <vnn_docrect.h>
#include <vnn_general.h>
#include <vnn_classifying.h>
#include <vnn_pose.h>

#define TAG "VNN"
#define LOGV(...) __android_log_print(ANDROID_LOG_VERBOSE, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
extern "C" {
//JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_javaTest(JNIEnv *env, jclass thiz) {
//
//    return 0;
//}

/************************************************************************/
/* Face KeyPoints                    									*/
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createFace(JNIEnv* env, jclass thiz, jobjectArray modelPathArr) {
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, nullptr);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle FaceID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_Face(&FaceID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return FaceID;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyFace(JNIEnv* env, jclass thiz, jint faceID) {
    VNNHandle fID = (VNNHandle)faceID;
    return VNN_Destroy_Face(&fID);
}
static void outFaceToJava(JNIEnv* env, VNN_FaceFrameDataArr &detectData, jobject outData) {
    jclass objClass = env->GetObjectClass(outData);
    env->SetIntField(outData, env->GetFieldID(objClass, "facesNum","I"), detectData.facesNum);

    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_FaceFrameData");
    jobjectArray faceArr = env->NewObjectArray(detectData.facesNum, frameDataClass, NULL);

    for(int i = 0; i < detectData.facesNum; i++)
    {
        jobject frameData = env->AllocObject(frameDataClass);

        //get the floatArr in faceFrameData
        jfieldID faceLandmarksArrayID =  env->GetFieldID(frameDataClass,"faceLandmarks","[F");
        jfieldID faceLandmarkScoresArrayID =  env->GetFieldID(frameDataClass,"faceLandmarkScores","[F");
        jfieldID faceRectID =  env->GetFieldID(frameDataClass,"faceRect","[F");
        jfieldID faceLandmarksNumID = env->GetFieldID(frameDataClass, "faceLandmarksNum", "I");
        jfieldID faceScoreID = env->GetFieldID(frameDataClass, "faceScore", "F");
        jfieldID closeLeftID = env->GetFieldID(frameDataClass, "closeLeftEye", "Z");
        jfieldID closeRightID = env->GetFieldID(frameDataClass, "closeRightEye", "Z");
        jfieldID blinkLeftID = env->GetFieldID(frameDataClass, "blinkLeftEye", "Z");
        jfieldID blinkRightID = env->GetFieldID(frameDataClass, "blinkRightEye", "Z");
        jfieldID openMouthID = env->GetFieldID(frameDataClass, "openMouth", "Z");
        jfieldID shakeHeadID = env->GetFieldID(frameDataClass, "shakeHead", "Z");
        jfieldID nodHeadID = env->GetFieldID(frameDataClass, "nodHead", "Z");
        jfieldID openCloseMouthID = env->GetFieldID(frameDataClass, "openCloseMouth", "Z");
        jfieldID smileID = env->GetFieldID(frameDataClass, "smileScore", "F");
        jfieldID yawID = env->GetFieldID(frameDataClass, "faceYaw", "F");

        env->SetIntField(frameData, faceLandmarksNumID, (jint)detectData.facesArr[i].faceLandmarksNum);
        env->SetFloatField(frameData, faceScoreID, detectData.facesArr[i].faceScore);
        env->SetFloatField(frameData, smileID, detectData.facesArr[i].smileScore);
        env->SetFloatField(frameData, yawID, detectData.facesArr[i].faceYaw);
//        env->SetBooleanField(frameData, blinkLeftID, detectData.facesArr[i].ifBlinkLeftEye);
//        env->SetBooleanField(frameData, blinkRightID, detectData.facesArr[i].ifBlinkRightEye);
//        env->SetBooleanField(frameData, openMouthID, detectData.facesArr[i].ifOpenMouth);
//        env->SetBooleanField(frameData, shakeHeadID, detectData.facesArr[i].ifShakeHead);
//        env->SetBooleanField(frameData, nodHeadID, detectData.facesArr[i].ifNodHead);

        if(detectData.facesArr[i].ifCloseLeftEye == true)
            env->SetBooleanField(frameData, closeLeftID, true);
        else
            env->SetBooleanField(frameData, closeLeftID, false);

        if(detectData.facesArr[i].ifCloseRightEye == true)
            env->SetBooleanField(frameData, closeRightID, true);
        else
            env->SetBooleanField(frameData, closeRightID, false);

        if(detectData.facesArr[i].ifBlinkLeftEye == true)
            env->SetBooleanField(frameData, blinkLeftID, true);
        else
            env->SetBooleanField(frameData, blinkLeftID, false);

        if(detectData.facesArr[i].ifBlinkRightEye == true)
            env->SetBooleanField(frameData, blinkRightID, true);
        else
            env->SetBooleanField(frameData, blinkRightID, false);

        if(detectData.facesArr[i].ifOpenMouth == true)
            env->SetBooleanField(frameData, openMouthID, true);
        else
            env->SetBooleanField(frameData, openMouthID, false);

        if(detectData.facesArr[i].ifShakeHead == true)
            env->SetBooleanField(frameData, shakeHeadID, true);
        else
            env->SetBooleanField(frameData, shakeHeadID, false);

        if(detectData.facesArr[i].ifNodHead == true)
            env->SetBooleanField(frameData, nodHeadID, true);
        else
            env->SetBooleanField(frameData, nodHeadID, false);

        if(detectData.facesArr[i].ifOpenCloseMouth == true)
            env->SetBooleanField(frameData, openCloseMouthID, true);
        else
            env->SetBooleanField(frameData, openCloseMouthID, false);

        jfloatArray faceLandmarksArr = env->NewFloatArray(detectData.facesArr[i].faceLandmarksNum * 2);
        jfloatArray faceLandmarkScoresArr = env->NewFloatArray(detectData.facesArr[i].faceLandmarksNum);
        jfloatArray faceRectArr = env->NewFloatArray(4);

        jfloat* faceLandmarksArrPtr = env->GetFloatArrayElements(faceLandmarksArr, NULL);
        jfloat* faceLandmarkScoresArrPtr = env->GetFloatArrayElements(faceLandmarkScoresArr, NULL);
        jfloat* faceRectPtr = env->GetFloatArrayElements(faceRectArr, NULL);

        for(int x = 0; x < detectData.facesArr[i].faceLandmarksNum; x++)
        {
            faceLandmarksArrPtr[2 * x] = detectData.facesArr[i].faceLandmarks[x].x;
            faceLandmarksArrPtr[2 * x + 1] = detectData.facesArr[i].faceLandmarks[x].y;
        }
        memcpy(faceLandmarkScoresArrPtr, detectData.facesArr[i].faceLandmarkScores, sizeof(float) * detectData.facesArr[i].faceLandmarksNum);

        faceRectPtr[0] = detectData.facesArr[i].faceRect.x0;
        faceRectPtr[1] = detectData.facesArr[i].faceRect.y0;
        faceRectPtr[2] = detectData.facesArr[i].faceRect.x1;
        faceRectPtr[3] = detectData.facesArr[i].faceRect.y1;

//        env->SetFloatArrayRegion(faceLandmarksArr, 0,detectData.facesArr[i].faceLandmarksNum * 2, faceLandmarksArrPtr);
//        env->SetFloatArrayRegion(faceLandmarkScoresArr, 0,detectData.facesArr[i].faceLandmarksNum, faceLandmarkScoresArrPtr);
//        env->SetFloatArrayRegion(faceRectArr, 0,4, faceRectPtr);

        env->SetObjectField(frameData,faceLandmarksArrayID,faceLandmarksArr);
        env->SetObjectField(frameData,faceLandmarkScoresArrayID,faceLandmarkScoresArr);
        env->SetObjectField(frameData,faceRectID,faceRectArr);

        env->ReleaseFloatArrayElements(faceLandmarksArr,faceLandmarksArrPtr,0);
        env->ReleaseFloatArrayElements(faceLandmarkScoresArr,faceLandmarkScoresArrPtr,0);
        env->ReleaseFloatArrayElements(faceRectArr,faceRectPtr,0);

        env->SetObjectArrayElement(faceArr,i,frameData);
    }

    env->SetObjectField(outData,env->GetFieldID(objClass,"facesArr","[Lcom/duowan/vnnlib/VNN$VNN_FaceFrameData;"),faceArr);

    env->DeleteLocalRef(faceArr);
    env->DeleteLocalRef(frameDataClass);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setFacePoints(JNIEnv* env, jclass thiz,
                                                           jint faceID,
                                                           jint pointsNum) {
    int _use_278pts = 0;
    int _use_104pts = 0;
    switch(pointsNum) {
        case 104:
            _use_104pts = 1;
            VNN_Set_Face_Attr(faceID, "_use_104pts", &_use_104pts);
            break;
        case 278:
            _use_278pts = 1;
            VNN_Set_Face_Attr(faceID, "_use_278pts", &_use_278pts);
            break;
        default:
            VNN_Set_Face_Attr(faceID, "_use_278pts", &_use_278pts);
            break;
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyFaceCpu(JNIEnv* env, jclass thiz,
                                                          jint faceID,
                                                          jobject  inputData,
                                                          jobject outData) {
    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    //img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    jlong jori_fmt = env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.ori_fmt = (VNN_ORIENT_FMT) jori_fmt;
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_FaceFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_FaceFrameDataArr));
    int result = VNN_Apply_Face_CPU(faceID, &img, &detectData);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);

    if(detectData.facesNum < 0 || result != 0)
        return -1;

    outFaceToJava(env,detectData,outData);
    return 0;
}
void getFaceData(JNIEnv* env, jobject outData, VNN_FaceFrameDataArr &detectData) {
    jclass objClass = env->GetObjectClass(outData);
    jfieldID faceC_id = env->GetFieldID(objClass, "facesNum","I");
    int faceCount = env->GetIntField(outData, faceC_id);
    detectData.facesNum = (VNNUInt32)faceCount;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_FaceFrameData");
    jfieldID frameData_id = env->GetFieldID(objClass, "facesArr","[Lcom/duowan/vnnlib/VNN$VNN_FaceFrameData;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outData, frameData_id);
    for(int i = 0; i < faceCount; i++) {

        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfieldID faceLandmarksArrayID = env->GetFieldID(frameDataClass, "faceLandmarks", "[F");
        jfieldID faceLandmarkScoresArrayID = env->GetFieldID(frameDataClass, "faceLandmarkScores", "[F");
        jfieldID faceRectID = env->GetFieldID(frameDataClass, "faceRect", "[F");
        jfieldID inputHeightID = env->GetFieldID(frameDataClass, "inputHeight", "I");
        jfieldID inputWidthID = env->GetFieldID(frameDataClass, "inputWidth", "I");
        jfieldID faceLandmarksNumID = env->GetFieldID(frameDataClass, "faceLandmarksNum", "I");
        jfieldID faceScoreID = env->GetFieldID(frameDataClass, "faceScore", "F");
        jfieldID smileID = env->GetFieldID(frameDataClass, "smileScore", "F");
        jfieldID yawID = env->GetFieldID(frameDataClass, "faceYaw", "F");

        jfieldID closeLeftID = env->GetFieldID(frameDataClass, "closeLeftEye", "Z");
        jfieldID closeRightID = env->GetFieldID(frameDataClass, "closeRightEye", "Z");
        jfieldID blinkLeftID = env->GetFieldID(frameDataClass, "blinkLeftEye", "Z");
        jfieldID blinkRightID = env->GetFieldID(frameDataClass, "blinkRightEye", "Z");
        jfieldID openMouthID = env->GetFieldID(frameDataClass, "openMouth", "Z");
        jfieldID shakeHeadID = env->GetFieldID(frameDataClass, "shakeHead", "Z");
        jfieldID nodHeadID = env->GetFieldID(frameDataClass, "nodHead", "Z");
        jfieldID openCloseMouthID = env->GetFieldID(frameDataClass, "openCloseMouth", "Z");

        jfloatArray faceLandmarksArr = (jfloatArray) env->GetObjectField(frameData, faceLandmarksArrayID);
        jfloatArray faceLandmarkScoresArr = (jfloatArray) env->GetObjectField(frameData, faceLandmarkScoresArrayID);
        jfloatArray faceRectArr = (jfloatArray) env->GetObjectField(frameData, faceRectID);
        int faceLandmarksNum = env->GetIntField(frameData, faceLandmarksNumID);
        int inputWidth = env->GetIntField(frameData, inputWidthID);
        int inputHeight = env->GetIntField(frameData, inputHeightID);
        float faceScore = env->GetFloatField(frameData, faceScoreID);

        bool closeLeftEye = env->GetBooleanField(frameData, closeLeftID);
        bool closeRightEye = env->GetBooleanField(frameData, closeRightID);
        bool blinkLeftEye = env->GetBooleanField(frameData, blinkLeftID);
        bool blinkRightEye = env->GetBooleanField(frameData, blinkRightID);
        bool openMouth = env->GetBooleanField(frameData, openMouthID);
        bool shakeHead = env->GetBooleanField(frameData, shakeHeadID);
        bool nodHead = env->GetBooleanField(frameData, nodHeadID);
        bool openCloseMouth = env->GetBooleanField(frameData, openCloseMouthID);
        float smileScore = env->GetFloatField(frameData, smileID);
        float faceYaw = env->GetFloatField(frameData, yawID);

        detectData.facesArr[i].inputWidth = inputWidth;
        detectData.facesArr[i].inputHeight = inputHeight;
        detectData.facesArr[i].faceLandmarksNum = faceLandmarksNum;
        detectData.facesArr[i].faceScore = faceScore;
        detectData.facesArr[i].ifCloseLeftEye = closeLeftEye;
        detectData.facesArr[i].ifCloseRightEye = closeRightEye;
        detectData.facesArr[i].ifBlinkLeftEye = blinkLeftEye;
        detectData.facesArr[i].ifBlinkRightEye = blinkRightEye;
        detectData.facesArr[i].ifOpenMouth = openMouth;
        detectData.facesArr[i].ifShakeHead = shakeHead;
        detectData.facesArr[i].ifNodHead = nodHead;
        detectData.facesArr[i].ifOpenCloseMouth = openCloseMouth;

        detectData.facesArr[i].smileScore = smileScore;
        detectData.facesArr[i].faceYaw = faceYaw;

        jfloat* faceLandmarksArrPtr = env->GetFloatArrayElements(faceLandmarksArr, 0);
        jfloat* faceLandmarkScoresArrPtr = env->GetFloatArrayElements(faceLandmarkScoresArr, 0);
        jfloat* faceRectPtr = env->GetFloatArrayElements(faceRectArr, 0);
        for(int x = 0; x < faceLandmarksNum; x++)
        {
            detectData.facesArr[i].faceLandmarks[x].x = faceLandmarksArrPtr[2 * x];
            detectData.facesArr[i].faceLandmarks[x].y = faceLandmarksArrPtr[2 * x + 1];
        }

        memcpy(detectData.facesArr[i].faceLandmarkScores, faceLandmarkScoresArrPtr, sizeof(float) * faceLandmarksNum);

        detectData.facesArr[i].faceRect.x0 = faceRectPtr[0];
        detectData.facesArr[i].faceRect.y0 = faceRectPtr[1];
        detectData.facesArr[i].faceRect.x1 = faceRectPtr[2];
        detectData.facesArr[i].faceRect.y1 = faceRectPtr[3];

        env->ReleaseFloatArrayElements(faceLandmarksArr,faceLandmarksArrPtr,0);
        env->ReleaseFloatArrayElements(faceLandmarkScoresArr,faceLandmarkScoresArrPtr,0);
        env->ReleaseFloatArrayElements(faceRectArr,faceRectPtr,0);
    }
    env->DeleteLocalRef(frameDataArr);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(objClass);
}
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processFaceResultRotate(JNIEnv* env, jclass thiz, jint objID, jobject outData, jint rotate) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_FaceFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_FaceFrameDataArr));
    getFaceData(env, outData, detectData);
    if(VNN_FaceFrameDataArr_Result_Rotate(&detectData, rotate) == 0) {
        outFaceToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_getFaceDetectionRect(JNIEnv* env, jclass thiz,
                                                                  jint faceID, jobject outData) {
    VNN_FaceFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_FaceFrameDataArr));
    int ret = VNN_Get_Face_Attr(faceID, "_detection_data", &detectData);
    outFaceToJava(env,detectData,outData);
    return ret;
}

/************************************************************************/
/* faceparser                                                           */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createFaceParser(JNIEnv* env, jclass thiz, jobjectArray modelPathArr) {
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        //LOGV("createFaceParser model[%d] = %s", i, rawStr);
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle faceParserID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_FaceParser(&faceParserID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return faceParserID;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyFaceParserCpu(JNIEnv* env, jclass thiz,
                                                             jint faceParserID,
                                                             jobject inputData,
                                                             jobject faceArrData,
                                                             jobject outImgArrData) {

    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    if (faceArrData == NULL) {
        LOGE("faceArr data for FaceParser can not be null!!!");
        return -1;
    }
    VNN_FaceFrameDataArr faceArr;
    memset(&faceArr, 0x00, sizeof(VNN_FaceFrameDataArr));
    getFaceData(env, faceArrData, faceArr);

    VNN_ImageArr imgsArrData;
    jclass outClass = env->GetObjectClass(outImgArrData);
    jfieldID num_id = env->GetFieldID(outClass, "imgsNum","I");
    int facesNum = faceArr.facesNum;//env->GetIntField(outImgArrData, num_id);
    env->SetIntField(outImgArrData, num_id, facesNum);
    imgsArrData.imgsNum = facesNum;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Image");
    jfieldID frameData_id = env->GetFieldID(outClass, "imgsArr","[Lcom/duowan/vnnlib/VNN$VNN_Image;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outImgArrData, frameData_id);

    jfieldID widthID = env->GetFieldID(frameDataClass, "width", "I");
    jfieldID heightID = env->GetFieldID(frameDataClass, "height", "I");
    jfieldID rectID = env->GetFieldID(frameDataClass, "rect", "[F");
    jfieldID dataID = env->GetFieldID(frameDataClass, "data", "[B");
    jfieldID channelsID = env->GetFieldID(frameDataClass, "channels","I");
    jfieldID pixfmtID = env->GetFieldID(frameDataClass, "pix_fmt","I");
    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        int width = env->GetIntField(frameData, widthID);
        int height = env->GetIntField(frameData, heightID);
        imgsArrData.imgsArr[i].width = width;
        imgsArrData.imgsArr[i].height = height;
        jbyteArray outImgData = (jbyteArray) env->GetObjectField(frameData, dataID);
        jbyte* outImgDataPtr = env->GetByteArrayElements(outImgData, 0);
        imgsArrData.imgsArr[i].data = outImgDataPtr;
        env->ReleaseByteArrayElements(outImgData, outImgDataPtr, 0);
    }

    //VN_LOGE("jni start");
    int result = VNN_Apply_FaceParser_CPU(faceParserID, &img, &faceArr, &imgsArrData);
    //VN_LOGE("jni end");

    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfloatArray outRectData = (jfloatArray) env->GetObjectField(frameData, rectID);
        jfloat* outRectDataPtr = env->GetFloatArrayElements(outRectData, 0);
        float rect[4] = {imgsArrData.imgsArr[i].rect.x0, imgsArrData.imgsArr[i].rect.y0, imgsArrData.imgsArr[i].rect.x1, imgsArrData.imgsArr[i].rect.y1};

        memcpy(outRectDataPtr, rect, sizeof(float) * 4);
        env->ReleaseFloatArrayElements(outRectData, outRectDataPtr, 0);

        env->SetIntField(frameData, channelsID, (jint)(imgsArrData.imgsArr[i].channels));
        env->SetIntField(frameData, pixfmtID, (jint)(imgsArrData.imgsArr[i].pix_fmt));
    }

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(outClass);

    if(result != 0)
        return -1;
    return 0;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyFaceParser(JNIEnv* env, jclass thiz, jint faceParserID) {
    VNNHandle fID = (VNNHandle)faceParserID;
    return VNN_Destroy_FaceParser(&fID);
}

/************************************************************************/
/* Stylizing                    									    */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createStylizing(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle segID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_Stylizing(&segID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return segID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyStylizingCpu(JNIEnv* env, jclass thiz,
                                                               jint vnnID,
                                                               jobject inputData,
                                                               jobject faceArrData,
                                                               jobject outImgArrData){
    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    if (faceArrData == NULL) {
        LOGD("if face info is used, face data can not be null!!!");
        return -1;
    }

    VNN_FaceFrameDataArr faceArr;
    memset(&faceArr, 0x00, sizeof(VNN_FaceFrameDataArr));
    getFaceData(env, faceArrData, faceArr);

    VNN_ImageArr imgsArrData;
    jclass outClass = env->GetObjectClass(outImgArrData);
    jfieldID num_id = env->GetFieldID(outClass, "imgsNum","I");
    int facesNum = faceArr.facesNum;//env->GetIntField(outImgArrData, num_id);
    env->SetIntField(outImgArrData, num_id, facesNum);
    imgsArrData.imgsNum = facesNum;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Image");
    jfieldID frameData_id = env->GetFieldID(outClass, "imgsArr","[Lcom/duowan/vnnlib/VNN$VNN_Image;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outImgArrData, frameData_id);

    jfieldID widthID = env->GetFieldID(frameDataClass, "width", "I");
    jfieldID heightID = env->GetFieldID(frameDataClass, "height", "I");
    jfieldID rectID = env->GetFieldID(frameDataClass, "rect", "[F");
    jfieldID dataID = env->GetFieldID(frameDataClass, "data", "[B");
    jfieldID channelsID = env->GetFieldID(frameDataClass, "channels","I");
    jfieldID pixfmtID = env->GetFieldID(frameDataClass, "pix_fmt","I");
    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        int width = env->GetIntField(frameData, widthID);
        int height = env->GetIntField(frameData, heightID);
        imgsArrData.imgsArr[i].width = width;
        imgsArrData.imgsArr[i].height = height;
        jbyteArray outImgData = (jbyteArray) env->GetObjectField(frameData, dataID);
        jbyte* outImgDataPtr = env->GetByteArrayElements(outImgData, 0);
        imgsArrData.imgsArr[i].data = outImgDataPtr;
        env->ReleaseByteArrayElements(outImgData, outImgDataPtr, 0);
    }

    //VN_LOGE("jni start");
    int result = VNN_Apply_Stylizing_CPU(vnnID, &img, &faceArr, &imgsArrData);
    //VN_LOGE("jni end");

    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfloatArray outRectData = (jfloatArray) env->GetObjectField(frameData, rectID);
        jfloat* outRectDataPtr = env->GetFloatArrayElements(outRectData, 0);
        float rect[4] = {imgsArrData.imgsArr[i].rect.x0, imgsArrData.imgsArr[i].rect.y0, imgsArrData.imgsArr[i].rect.x1, imgsArrData.imgsArr[i].rect.y1};

        memcpy(outRectDataPtr, rect, sizeof(float) * 4);
        env->ReleaseFloatArrayElements(outRectData, outRectDataPtr, 0);

        env->SetIntField(frameData, channelsID, (jint)(imgsArrData.imgsArr[i].channels));
        env->SetIntField(frameData, pixfmtID, (jint)(imgsArrData.imgsArr[i].pix_fmt));
    }

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(outClass);

    if(result != 0)
        return -1;
    return 0;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_getImageArrStylizing(JNIEnv* env, jclass thiz,
                                                                  jint fID,
                                                                  jstring key,
                                                                  jobject outImgArrData) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);
    VNN_ImageArr imgsArrData;
    jclass outClass = env->GetObjectClass(outImgArrData);
    jfieldID num_id = env->GetFieldID(outClass, "imgsNum","I");

    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Image");
    jfieldID frameData_id = env->GetFieldID(outClass, "imgsArr","[Lcom/duowan/vnnlib/VNN$VNN_Image;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outImgArrData, frameData_id);

    jfieldID widthID = env->GetFieldID(frameDataClass, "width", "I");
    jfieldID heightID = env->GetFieldID(frameDataClass, "height", "I");
    jfieldID rectID = env->GetFieldID(frameDataClass, "rect", "[F");
    jfieldID dataID = env->GetFieldID(frameDataClass, "data", "[B");
    jfieldID channelsID = env->GetFieldID(frameDataClass, "channels","I");
    jfieldID pixfmtID = env->GetFieldID(frameDataClass, "pix_fmt","I");
    int inNum = env->GetIntField(outImgArrData, num_id);
    if(inNum <= 0 || inNum > VNN_FRAMEDATAARR_MAX_FACES_NUM) {
        inNum = VNN_FRAMEDATAARR_MAX_FACES_NUM;
    }
    int facesNum = inNum;
    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        int width = env->GetIntField(frameData, widthID);
        int height = env->GetIntField(frameData, heightID);
        imgsArrData.imgsArr[i].width = width;
        imgsArrData.imgsArr[i].height = height;
        jbyteArray outImgData = (jbyteArray) env->GetObjectField(frameData, dataID);
        jbyte* outImgDataPtr = env->GetByteArrayElements(outImgData, 0);
        imgsArrData.imgsArr[i].data = outImgDataPtr;
        env->ReleaseByteArrayElements(outImgData, outImgDataPtr, 0);
    }

    //VN_LOGE("jni start");
    int result = VNN_Get_Stylizing_Attr(fID, keyStr, &imgsArrData);
    //VN_LOGE("jni end");
    facesNum = imgsArrData.imgsNum;
    env->SetIntField(outImgArrData, num_id, facesNum);
    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfloatArray outRectData = (jfloatArray) env->GetObjectField(frameData, rectID);
        jfloat* outRectDataPtr = env->GetFloatArrayElements(outRectData, 0);
        float rect[4] = {imgsArrData.imgsArr[i].rect.x0, imgsArrData.imgsArr[i].rect.y0, imgsArrData.imgsArr[i].rect.x1, imgsArrData.imgsArr[i].rect.y1};

        memcpy(outRectDataPtr, rect, sizeof(float) * 4);
        env->ReleaseFloatArrayElements(outRectData, outRectDataPtr, 0);

        env->SetIntField(frameData, channelsID, (jint)(imgsArrData.imgsArr[i].channels));
        env->SetIntField(frameData, pixfmtID, (jint)(imgsArrData.imgsArr[i].pix_fmt));
    }

    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(outClass);

    if(result != 0)
        return -1;
    return 0;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyStylizing(JNIEnv* env, jclass thiz, jint vnnID) {
    VNNHandle vID = (VNNHandle)vnnID;
    return VNN_Destroy_Stylizing(&vID);
}

/************************************************************************/
/* Face Reenactment                    									*/
/************************************************************************/

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createFaceReenactment(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle segID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_FaceReenactment(&segID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return segID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyFaceReenactmentCpu(JNIEnv* env, jclass thiz,
                                                           jint fID,
                                                           jint frame_idx,
                                                           jobject outData){


    VNN_Image outImg;
    jclass outClass = env->GetObjectClass(outData);
    jbyteArray outImgData = (jbyteArray) env->GetObjectField(outData, env->GetFieldID(outClass, "data", "[B"));
    jbyte* outImgDataPtr = env->GetByteArrayElements(outImgData, 0);
    outImg.data = (unsigned char*)outImgDataPtr;
    outImg.width = env->GetIntField(outData, env->GetFieldID(outClass, "width","I"));
    outImg.height = env->GetIntField(outData, env->GetFieldID(outClass, "height","I"));
    outImg.pix_fmt = VNN_PIX_FMT_RGB888;
    int ret = VNN_Apply_FaceReenactment_CPU(fID, &frame_idx, &outImg);

//    env->SetIntField(outData, env->GetFieldID(outClass, "width","I"), (jint)(outImg.width));
//    env->SetIntField(outData, env->GetFieldID(outClass, "height","I"), (jint)(outImg.height));
    env->SetIntField(outData, env->GetFieldID(outClass, "channels","I"), (jint)(outImg.channels));
    env->SetIntField(outData, env->GetFieldID(outClass, "pix_fmt","I"), (jint)(outImg.pix_fmt));

    env->ReleaseByteArrayElements(outImgData, outImgDataPtr,0);
    env->DeleteLocalRef(outClass);
    if(ret != 0) {
        return ret;
    }

    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyFaceReenactment(JNIEnv* env, jclass thiz, jint fID) {
    VNNHandle frID = (VNNHandle)fID;
    return VNN_Destroy_FaceReenactment(&frID);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_getIntFaceReenactment(JNIEnv* env, jclass thiz,
                                                           jint fID,
                                                           jstring key) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);
    int _val = -1;
    int ret = VNN_Get_FaceReenactment_Attr(fID, keyStr, &_val);
    env->ReleaseStringUTFChars(key, keyStr);
    return _val;
}
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setStringFaceReenactment(JNIEnv* env, jclass thiz,
                                                                   jint fID,
                                                                   jstring key,
                                                                   jstring val) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);
    const char* valStr = env->GetStringUTFChars(val, VNN_NULL);
//    std::string _val = valStr;
    int ret = VNN_Set_FaceReenactment_Attr(fID, keyStr, valStr);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseStringUTFChars(val, valStr);
    return ret;
}
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setImageFaceReenactment(JNIEnv* env, jclass thiz,
                                                                      jint fID,
                                                                      jstring key,
                                                                     jobject inputData) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);

    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    int ret = VNN_Set_FaceReenactment_Attr(fID, keyStr, &img);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseByteArrayElements(imgData, imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setRectFaceReenactment(JNIEnv* env, jclass thiz,
                                                                     jint fID,
                                                                     jstring key,
                                                                     jfloatArray rect) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);

    float* rectPtr = env->GetFloatArrayElements(rect, 0);
    VNN_Rect2D face_rect;
    face_rect.x0 = rectPtr[0];
    face_rect.y0 = rectPtr[1];
    face_rect.x1 = rectPtr[2];
    face_rect.y1 = rectPtr[3];


    int ret = VNN_Set_FaceReenactment_Attr(fID, keyStr, &face_rect);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseFloatArrayElements(rect, (jfloat*) rectPtr, 0);
    return ret;
}

/************************************************************************/
/* Gesture                                                              */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createGesture(JNIEnv* env, jclass thiz, jobjectArray modelPathArr) {
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle vnnID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_Gesture(&vnnID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return vnnID;

}

static void outGestureToJava(JNIEnv* env, VNN_GestureFrameDataArr &detectData, jobject outData) {
    jclass objClass = env->GetObjectClass(outData);
    env->SetIntField(outData, env->GetFieldID(objClass, "count","I"), detectData.gestureNum);

    jclass gestureClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_GestureFrameData");
    jobjectArray gestureArr = env->NewObjectArray(detectData.gestureNum, gestureClass, NULL);

    for(int i = 0; i < detectData.gestureNum; i++)
    {
        jobject gesture = env->AllocObject(gestureClass);
        env->SetIntField(gesture, env->GetFieldID(gestureClass, "type", "I"), (int)detectData.gestureArr[i].type);
        env->SetFloatField(gesture, env->GetFieldID(gestureClass, "score", "F"), detectData.gestureArr[i].score);
        jfieldID rectID =  env->GetFieldID(gestureClass,"rect","[F");
        jfloatArray rectArr = env->NewFloatArray(4);
        jfloat* rectPtr = env->GetFloatArrayElements(rectArr, NULL);
        rectPtr[0] = detectData.gestureArr[i].rect.x0;
        rectPtr[1] = detectData.gestureArr[i].rect.y0;
        rectPtr[2] = detectData.gestureArr[i].rect.x1;
        rectPtr[3] = detectData.gestureArr[i].rect.y1;

        env->SetObjectField(gesture, rectID, rectArr);
        env->ReleaseFloatArrayElements(rectArr, rectPtr, 0);


        env->SetObjectArrayElement(gestureArr, i, gesture);
        env->DeleteLocalRef(gesture);
    }

    env->SetObjectField(outData, env->GetFieldID(objClass, "arr", "[Lcom/duowan/vnnlib/VNN$VNN_GestureFrameData;"), gestureArr);
    env->DeleteLocalRef(gestureClass);
    env->DeleteLocalRef(gestureArr);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyGestureCpu(JNIEnv* env, jclass thiz,
                                                            jint vnnID,
                                                            jobject  inputData,
                                                            jobject outData) {
    if(inputData == NULL) {
        LOGE("Input data for ObjCount can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    //img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    jlong jori_fmt = env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.ori_fmt = (VNN_ORIENT_FMT) jori_fmt;
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_GestureFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_GestureFrameDataArr));
    int result = VNN_Apply_Gesture_CPU(vnnID, &img, &detectData);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);

    if(detectData.gestureNum < 0 || result != 0)
        return -1;

    outGestureToJava(env,detectData,outData);
    return result;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyGesture(JNIEnv* env, jclass thiz, jint vnnID) {
    VNNHandle vID = (VNNHandle)vnnID;
    return VNN_Destroy_Gesture(&vID);
}

void static getGestureData(JNIEnv* env, jobject outData, VNN_GestureFrameDataArr &detectData) {
    jclass objClass = env->GetObjectClass(outData);
    jfieldID gestureC_id = env->GetFieldID(objClass, "count","I");
    int gestureCount = env->GetIntField(outData, gestureC_id);
    detectData.gestureNum = (VNNUInt32)gestureCount;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_GestureFrameData");
    jfieldID frameData_id = env->GetFieldID(objClass, "arr","[Lcom/duowan/vnnlib/VNN$VNN_GestureFrameData;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outData, frameData_id);
    for(int i = 0; i < gestureCount; i++) {

        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfieldID gestureRectID = env->GetFieldID(frameDataClass, "rect", "[F");
        jfieldID gestureScoreID = env->GetFieldID(frameDataClass, "score", "F");
        jfieldID gestureTypeID = env->GetFieldID(frameDataClass, "type", "I");
        jfloatArray gestureRectArr = (jfloatArray) env->GetObjectField(frameData, gestureRectID);
        float gestureScore = env->GetFloatField(frameData, gestureScoreID);
        int gestureType = env->GetIntField(frameData, gestureTypeID);

        detectData.gestureArr[i].score = gestureScore;
        detectData.gestureArr[i].type = (VNN_GestureType)gestureType;



        jfloat* gestureRectPtr = env->GetFloatArrayElements(gestureRectArr, 0);

        detectData.gestureArr[i].rect.x0 = gestureRectPtr[0];
        detectData.gestureArr[i].rect.y0 = gestureRectPtr[1];
        detectData.gestureArr[i].rect.x1 = gestureRectPtr[2];
        detectData.gestureArr[i].rect.y1 = gestureRectPtr[3];
        env->ReleaseFloatArrayElements(gestureRectArr,gestureRectPtr,0);
    }
    env->DeleteLocalRef(frameDataArr);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(objClass);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processGestureResultRotate(JNIEnv* env, jclass thiz, jint objID, jobject outData, jint rotate) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_GestureFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_GestureFrameDataArr));
    getGestureData(env, outData, detectData);
    if(VNN_GestureFrameDataArr_Result_Rotate(&detectData, rotate) == 0) {
        outGestureToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processGestureResultMirror(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_GestureFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_GestureFrameDataArr));
    getGestureData(env, outData, detectData);
    if(VNN_GestureFrameDataArr_Result_Mirror(&detectData) == 0) {
        outGestureToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processGestureResultFlipV(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_GestureFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_GestureFrameDataArr));
    getGestureData(env, outData, detectData);
    if(VNN_GestureFrameDataArr_Result_FlipV(&detectData) == 0) {
        outGestureToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

/************************************************************************/
/* Object Tracking                   									*/
/************************************************************************/
static void outObjCountToJava(JNIEnv* env, VNN_ObjCountDataArr &detectData, jobject outData) {
    jclass objClass = env->GetObjectClass(outData);
    env->SetIntField(outData, env->GetFieldID(objClass, "count","I"), detectData.count);

    jclass rectClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Rect2D");
    jobjectArray rectArr = env->NewObjectArray(detectData.count, rectClass, NULL);

    for(int i = 0; i < detectData.count; i++)
    {
        jobject rect = env->AllocObject(rectClass);
        env->SetFloatField(rect, env->GetFieldID(rectClass, "x0", "F"), detectData.objRectArr[i].x0);
        env->SetFloatField(rect, env->GetFieldID(rectClass, "y0", "F"), detectData.objRectArr[i].y0);
        env->SetFloatField(rect, env->GetFieldID(rectClass, "x1", "F"), detectData.objRectArr[i].x1);
        env->SetFloatField(rect, env->GetFieldID(rectClass, "y1", "F"), detectData.objRectArr[i].y1);

        env->SetObjectArrayElement(rectArr, i, rect);
        env->DeleteLocalRef(rect);
    }

    env->SetObjectField(outData, env->GetFieldID(objClass, "objRectArr", "[Lcom/duowan/vnnlib/VNN$VNN_Rect2D;"), rectArr);
    env->DeleteLocalRef(rectClass);
    env->DeleteLocalRef(rectArr);
    env->DeleteLocalRef(objClass);
}
static void getObjCountData(JNIEnv* env, jobject outData, VNN_ObjCountDataArr &detectData) {
    jclass objClass = env->GetObjectClass(outData);
    jfieldID count_id = env->GetFieldID(objClass, "count","I");
    int count = env->GetIntField(outData, count_id);
    detectData.count = count;
    detectData.objRectArr = (VNN_Rect2D *)calloc(count, sizeof(VNN_Rect2D));
    jclass rectClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Rect2D");
    jfieldID rectData_id = env->GetFieldID(objClass, "objRectArr","[Lcom/duowan/vnnlib/VNN$VNN_Rect2D;");
    jobjectArray rectDataArr = (jobjectArray)env->GetObjectField(outData, rectData_id);
    for(int i = 0; i < count; i++) {
        jobject rectData = env->GetObjectArrayElement(rectDataArr, i);
        jfieldID x0ID = env->GetFieldID(rectClass, "x0", "F");
        jfieldID y0ID = env->GetFieldID(rectClass, "y0", "F");
        jfieldID x1ID = env->GetFieldID(rectClass, "x1", "F");
        jfieldID y1ID = env->GetFieldID(rectClass, "y1", "F");

        detectData.objRectArr[i].x0 = env->GetFloatField(rectData, x0ID);
        detectData.objRectArr[i].y0 = env->GetFloatField(rectData, y0ID);
        detectData.objRectArr[i].x1 = env->GetFloatField(rectData, x1ID);
        detectData.objRectArr[i].y1 = env->GetFloatField(rectData, y1ID);
        env->DeleteLocalRef(rectData);
    }
    env->DeleteLocalRef(rectClass);
    env->DeleteLocalRef(rectDataArr);
    env->DeleteLocalRef(objClass);
}
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createObjectTracking(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle segID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_ObjTracking(&segID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return segID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyObjectTrackingCpu(JNIEnv* env, jclass thiz,
                                                                     jint objID,
                                                                     jobject inputData,
                                                                     jobject outData){
    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_ObjCountDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_ObjCountDataArr));
    int ret = VNN_Apply_ObjTracking_CPU(objID, &img, &detectData);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);

    if(ret != 0) {
        return ret;
    }
    outObjCountToJava(env, detectData, outData);
    VNN_ObjCountDataArr_Free(&detectData);
    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyObjectTracking(JNIEnv* env, jclass thiz, jint fID) {
    VNNHandle frID = (VNNHandle)fID;
    return VNN_Destroy_ObjTracking(&frID);
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setImageObjectTracking(JNIEnv* env, jclass thiz,
                                                                     jint fID,
                                                                     jstring key,
                                                                     jobject inputData) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);

    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    int ret = VNN_Set_ObjTracking_Attr(fID, keyStr, &img);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseByteArrayElements(imgData, imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setRectObjectTracking(JNIEnv* env, jclass thiz,
                                                                    jint fID,
                                                                    jstring key,
                                                                    jfloatArray rect) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);

    float* rectPtr = env->GetFloatArrayElements(rect, 0);
    VNN_Rect2D face_rect;
    face_rect.x0 = rectPtr[0];
    face_rect.y0 = rectPtr[1];
    face_rect.x1 = rectPtr[2];
    face_rect.y1 = rectPtr[3];


    int ret = VNN_Set_ObjTracking_Attr(fID, keyStr, &face_rect);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseFloatArrayElements(rect, (jfloat*) rectPtr, 0);
    return ret;
}
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setClearImageObjectTracking(JNIEnv* env, jclass thiz,
                                                                        jint fID) {

    bool clear = true;
    int ret = VNN_Set_ObjTracking_Attr(fID, "_clearImage", &clear);
    return ret;
}

/************************************************************************/
/* Object Count                     									*/
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createObjCount(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    VNNHandle vnnID;
    std::string strModelPath[2];

    int strCount = env->GetArrayLength(modelPathArr);

    LOGD("create ObjCount model count = %d.", strCount);
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }
    const char* pStr[2];
    pStr[0] = strModelPath[0].c_str();
    pStr[1] = strModelPath[1].c_str();


    int result = VNN_Create_ObjCount(&vnnID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    if(result != 0)
        return -1;
    return vnnID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyObjCountCpu(JNIEnv* env, jclass thiz,
                                                              jint objID,
                                                              jobject inputData,
                                                              jobject outData){
    if(inputData == NULL) {
        LOGE("Input data for ObjCount can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_ObjCountDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_ObjCountDataArr));
    int ret = VNN_Apply_ObjCount_CPU(objID, &img, &detectData);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);

    if(ret != 0) {
        return ret;
    }
    outObjCountToJava(env, detectData, outData);
    VNN_ObjCountDataArr_Free(&detectData);
    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyObjCount(JNIEnv* env, jclass thiz, jint objID) {
    VNNHandle oID = (VNNHandle)objID;
    return VNN_Destroy_ObjCount(&oID);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processObjectCountResultRotate(JNIEnv* env, jclass thiz, jint objID, jobject outData, jint rotate) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_ObjCountDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_ObjCountDataArr));
    getObjCountData(env, outData, detectData);
    if(VNN_ObjCountDataArr_Result_Rotate(&detectData, rotate) == 0) {
        outObjCountToJava(env, detectData, outData);
        VNN_ObjCountDataArr_Free(&detectData);
        return 0;
    }
    VNN_ObjCountDataArr_Free(&detectData);
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processObjectCountResultMirror(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_ObjCountDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_ObjCountDataArr));
    getObjCountData(env, outData, detectData);
    if(VNN_ObjCountDataArr_Result_Mirror(&detectData) == 0) {
        outObjCountToJava(env, detectData, outData);
        VNN_ObjCountDataArr_Free(&detectData);
        return 0;
    }
    VNN_ObjCountDataArr_Free(&detectData);
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processObjectCountResultFlipV(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_ObjCountDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_ObjCountDataArr));
    getObjCountData(env, outData, detectData);
    if(VNN_ObjCountDataArr_Result_FlipV(&detectData) == 0) {
        outObjCountToJava(env, detectData, outData);
        VNN_ObjCountDataArr_Free(&detectData);
        return 0;
    }
    VNN_ObjCountDataArr_Free(&detectData);
    return -1;
}


/************************************************************************/
/* Document Rectification            									*/
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createDocRect(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle vnnID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_DocRect(&vnnID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return vnnID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyDocRectCpu(JNIEnv* env, jclass thiz,
                                                             jint docID,
                                                             jobject inputData,
                                                             jfloatArray outData){
    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_Point2D outdata[4];
    int ret = VNN_Apply_DocRect_CPU(docID, &img, outdata);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    if(ret != 0) {
        return ret;
    }

    float* out = env->GetFloatArrayElements(outData, 0);
    for(int i = 0; i < 4; i++) {
        out[i * 2] = outdata[i].x;
        out[i * 2 + 1] = outdata[i].y;
    }
    env->ReleaseFloatArrayElements(outData, (jfloat*) out, 0);
    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyDocRect(JNIEnv* env, jclass thiz, jint docID) {
    VNNHandle aID = (VNNHandle)docID;
    return VNN_Destroy_DocRect(&aID);
}

/************************************************************************/
/* General                     									        */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createGeneral(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle segID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_General(&segID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return segID;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyGeneralSegmentCpu(JNIEnv* env, jclass thiz,
                                                                 jint docID,
                                                                 jobject inputData,
                                                                 jobject faceArrData,
                                                                 jobject outImgArrData){
    if(inputData == NULL) {
        LOGE("Input data for ObjCount can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_FaceFrameDataArr* face_data = NULL;
    VNN_FaceFrameDataArr faceArr;
    memset(&faceArr, 0x00, sizeof(VNN_FaceFrameDataArr));
    if (faceArrData != NULL) {
        getFaceData(env, faceArrData, faceArr);
        face_data = &faceArr;
    }

    VNN_ImageArr imgsArrData;
    jclass outClass = env->GetObjectClass(outImgArrData);
    jfieldID num_id = env->GetFieldID(outClass, "imgsNum","I");
    int facesNum = env->GetIntField(outImgArrData, num_id);
    imgsArrData.imgsNum = facesNum;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_Image");
    jfieldID frameData_id = env->GetFieldID(outClass, "imgsArr","[Lcom/duowan/vnnlib/VNN$VNN_Image;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outImgArrData, frameData_id);

    jfieldID widthID = env->GetFieldID(frameDataClass, "width", "I");
    jfieldID heightID = env->GetFieldID(frameDataClass, "height", "I");
    jfieldID rectID = env->GetFieldID(frameDataClass, "rect", "[F");
    jfieldID dataID = env->GetFieldID(frameDataClass, "data", "[B");
    jfieldID channelsID = env->GetFieldID(frameDataClass, "channels","I");
    jfieldID pixfmtID = env->GetFieldID(frameDataClass, "pix_fmt","I");
    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        int width = env->GetIntField(frameData, widthID);
        int height = env->GetIntField(frameData, heightID);
        imgsArrData.imgsArr[i].width = width;
        imgsArrData.imgsArr[i].height = height;
        jbyteArray outImgData = (jbyteArray) env->GetObjectField(frameData, dataID);
        jbyte* outImgDataPtr = env->GetByteArrayElements(outImgData, 0);
        imgsArrData.imgsArr[i].data = outImgDataPtr;
        env->ReleaseByteArrayElements(outImgData, outImgDataPtr, 0);
    }
    int ret = VNN_Apply_General_CPU(docID, &img, face_data, &imgsArrData);

    for(int i = 0; i < facesNum; i++) {
        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        jfloatArray outRectData = (jfloatArray) env->GetObjectField(frameData, rectID);
        jfloat* outRectDataPtr = env->GetFloatArrayElements(outRectData, 0);
        float rect[4] = {imgsArrData.imgsArr[i].rect.x0, imgsArrData.imgsArr[i].rect.y0, imgsArrData.imgsArr[i].rect.x1, imgsArrData.imgsArr[i].rect.y1};

        memcpy(outRectDataPtr, rect, sizeof(float) * 4);
        env->ReleaseFloatArrayElements(outRectData, outRectDataPtr, 0);

        env->SetIntField(frameData, channelsID, (jint)(imgsArrData.imgsArr[i].channels));
        env->SetIntField(frameData, pixfmtID, (jint)(imgsArrData.imgsArr[i].pix_fmt));
    }
    env->ReleaseByteArrayElements(imgData, imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(outClass);
    if(ret != 0) {
        return ret;
    }

    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyGeneral(JNIEnv* env, jclass thiz, jint segID) {
    VNNHandle sID = (VNNHandle)segID;
    return VNN_Destroy_General(&sID);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_getGeneralInt(JNIEnv* env, jclass thiz,
                                                           jint segID,
                                                           jstring name) {
    const char* cname = env->GetStringUTFChars(name, nullptr);
    int val = 0;
    VNN_Get_General_Attr(segID, cname, &val);
    return val;
}


/************************************************************************/
/* Classifying                									        */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createClassifying(JNIEnv* env, jclass thiz, jobjectArray modelPathArr){
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle vnnID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_Classifying(&vnnID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return vnnID;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_setStringClassifying(JNIEnv* env, jclass thiz,
                                                                      jint fID,
                                                                      jstring key,
                                                                      jstring val) {
    const char* keyStr = env->GetStringUTFChars(key, VNN_NULL);
    const char* valStr = env->GetStringUTFChars(val, VNN_NULL);
//    std::string _val = valStr;
    int ret = VNN_Set_Classifying_Attr(fID, keyStr, valStr);
    env->ReleaseStringUTFChars(key, keyStr);
    env->ReleaseStringUTFChars(val, valStr);
    return ret;
}
static void outMultiClassificationToJava(JNIEnv* env, VNN_MultiClsTopNAccArr &detectData, jobject outData) {
    jclass objClass = env->GetObjectClass(outData);
    env->SetIntField(outData, env->GetFieldID(objClass, "numOut","I"), detectData.numOut);

    jclass frameDataArrClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_ClsTopNAccArr");
    jobjectArray multiClsArr = env->NewObjectArray(detectData.numOut, frameDataArrClass, NULL);
    jclass stringClass = env->FindClass("java/lang/String");

    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_ClsTopNAcc");

    for(int k = 0; k < detectData.numOut; k++) {
        jobject frameArrData = env->AllocObject(frameDataArrClass);
        jobjectArray clsArr = env->NewObjectArray(detectData.multiClsArr[k].numCls, frameDataClass, NULL);
        env->SetIntField(frameArrData, env->GetFieldID(frameDataArrClass, "numCls","I"), (int)detectData.multiClsArr[k].numCls);
        for(int i = 0; i < detectData.multiClsArr[k].numCls; i++)
        {
            jobject frameData = env->AllocObject(frameDataClass);
            jobjectArray labelArr = env->NewObjectArray(detectData.multiClsArr[k].clsArr[i].usedTopN, stringClass, NULL);
            jstring jstr;
            int usedTopN = detectData.multiClsArr[k].clsArr[i].usedTopN;
            for(int j = 0; j < usedTopN; j++) {
                jstr = env->NewStringUTF(detectData.multiClsArr[k].clsArr[i].labels[j]);
                env->SetObjectArrayElement(labelArr, j, jstr);
            }
            env->DeleteLocalRef(jstr);

            jfieldID categoriesID =  env->GetFieldID(frameDataClass,"categories","[I");
            jfieldID probID =  env->GetFieldID(frameDataClass,"probabilities","[F");
            jfieldID lableID = env->GetFieldID(frameDataClass,"labels","[Ljava/lang/String;");

            jintArray categoriesArr = env->NewIntArray(usedTopN);
            jfloatArray probArr = env->NewFloatArray(usedTopN);

            jint* categoriesArrPtr = env->GetIntArrayElements(categoriesArr, NULL);
            jfloat* probArrPtr = env->GetFloatArrayElements(probArr, NULL);


            memcpy(categoriesArrPtr, detectData.multiClsArr[k].clsArr[i].categories, sizeof(int) * usedTopN);
            memcpy(probArrPtr, detectData.multiClsArr[k].clsArr[i].probabilities, sizeof(float) * usedTopN);


            env->SetObjectField(frameData, categoriesID, categoriesArr);
            env->SetObjectField(frameData, probID, probArr);
            env->SetObjectField(frameData, lableID, labelArr);

            env->ReleaseIntArrayElements(categoriesArr, categoriesArrPtr, 0);
            env->ReleaseFloatArrayElements(probArr, probArrPtr, 0);

            env->SetObjectArrayElement(clsArr, i, frameData);
            env->DeleteLocalRef(labelArr);
        }
        jfieldID clsArrID = env->GetFieldID(frameDataArrClass,"clsArr","[Lcom/duowan/vnnlib/VNN$VNN_ClsTopNAcc;");
        env->SetObjectField(frameArrData, clsArrID, clsArr);
        env->SetObjectArrayElement(multiClsArr, k, frameArrData);
        env->DeleteLocalRef(clsArr);
    }
    env->SetObjectField(outData,env->GetFieldID(objClass,"multiClsArr","[Lcom/duowan/vnnlib/VNN$VNN_ClsTopNAccArr;"), multiClsArr);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(frameDataArrClass);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyClassifyingCpu(JNIEnv* env, jclass thiz,
                                                                 jint vnnID,
                                                                 jobject inputData,
                                                                 jobject faceArrData,
                                                                 jobject outData){
    if(inputData == NULL) {
        LOGE("Input data can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_MultiClsTopNAccArr outResult;

    VNN_FaceFrameDataArr* face_data = NULL;
    VNN_FaceFrameDataArr faceArr;
    memset(&faceArr, 0x00, sizeof(VNN_FaceFrameDataArr));
    if (faceArrData != NULL) {
        getFaceData(env, faceArrData, faceArr);
        face_data = &faceArr;
    }

    int ret = VNN_Apply_Classifying_CPU(vnnID, &img, face_data, &outResult);
    outMultiClassificationToJava(env, outResult, outData);
    env->ReleaseByteArrayElements(imgData, imgDataPtr,0);
    env->DeleteLocalRef(inputClass);
    if(ret != 0) {
        return ret;
    }

    return ret;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyClassifying(JNIEnv* env, jclass thiz, jint vnnID) {
    VNNHandle vID = (VNNHandle)vnnID;
    return VNN_Destroy_Classifying(&vID);
}

/************************************************************************/
/* Pose Landmarks                                                       */
/************************************************************************/
JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_createPoseLandmarks(JNIEnv* env, jclass thiz, jobjectArray modelPathArr) {
    int strCount = env->GetArrayLength(modelPathArr);
    std::string* strModelPath = new std::string[strCount];
    for (int i = 0; i < strCount; i++)
    {
        jstring modelPath = (jstring)(env->GetObjectArrayElement(modelPathArr, i));
        const char* rawStr = env->GetStringUTFChars(modelPath, VNN_NULL);
        strModelPath[i] = rawStr;
        env->ReleaseStringUTFChars(modelPath, rawStr);
    }

    VNNHandle vnnID = 0;
    const char** pStr = new const char* [strCount];
    for (int i = 0; i < strCount; i++)
    {
        pStr[i] = strModelPath[i].c_str();
    }
    int result = VNN_Create_Pose(&vnnID, strCount, (const void**)pStr);
    env->DeleteLocalRef(modelPathArr);
    delete[] strModelPath;
    delete[] pStr;
    if(result != 0)
        return -1;
    return vnnID;

}

static void outPoseLandmarksToJava (JNIEnv* env, VNN_BodyFrameDataArr &detectData, jobject outDataObj) {
    jclass objClass = env->GetObjectClass(outDataObj);

    env->SetIntField(outDataObj, env->GetFieldID(objClass, "bodyCount", "I"), detectData.bodiesNum);


    jclass bodyClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_BodyFrameData");
    jobjectArray bodyArr = env->NewObjectArray(detectData.bodiesNum, bodyClass, NULL);
    for (int i = 0; i < detectData.bodiesNum; i++)
    {
        jobject body = env->AllocObject(bodyClass);
        env->SetIntField(body, env->GetFieldID(bodyClass, "bodyLandmarksNum", "I"), (int)(detectData.bodiesArr[i].bodyLandmarksNum));
        env->SetIntField(body, env->GetFieldID(bodyClass, "isWriggleWaist", "I"), (int)(detectData.bodiesArr[i].isWriggleWaist));
        env->SetIntField(body, env->GetFieldID(bodyClass, "isCrouch", "I"), (int)(detectData.bodiesArr[i].isCrouch));
        env->SetIntField(body, env->GetFieldID(bodyClass, "isRun", "I"), (int)(detectData.bodiesArr[i].isRun));
        env->SetIntField(body, env->GetFieldID(bodyClass, "bodyResultDesc", "I"), (int)(detectData.bodiesArr[i].bodyResultDesc));

        //get the floatArr in bodyClass
        jfieldID bodyPointsId = env->GetFieldID(bodyClass, "bodyPoints", "[F");
        jfieldID bodyPointsScoreId = env->GetFieldID(bodyClass, "bodyPointsScore", "[F");
        jfieldID bodyRectId = env->GetFieldID(bodyClass, "bodyRect", "[F");

        //set the bodyPointsArray and bodyPointsScoreArray in body class
        int pointsCount = detectData.bodiesArr[i].bodyLandmarksNum;
        jfloatArray bodyPointsJavaArr = env->NewFloatArray(2 * pointsCount);
        jfloatArray bodyPointsScoreJavaArr = env->NewFloatArray(pointsCount);
        jfloatArray bodyRectJavaArr = env->NewFloatArray(4);
        jfloat* bodyPointsJavaArrPtr = env->GetFloatArrayElements(bodyPointsJavaArr, NULL);
        jfloat* bodyPointsScoreJavaArrPtr = env->GetFloatArrayElements(bodyPointsScoreJavaArr, NULL);
        jfloat* bodyRectJavaArrPtr = env->GetFloatArrayElements(bodyRectJavaArr, NULL);

        for(int k = 0; k < pointsCount; k++)
        {
            bodyPointsJavaArrPtr[2 * k + 0] = detectData.bodiesArr[i].bodyLandmarks[k].x;
            bodyPointsJavaArrPtr[2 * k + 1 ] = detectData.bodiesArr[i].bodyLandmarks[k].y;
            bodyPointsScoreJavaArrPtr[k] = detectData.bodiesArr[i].bodyLandmarkScores[k];
        }
        bodyRectJavaArrPtr[0] = detectData.bodiesArr[i].bodyRect.x0;
        bodyRectJavaArrPtr[1] = detectData.bodiesArr[i].bodyRect.y0;
        bodyRectJavaArrPtr[2] = detectData.bodiesArr[i].bodyRect.x1;
        bodyRectJavaArrPtr[3] = detectData.bodiesArr[i].bodyRect.y1;

        env->SetObjectField(body, bodyPointsId, bodyPointsJavaArr);
        env->SetObjectField(body, bodyPointsScoreId, bodyPointsScoreJavaArr);
        env->SetObjectField(body, bodyRectId, bodyRectJavaArr);
        env->SetObjectArrayElement(bodyArr, i, body);

        env->ReleaseFloatArrayElements(bodyPointsJavaArr,bodyPointsJavaArrPtr, 0);
        env->ReleaseFloatArrayElements(bodyPointsScoreJavaArr,bodyPointsScoreJavaArrPtr, 0);
        env->ReleaseFloatArrayElements(bodyRectJavaArr,bodyRectJavaArrPtr, 0);

        env->DeleteLocalRef(bodyPointsJavaArr);
        env->DeleteLocalRef(bodyPointsScoreJavaArr);
        env->DeleteLocalRef(bodyRectJavaArr);
        env->DeleteLocalRef(body);
    }
    env->SetObjectField(outDataObj, env->GetFieldID(objClass, "bodyArr", "[Lcom/duowan/vnnlib/VNN$VNN_BodyFrameData;"), bodyArr);
    env->DeleteLocalRef(bodyClass);
    env->DeleteLocalRef(bodyArr);
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_applyPoseLandmarksCpu(JNIEnv* env, jclass thiz,
                                                                  jint vnnID,
                                                                  jobject  inputData,
                                                                  jobject outData) {
    if(inputData == NULL) {
        LOGE("Input data for ObjCount can not be null!!!");
        return -1;
    }
    VNN_Image img;
    jclass inputClass = env->GetObjectClass(inputData);
    //img.ori_fmt = (VNN_ORIENT_FMT)env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    jlong jori_fmt = env->GetLongField(inputData, env->GetFieldID(inputClass, "ori_fmt","J"));
    img.ori_fmt = (VNN_ORIENT_FMT) jori_fmt;
    img.pix_fmt = (VNN_PIX_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "pix_fmt","I"));
    img.mode_fmt = (VNN_MODE_FMT)env->GetIntField(inputData, env->GetFieldID(inputClass, "mode_fmt","I"));
    img.width = env->GetIntField(inputData, env->GetFieldID(inputClass, "width","I"));
    img.height = env->GetIntField(inputData, env->GetFieldID(inputClass, "height","I"));
    img.channels = env->GetIntField(inputData, env->GetFieldID(inputClass, "channels","I"));
    jbyteArray imgData = (jbyteArray) env->GetObjectField(inputData, env->GetFieldID(inputClass, "data", "[B"));
    jbyte* imgDataPtr = env->GetByteArrayElements(imgData, 0);
    img.data = (unsigned char*)imgDataPtr;

    VNN_BodyFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_GestureFrameDataArr));
    int result = VNN_Apply_Pose_CPU(vnnID, &img, &detectData);

    env->ReleaseByteArrayElements(imgData,imgDataPtr,0);
    env->DeleteLocalRef(inputClass);

    if(detectData.bodiesNum < 0 || result != 0)
        return -1;

    outPoseLandmarksToJava(env,detectData,outData);
    return result;
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_destroyPoseLandmarks(JNIEnv* env, jclass thiz, jint vnnID) {
    VNNHandle vID = (VNNHandle)vnnID;
    return VNN_Destroy_Pose(&vID);
}

void static getPoseLandmarksData(JNIEnv* env, jobject outData, VNN_BodyFrameDataArr &detectData) {
    jclass objClass = env->GetObjectClass(outData);
    jfieldID bodyC_id = env->GetFieldID(objClass, "bodyCount","I");
    int bodyCount = env->GetIntField(outData, bodyC_id);
    detectData.bodiesNum = (VNNUInt32)bodyCount;
    jclass frameDataClass = env->FindClass("com/duowan/vnnlib/VNN$VNN_BodyFrameData");
    jfieldID frameData_id = env->GetFieldID(objClass, "bodyArr","[Lcom/duowan/vnnlib/VNN$VNN_BodyFrameData;");
    jobjectArray frameDataArr = (jobjectArray)env->GetObjectField(outData, frameData_id);
    for(int i = 0; i < bodyCount; i++) {

        jobject frameData = env->GetObjectArrayElement(frameDataArr, i);
        detectData.bodiesArr[i].isWriggleWaist = env->GetIntField(frameData, env->GetFieldID(frameDataClass, "isWriggleWaist", "I"));
        detectData.bodiesArr[i].isCrouch = env->GetIntField(frameData, env->GetFieldID(frameDataClass, "isCrouch", "I"));
        detectData.bodiesArr[i].isRun = env->GetIntField(frameData, env->GetFieldID(frameDataClass, "isRun", "I"));
        detectData.bodiesArr[i].bodyResultDesc = (VNN_BodyResultDesc)env->GetIntField(frameData, env->GetFieldID(frameDataClass, "bodyResultDesc", "I"));

        jfieldID bodyPointsId = env->GetFieldID(frameDataClass, "bodyPoints", "[F");
        jfieldID bodyPointsScoreId = env->GetFieldID(frameDataClass, "bodyPointsScore", "[F");
        jfieldID bodyRectId = env->GetFieldID(frameDataClass, "bodyRect", "[F");


        jfloatArray bodyPointsArr = (jfloatArray) env->GetObjectField(frameData, bodyPointsId);
        jfloatArray bodyPointsScoreArr = (jfloatArray) env->GetObjectField(frameData, bodyPointsScoreId);
        jfloatArray bodyRectArr = (jfloatArray) env->GetObjectField(frameData, bodyRectId);

        jfloat* bodyPointsPtr = env->GetFloatArrayElements(bodyPointsArr, 0);
        jfloat* bodyPointsScorePtr = env->GetFloatArrayElements(bodyPointsScoreArr, 0);
        jfloat* bodyRectPtr = env->GetFloatArrayElements(bodyRectArr, 0);

        detectData.bodiesArr[i].bodyLandmarksNum = env->GetIntField(frameData, env->GetFieldID(frameDataClass, "bodyLandmarksNum", "I"));

        for(int k = 0; k < detectData.bodiesArr[i].bodyLandmarksNum; k++)
        {
            detectData.bodiesArr[i].bodyLandmarks[k].x = bodyPointsPtr[2 * k + 0];
            detectData.bodiesArr[i].bodyLandmarks[k].y = bodyPointsPtr[2 * k + 1];
//            LOGE("x, y = %f, %f", bodyPointsPtr[2 * k + 0], bodyPointsPtr[2 * k + 1]);
            detectData.bodiesArr[i].bodyLandmarkScores[k] = bodyPointsScorePtr[k];
        }
        detectData.bodiesArr[i].bodyRect.x0 = bodyRectPtr[0];
        detectData.bodiesArr[i].bodyRect.y0 = bodyRectPtr[1];
        detectData.bodiesArr[i].bodyRect.x1 = bodyRectPtr[2];
        detectData.bodiesArr[i].bodyRect.y1 = bodyRectPtr[3];

        detectData.bodiesArr[i].bodyScore = env->GetFloatField(frameData, env->GetFieldID(frameDataClass, "bodyScore", "F"));;

        env->ReleaseFloatArrayElements(bodyPointsArr, bodyPointsPtr, 0);
        env->ReleaseFloatArrayElements(bodyPointsScoreArr, bodyPointsScorePtr, 0);
        env->ReleaseFloatArrayElements(bodyRectArr, bodyRectPtr, 0);
    }
    env->DeleteLocalRef(frameDataArr);
    env->DeleteLocalRef(frameDataClass);
    env->DeleteLocalRef(objClass);
}


JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processPoseResultRotate(JNIEnv* env, jclass thiz, jint objID, jobject outData, jint rotate) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_BodyFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_BodyFrameDataArr));
    getPoseLandmarksData(env, outData, detectData);
    if(VNN_BodyFrameDataArr_Result_Rotate(&detectData, rotate) == 0) {
        outPoseLandmarksToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processPoseResultMirror(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_BodyFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_BodyFrameDataArr));
    getPoseLandmarksData(env, outData, detectData);
    if(VNN_BodyFrameDataArr_Result_Mirror(&detectData) == 0) {
        outPoseLandmarksToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

JNIEXPORT jint JNICALL Java_com_duowan_vnnlib_VNN_processPoseResultFlipV(JNIEnv* env, jclass thiz, jint objID, jobject outData) {
    VNNHandle oID = (VNNHandle)objID;
    VNN_BodyFrameDataArr detectData;
    memset(&detectData, 0x00, sizeof(VNN_BodyFrameDataArr));
    getPoseLandmarksData(env, outData, detectData);
    if(VNN_BodyFrameDataArr_Result_FlipV(&detectData) == 0) {
        outPoseLandmarksToJava(env, detectData, outData);
        return 0;
    }
    return -1;
}

}