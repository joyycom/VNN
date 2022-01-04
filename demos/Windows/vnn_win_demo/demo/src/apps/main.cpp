//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
#include <opencv2/opencv.hpp>
#include <opencv2/videoio/videoio.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include "cvui.h"
#include <windows.h>
#include "vnn_helper.h"
#define CAPTURE_WIDTH 1280
#define CAPTURE_HEIGHT 720
using namespace std;
using namespace cv;
static int mCameraId = 0;
VNN_EFFECT_MODE mEffectMode = VNN_EFFECT_COUNT;
static int window_height = 900;
static int window_width = 400;
cv::VideoCapture video_capture = nullptr;
bool mCameraOpened = false;
bool mUseCamera = false;
bool mUseImage = false;
string mImagePath;
bool mDestroyWindowFlag = false;
VNNHelper mVnnHelper;
std::string effect_name[] = {
    "VNN_FACE_KEYPOINTS",
    "VNN_FACE_MASK",
    "VNN_DISNEY_FACE",
    "VNN_3DGAME_FACE",
    "VNN_FACE_REENACT",
    "VNN_GESTURE",
    "VNN_OBJECT_TRACKING",
    "VNN_FACE_COUNT",
    "VNN_QR_CODE",
    "VNN_DOCUMENT_RECT",
    "VNN_PORTRAIT_SEG",
    "VNN_VIDEO_PORTRAIT_SEG",
    "VNN_SKY_SEG",
    "VNN_CLOTHES_SEG",
    "VNN_ANIMAL_SEG",
    "VNN_HAIR_SEG",
    "VNN_HEAD_SEG",
    "VNN_COMIC",
    "VNN_CARTOON",
    "VNN_OBJECT_CLASSIFICATION",
    "VNN_SCENE_WEATHER",
    "VNN_PERSON_ATTRIBUTE",
	"VNN_POSE_LANDMARKS"
};


string openfilename(char* filter = "All Files (*.*)\0*.*\0", HWND owner = NULL) {
    OPENFILENAME ofn;
    char fileName[MAX_PATH] = "";
    ZeroMemory(&ofn, sizeof(ofn));

    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = owner;
    ofn.lpstrFilter = filter;
    ofn.lpstrFile = fileName;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_NOCHANGEDIR;
    ofn.lpstrDefExt = "";

    string fileNameStr;

    if (GetOpenFileName(&ofn)) {
        fileNameStr = fileName;
    }
        

    return fileNameStr;
}
void UpdateKitWindow(cv::Mat& frame) {
    if (mEffectMode == VNN_EFFECT_COUNT) {
        int effect_count = VNN_EFFECT_COUNT;
        int btn_margin = 10;
        int btn_height_all = window_height - btn_margin * (effect_count + 1);
        int btn_height = btn_height_all / effect_count;
        int btn_width = window_width * 2 / 3;
        int btn_start_w = (window_width - btn_width) / 2;
        int btn_start_h = btn_margin;
        frame = cv::Scalar(49, 52, 49);
        for (int i = 0; i < effect_count; i++) {
            std::string btn_name = effect_name[i];
            if (cvui::button(frame, btn_start_w, btn_start_h + i * (btn_height + btn_margin), btn_width, btn_height, btn_name)) {
                mEffectMode = (VNN_EFFECT_MODE)i;
                mVnnHelper.createVNN(mEffectMode);
            }
        }
    }
    else {
        int effect_count = 4;
        int btn_margin = 50;
        int btn_height_all = window_height - btn_margin * (effect_count + 1);
        int btn_height = btn_height_all / effect_count;
        int btn_width = window_width * 2 / 3;
        int btn_start_w = (window_width - btn_width) / 2;
        int btn_start_h = btn_margin;
        frame = cv::Scalar(49, 52, 49);
        bool show_camera_btn = true;
        bool show_image_btn = true;
        if (mEffectMode == VNN_FACE_REENACT || 
            mEffectMode == VNN_DOCUMENT_RECT) {
            show_camera_btn = false;
        }
        if (mEffectMode == VNN_OBJECT_TRACKING ||
            mEffectMode == VNN_DOCUMENT_RECT) {
            show_image_btn = false;
        }
        if (show_camera_btn && mCameraOpened) {
            if (cvui::button(frame, btn_start_w, btn_start_h, btn_width, btn_height, "Camera")) {
                if (mUseImage) {
                    mUseImage = false;
                    mDestroyWindowFlag = true;
                }

                mUseCamera = true;

            }
        }
        if (show_image_btn) {
            if (cvui::button(frame, btn_start_w, btn_start_h + btn_height + btn_margin, btn_width, btn_height, "Image")) {
                if (mUseCamera) {
                    mUseCamera = false;
                    mDestroyWindowFlag = true;
                    if (mDestroyWindowFlag) {
                        cvDestroyWindow("Show");
                        cvDestroyWindow("Origin");
                        mDestroyWindowFlag = false;
                    }
                }
                mImagePath = openfilename();
                mUseImage = true;
            }
        }
        
        if (cvui::button(frame, btn_start_w, btn_start_h + 2 * (btn_height + btn_margin), btn_width, btn_height, "Return")) {
            mVnnHelper.destroyVNN(mEffectMode);
            mEffectMode = VNN_EFFECT_COUNT;
            if (mUseCamera || mUseImage) {
                mDestroyWindowFlag = true;
                
            }
            cvDestroyWindow("Show");
            cvDestroyWindow("Origin");
            mUseCamera = false;
            mUseImage = false;
        }
        cvui::printf(frame, btn_start_w, btn_start_h + 3 * (btn_height + btn_margin), 0.5, 0xffffff, "Press Esc to exit procedure");
    
    }
    
    cvui::update();
}
int main(int argc, char* argv[]) {

    // init window
    cv::Mat kit_frame = cv::Mat(cv::Size(window_width, window_height), 0);
    const char* KIT_WINODW_NAME = "vnn_window";
    cv::namedWindow(KIT_WINODW_NAME, 1);
    cvui::init(KIT_WINODW_NAME);

    // open camera
    cout << "init camera ....." << endl;
    video_capture = cv::VideoCapture(mCameraId);
    bool width_flag = video_capture.set(CV_CAP_PROP_FRAME_WIDTH, CAPTURE_WIDTH);
    bool height_flag = video_capture.set(CV_CAP_PROP_FRAME_HEIGHT, CAPTURE_HEIGHT);
    if (!width_flag || !height_flag) {
        printf("Don't support this resolution, %d * %d.", CAPTURE_WIDTH, CAPTURE_HEIGHT);
        mUseCamera = false;
    }
    if (!video_capture.isOpened()) {
        cout << "Failed open the camera." << endl;
        mCameraOpened = false;
        mUseCamera = false;
    }
    else {
        mCameraOpened = true;
        cout << "camera has been opened!" << endl;
    }
    

    // loop 
    cv::Mat captured_image;
    cv::Mat mirror_image;
    bool loop_flag = true;
    while (loop_flag) {
        UpdateKitWindow(kit_frame);
        cv::imshow(KIT_WINODW_NAME, kit_frame);
        if (cv::waitKey(20) == 27) {
            if (mEffectMode != VNN_EFFECT_COUNT) {
                mVnnHelper.destroyVNN(mEffectMode);
            }
            break;
        }
        
        
        if (mUseCamera) {
            video_capture >> captured_image;
            flip(captured_image, mirror_image, 1);
            mVnnHelper.applyVNN(mEffectMode, mirror_image, 0);
        }
        if (mUseImage) {
            if (mImagePath != "") {
                cout << mImagePath << endl;
                captured_image = imread(mImagePath, CV_LOAD_IMAGE_COLOR);
                mVnnHelper.applyVNN(mEffectMode, captured_image, 1);
                //imshow("Show", captured_image);
            }
            mUseImage = false;
            
        }
        
    }
	return 0;
}