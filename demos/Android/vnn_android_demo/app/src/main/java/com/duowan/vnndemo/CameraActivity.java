//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.PorterDuff;
import android.hardware.SensorManager;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.util.Size;
import android.view.MotionEvent;
import android.view.OrientationEventListener;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.duowan.vnndemo.glutils.GLRender;
import com.duowan.vnndemo.glutils.OpenGLUtils;
import com.duowan.vnnlib.VNN;
import com.google.common.util.concurrent.ListenableFuture;

import java.nio.ByteBuffer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class CameraActivity extends AppCompatActivity implements View.OnTouchListener, GLSurfaceView.Renderer {
    private final static String TAG = "CameraActivity";
    private Context mContext;
    GLSurfaceView mGlSurfaceView;
    private SurfaceView mSurfaceView;
    public PreviewView mViewFinder;
    private Preview preview;
    ImageAnalysis imageAnalysis;
    private ExecutorService executor;
    androidx.camera.core.Camera camera;
    ProcessCameraProvider cameraProvider;
    private int mEffectMode;
    private int mPreviewWidth = 720;
    private int mPreviewHeight = 1280;
    private int[] yTexture;
    private int[] uTexture;
    private int[] vTexture;
    private int[] mSegmentTexture;
    private int[] mDisneyTexture;
    private int[] m3dGameTexture;
    private int replaceTexture;
    private Bitmap replaceImage;
    private int mCameraID = CameraSelector.LENS_FACING_FRONT;
    private int mCameraOrientation = 270;
    private boolean mMirrorFlag = true;
    private OrientationEventListener mOrientationListener;
    private int mScreenOrientation = 0;
    private VNNHelper vnnHelper;
    private int mDisplayWidth = 0;
    private int mDisplayHeight = 0;
    private boolean mPauseFlag = false;

    private GLRender mGLRender;
    private byte[] mCameraData = null;
    private byte[] mUseData = null;

    private boolean mGetBox = false;
    private boolean mReadyTrack = false;
    private float[] mObjBox;
    private float preX = -1;
    private float preY = -1;
    private float curX = -1;
    private float curY = -1;
    private Paint mPaint;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "onCreate");
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_camera);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            final WindowInsetsController insetsController = getWindow().getInsetsController();
            if (insetsController != null) {
                insetsController.hide(WindowInsets.Type.statusBars());
            }
        } else {
            getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN
            );
        }
        mContext = this;
        mViewFinder = findViewById(R.id.viewFinder);
        mGlSurfaceView = (GLSurfaceView) findViewById(R.id.id_gl_sv);
        mSurfaceView = (SurfaceView) findViewById(R.id.surfaceView);
        mGlSurfaceView.setEGLContextClientVersion(2);
        mGlSurfaceView.setRenderer(this);
        mGlSurfaceView.setRenderMode(GLSurfaceView.RENDERMODE_WHEN_DIRTY);

        mSurfaceView.setZOrderMediaOverlay(true);
        mSurfaceView.getHolder().setFormat(PixelFormat.TRANSLUCENT);
        Intent intent = getIntent();
        mEffectMode = intent.getIntExtra("vnnModeID", 0);

        mViewFinder.setPreferredImplementationMode(PreviewView.ImplementationMode.TEXTURE_VIEW);
        executor = Executors.newSingleThreadExecutor();

        mOrientationListener = new OrientationEventListener(mContext,
                SensorManager.SENSOR_DELAY_NORMAL) {

            @Override
            public void onOrientationChanged(int orientation) {
                if (orientation == OrientationEventListener.ORIENTATION_UNKNOWN) {
                    return;
                }
                //只检测是否有四个角度的改变
                if (orientation > 340 || orientation < 20) { //0度
                    mScreenOrientation = 0;
                } else if (orientation > 70 && orientation < 110) { //90度
                    mScreenOrientation = 90;
                } else if (orientation > 160 && orientation < 200) { //180度
                    mScreenOrientation = 180;
                } else if (orientation > 250 && orientation < 290) { //270度
                    mScreenOrientation = 270;
                } else {
                    return;
                }
                Log.i(TAG,"Orientation changed to " + mScreenOrientation);
            }
        };


        findViewById(R.id.iv_change_camera).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                switchCamera();
            }
        });
        vnnHelper = new VNNHelper(mContext);
        mPaint = new Paint();
        mObjBox = new float[4];
        if(mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_OBJECT_TRACKING) {
            findViewById(R.id.id_preview_layout).setOnTouchListener(this);
            Toast toast = Toast.makeText(mContext, "触屏滑动，选择目标", Toast.LENGTH_LONG);
            toast.show();
        }
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {

        // TODO Auto-generated method stub
        float x = event.getX(); // getX是获取相对当前控件的坐标
        float y = event.getY(); // getRawX是获取相对屏幕左上角的坐标
        //Log.e(TAG, "onTouch: action type " + event.getAction() + ", x = " + x + ", y = " + y);
        switch (event.getAction()) {
            // ACTION_DOWN 按下
            // ACTION_MOVE 在屏幕上移动
            // ACTION_UP   离开屏幕
            case MotionEvent.ACTION_DOWN:
                mGetBox = false;
                mReadyTrack = false;
                preX = x;
                preY = y;
                break;
            case MotionEvent.ACTION_MOVE:
                curX = x;
                curY = y;
                int strokeWidth = mDisplayWidth / 200;
                strokeWidth = strokeWidth > 0 ? strokeWidth : 1;
                mPaint.setStrokeWidth(strokeWidth);
                mPaint.setColor(Color.parseColor("#0a8dff"));
                mPaint.setStyle(Paint.Style.STROKE);
                Canvas canvas = mSurfaceView.getHolder().lockCanvas();
                //canvas.drawColor(0, PorterDuff.Mode.CLEAR);
                canvas.drawRect(preX, preY, curX, curY, mPaint);
                mSurfaceView.getHolder().unlockCanvasAndPost(canvas);
                break;
            case MotionEvent.ACTION_UP:
                mObjBox[0] = preX / mDisplayWidth;
                mObjBox[1] = preY / mDisplayHeight;
                mObjBox[2] = curX / mDisplayWidth;
                mObjBox[3] = curY / mDisplayHeight;
                if(Math.abs(mObjBox[2] - mObjBox[0]) > 0.02 && Math.abs(mObjBox[3] - mObjBox[1]) > 0.02) {
                    mGetBox = true;
                }
                else {
                    mGetBox = false;
                }
                break;
        }
        return true;
    }
    @Override
    public synchronized void onSurfaceCreated(GL10 gl, EGLConfig config) {
        Log.i(TAG, "onSurfaceCreated");
        GLES20.glEnable(GL10.GL_DITHER);
        GLES20.glClearColor(0, 0, 0, 0);
        GLES20.glEnable(GL10.GL_DEPTH_TEST);
        vnnHelper.createModels(mEffectMode);
        startCamera();
        //replaceImage = BitmapFactory.decodeResource(mContext.getResources(), R.drawable.starry_sky);
//        replaceTexture = OpenGLUtils.createTextureFromBitmap(GLES20.GL_TEXTURE_2D, replaceImage, GLES20.GL_LINEAR, GLES20.GL_LINEAR,
//                GLES20.GL_CLAMP_TO_EDGE, GLES20.GL_CLAMP_TO_EDGE);

        if (mOrientationListener.canDetectOrientation()) {
            Log.v(TAG, "Can detect orientation");
            mOrientationListener.enable();
        }
        else {
            Log.v(TAG, "Cannot detect orientation");
            mOrientationListener.disable();
        }
    }
    @Override
    public synchronized void onSurfaceChanged(GL10 gl, int width, int height) {
        Log.i(TAG, "onSurfaceChanged");
        mDisplayWidth = width;
        mDisplayHeight = height;

        GLES20.glViewport(0, 0, mDisplayWidth, mDisplayHeight);
        mGLRender.setViewPortWH(mPreviewWidth, mPreviewHeight);
        mGLRender.setTextureCoordBuffer(mCameraOrientation, mMirrorFlag);
        Log.e(TAG, "onSurfaceChanged: mDisplayWidth, mDisplayHeight = " + mDisplayWidth + ", " + mDisplayHeight);

    }
    @Override
    public synchronized void onDrawFrame(GL10 gl) {

        if(mPauseFlag) {
            return;
        }

        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);

        if (yTexture == null) {
            yTexture = new int[1];
            OpenGLUtils.createLuminanceTexture(mPreviewHeight, mPreviewWidth, yTexture,
                    GLES20.GL_TEXTURE_2D);
        }
        if (uTexture == null) {
            uTexture = new int[1];
            OpenGLUtils.createLuminanceAlphaTexture(mPreviewHeight / 2, mPreviewWidth / 2, uTexture,
                    GLES20.GL_TEXTURE_2D);
        }
        if (vTexture == null) {
            vTexture = new int[1];
            OpenGLUtils.createLuminanceAlphaTexture(mPreviewHeight / 2, mPreviewWidth / 2, vTexture,
                    GLES20.GL_TEXTURE_2D);
        }
        int textureId = -1;
        if(mCameraData != null) {
            int pixelNum = mPreviewHeight * mPreviewWidth;
            int pixelNumUV = pixelNum / 2;
            byte[] ydata = new byte[pixelNum];
            System.arraycopy(mCameraData, 0, ydata, 0, pixelNum);
            ByteBuffer yImgBuffer = ByteBuffer.wrap(ydata);
            byte[] udata = new byte[pixelNum];
            System.arraycopy(mCameraData, pixelNum, udata, 0, pixelNumUV);
            ByteBuffer uImgBuffer = ByteBuffer.wrap(udata);
            byte[] vdata = new byte[pixelNum];
            System.arraycopy(mCameraData, pixelNum + pixelNumUV, vdata, 0, pixelNumUV);
            ByteBuffer vImgBuffer = ByteBuffer.wrap(vdata);
            textureId = mGLRender.drawYUVImgeToTexture(yTexture[0], uTexture[0], vTexture[0], mPreviewHeight,
                    mPreviewWidth, yImgBuffer, uImgBuffer, vImgBuffer);
            applyVNN();
            if (mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_FACE_MASK ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_PORTRAIT_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_VIDEO_PORTRAIT_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_SKY_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_CLOTHES_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_ANIMAL_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_HAIR_SEG ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_HEAD_SEG) {
                for(int i = 0; i < vnnHelper.imageArr.imgsNum; i++) {
                    if (mSegmentTexture == null) {
                        mSegmentTexture = new int[1];
                        OpenGLUtils.createLuminanceTexture(vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height, mSegmentTexture, GLES20.GL_TEXTURE_2D);
                    }
                    ByteBuffer maskBuffer = ByteBuffer.wrap(vnnHelper.imageArr.imgsArr[i].data);

                    if (i == 0) {
                        textureId = mGLRender.drawMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height,
                                maskBuffer, vnnHelper.imageArr.imgsArr[i].rect, true);
                    }
                    else {
                        textureId = mGLRender.drawMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height,
                                maskBuffer, vnnHelper.imageArr.imgsArr[i].rect, false);
                    }

                }
            }
            if(mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_DISNEY_FACE) {
                //Log.e(TAG, "onDrawFrame: disney");
                int midTextureId = -1;
                for(int i = 0; i < vnnHelper.imageArr.imgsNum; i++) {
                    if (mSegmentTexture == null) {
                        mSegmentTexture = new int[1];
                        OpenGLUtils.createLuminanceTexture(vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height, mSegmentTexture, GLES20.GL_TEXTURE_2D);
                    }
                    if (mDisneyTexture == null) {
                        mDisneyTexture = new int[1];
                        OpenGLUtils.createRGBTexture(vnnHelper.disneyDataArr.imgsArr[i].width, vnnHelper.disneyDataArr.imgsArr[i].height, mDisneyTexture, GLES20.GL_TEXTURE_2D);
                    }
                    ByteBuffer maskBuffer = ByteBuffer.wrap(vnnHelper.imageArr.imgsArr[i].data);
                    ByteBuffer disneyBuffer = ByteBuffer.wrap(vnnHelper.disneyDataArr.imgsArr[i].data);
                    if (i == 0) {
                        midTextureId = mGLRender.drawImageAndMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.imageArr.imgsArr[i].width,
                                vnnHelper.imageArr.imgsArr[i].height,
                                maskBuffer,
                                mDisneyTexture[0],
                                vnnHelper.disneyDataArr.imgsArr[i].width,
                                vnnHelper.disneyDataArr.imgsArr[i].height,
                                disneyBuffer,
                                vnnHelper.imageArr.imgsArr[i].rect,
                                true);
                    }
                    else {
                        midTextureId = mGLRender.drawImageAndMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.imageArr.imgsArr[i].width,
                                vnnHelper.imageArr.imgsArr[i].height,
                                maskBuffer,
                                mDisneyTexture[0],
                                vnnHelper.disneyDataArr.imgsArr[i].width,
                                vnnHelper.disneyDataArr.imgsArr[i].height,
                                disneyBuffer,
                                vnnHelper.imageArr.imgsArr[i].rect,
                                false);
                    }


                    textureId = mGLRender.drawBlendMaskImageTexture(textureId, midTextureId);
                }
            }
            if(mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_3DGAME_FACE) {
                int midTextureId = -1;
                for (int i = 0; i < vnnHelper.game3dDataArr.imgsNum; i++) {
                    if (mSegmentTexture == null) {
                        mSegmentTexture = new int[1];
                        OpenGLUtils.createLuminanceTexture(vnnHelper.game3dMaskDataArr.imgsArr[i].width, vnnHelper.game3dMaskDataArr.imgsArr[i].height, mSegmentTexture, GLES20.GL_TEXTURE_2D);
                    }
                    if (m3dGameTexture == null) {
                        m3dGameTexture = new int[1];
                        OpenGLUtils.createRGBTexture(vnnHelper.game3dDataArr.imgsArr[i].width, vnnHelper.game3dDataArr.imgsArr[i].height, m3dGameTexture, GLES20.GL_TEXTURE_2D);
                    }
                    ByteBuffer maskBuffer = ByteBuffer.wrap(vnnHelper.game3dMaskDataArr.imgsArr[i].data);
                    ByteBuffer gameBuffer = ByteBuffer.wrap(vnnHelper.game3dDataArr.imgsArr[i].data);
                    if (i == 0) {
                        midTextureId = mGLRender.drawImageAndMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.game3dMaskDataArr.imgsArr[i].width,
                                vnnHelper.game3dMaskDataArr.imgsArr[i].height,
                                maskBuffer,
                                m3dGameTexture[0],
                                vnnHelper.game3dDataArr.imgsArr[i].width,
                                vnnHelper.game3dDataArr.imgsArr[i].height,
                                gameBuffer,
                                vnnHelper.game3dMaskDataArr.imgsArr[i].rect,
                                true);
                    }
                    else {
                        midTextureId = mGLRender.drawImageAndMaskRectToTexture(mSegmentTexture[0],
                                vnnHelper.game3dMaskDataArr.imgsArr[i].width,
                                vnnHelper.game3dMaskDataArr.imgsArr[i].height,
                                maskBuffer,
                                m3dGameTexture[0],
                                vnnHelper.game3dDataArr.imgsArr[i].width,
                                vnnHelper.game3dDataArr.imgsArr[i].height,
                                gameBuffer,
                                vnnHelper.game3dMaskDataArr.imgsArr[i].rect,
                                false);
                    }


                    textureId = mGLRender.drawBlendMaskImageTexture(textureId, midTextureId);
                }
            }
            if (mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_COMIC ||
                    mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_CARTOON) {
                Log.e(TAG, "onDrawFrame: mEffectMode = " + mEffectMode);
                for(int i = 0; i < vnnHelper.imageArr.imgsNum; i++) {
                    if (mSegmentTexture == null) {
                        mSegmentTexture = new int[1];
                        OpenGLUtils.createRGBTexture(vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height, mSegmentTexture, GLES20.GL_TEXTURE_2D);
                    }
                    ByteBuffer maskBuffer = ByteBuffer.wrap(vnnHelper.imageArr.imgsArr[i].data);

                    textureId = mGLRender.drawRGBImageToTexture(mSegmentTexture[0],
                            vnnHelper.imageArr.imgsArr[i].width, vnnHelper.imageArr.imgsArr[i].height,
                            maskBuffer);
                }
            }
        }
        GLES20.glViewport(0, 0, mDisplayWidth, mDisplayHeight);
        mGLRender.onDraw(textureId);
        //mGLRender.onDraw(replaceTexture);
    }
    public void applyVNN() {
        if(mPauseFlag) {
            return;
        }
        if(mUseData == null) {
            mUseData = new byte[mCameraData.length];
        }
        synchronized (mCameraData) {
            System.arraycopy(mCameraData, 0, mUseData, 0, mCameraData.length);
        }
        long oriFmt = vnnHelper.getImageOrientationFmt(mMirrorFlag, mCameraOrientation, mScreenOrientation);
        VNN.VNN_Image inputImage = new VNN.VNN_Image();
        inputImage.width = mPreviewHeight;
        inputImage.height = mPreviewWidth;
        inputImage.data = mUseData;
        inputImage.ori_fmt = oriFmt;
        inputImage.pix_fmt = VNN.VNN_PixelFormat.VNN_PIX_FMT_YUV420P_888_SKIP1;
        inputImage.mode_fmt = VNN.VNN_MODE_FMT.VNN_MODE_FMT_VIDEO;

        Canvas canvas = mSurfaceView.getHolder().lockCanvas();
        if (!mSurfaceView.getHolder().getSurface().isValid()) {
            return;
        }
        else {
            canvas.drawColor(0, PorterDuff.Mode.CLEAR);
        }
        if(mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_OBJECT_TRACKING) {
            if(mGetBox) {
                mGetBox = false;
                mReadyTrack = true;
                boolean clearFlag = true;
                if(vnnHelper.mVnnID != -1) {
                    VNN.setClearImageObjectTracking(vnnHelper.mVnnID);
                    VNN.setImageObjectTracking(vnnHelper.mVnnID, "_targetImage", inputImage);
                    VNN.setRectObjectTracking(vnnHelper.mVnnID, "_objRect", mObjBox);
                }
            }
            else if(mReadyTrack) {
                vnnHelper.apply(mEffectMode, inputImage, canvas);
            }
        }
        else {
            vnnHelper.apply(mEffectMode, inputImage, canvas);
        }
        if (!mSurfaceView.getHolder().getSurface().isValid()) {
            return;
        }
        mSurfaceView.getHolder().unlockCanvasAndPost(canvas);
    }
    private void cleanCanvas() {
        if (!mSurfaceView.getHolder().getSurface().isValid()) {
            return;
        }
        Canvas canvas = mSurfaceView.getHolder().lockCanvas();
        if (canvas == null) {
            return;
        }

        canvas.drawColor(0, PorterDuff.Mode.CLEAR);
        mSurfaceView.getHolder().unlockCanvasAndPost(canvas);
    }
    public void startCamera() {
        Log.i(TAG, "startCamera: start");
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture = ProcessCameraProvider.getInstance(mContext);
        cameraProviderFuture.addListener(new Runnable() {
            @Override
            public void run() {
                try {
                    //1 图像预览接口
                    preview= new Preview.Builder().build();

                    //2 图像分析接口
                    imageAnalysis = new ImageAnalysis.Builder()
                            .setTargetResolution(new Size(mPreviewWidth, mPreviewHeight)) // can not work for unknown reasons, maybe camerax version is not suitable
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build();
                    imageAnalysis.setAnalyzer(executor,
                            new LuminosityAnalyzer());

                    CameraSelector cameraSelector = new CameraSelector.Builder().requireLensFacing(mCameraID).build();
                    cameraProvider = cameraProviderFuture.get();


                    cameraProvider.unbindAll();
                    camera = cameraProvider.bindToLifecycle((LifecycleOwner)mContext, cameraSelector, preview, imageAnalysis);

                    //preview.setSurfaceProvider(mViewFinder.getSurfaceProvider());
                    preview.setSurfaceProvider(mViewFinder.createSurfaceProvider(camera.getCameraInfo()));


                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }, ContextCompat.getMainExecutor(mContext));
    }
    private class LuminosityAnalyzer  implements ImageAnalysis.Analyzer{

        @Override
        public void analyze(@NonNull ImageProxy image) {
            ByteBuffer bufferY = image.getPlanes()[0].getBuffer();
            ByteBuffer bufferU = image.getPlanes()[1].getBuffer();
            ByteBuffer bufferV = image.getPlanes()[2].getBuffer();
            int ySize = bufferY.remaining();
            int uSize = bufferU.remaining();
            int vSize = bufferV.remaining();
            if(mPreviewWidth != image.getHeight() || mPreviewHeight != image.getWidth()) {
                Log.e(TAG, "analyze: resolution (" + mPreviewWidth + ", " + mPreviewHeight + ") is not supported by camerax");
                mPreviewHeight = image.getWidth();
                mPreviewWidth = image.getHeight();
            }

            int dataLen = ySize + uSize + 1 + vSize + 1;
			if(ySize == uSize * 4) {
                dataLen = ySize * 2;
            }
            if(mCameraData == null || mCameraData.length != dataLen) {
                mCameraData =new byte[dataLen];
            }
            synchronized (mCameraData) {
                if(ySize == uSize * 4) {
                    // for this case, Image format is YUVI420, which is not supported in VNN on android platform.
                    // So, here YUVI420 is converted into VNN_PIX_FMT_YUV420P_888_SKIP1
                    bufferY.get(mCameraData, 0, ySize);
                    byte[] midU = new byte[uSize];
                    byte[] midV = new byte[vSize];
                    bufferU.get(midU, 0, uSize);
                    bufferV.get(midV, 0, vSize);
                    for(int i = 0; i < uSize; i++) {
                        int offsetU = ySize + i * 2;
                        int offsetV = ySize + ySize / 2 + i * 2;
                        mCameraData[offsetU] = midU[i];
                        mCameraData[offsetV] = midV[i];
                    }
                }
                else {
                    bufferY.get(mCameraData, 0, ySize);
                    bufferU.get(mCameraData, ySize, uSize);
                    bufferV.get(mCameraData, ySize + uSize + 1, vSize);
                }
            }
            int rotationDegrees = image.getImageInfo().getRotationDegrees();
            if(rotationDegrees != mCameraOrientation) {
                mCameraOrientation = rotationDegrees;
                mGLRender.setTextureCoordBuffer(mCameraOrientation, mMirrorFlag);
            }
            mGlSurfaceView.requestRender();
            image.close();
        }
    }


    @Override
    protected void onResume() {
        Log.i(TAG, "onResume");
        super.onResume();
        mPauseFlag = false;
        mGLRender = new GLRender();
        mGlSurfaceView.onResume();
        mGlSurfaceView.forceLayout();
    }

    @Override
    protected void onPause() {
        Log.i(TAG, "onPause");
        super.onPause();
        mPauseFlag = true;
        mGlSurfaceView.queueEvent(new Runnable() {
            @Override
            public void run() {


                deleteTextures();
                mGLRender.destroyGLRender();
            }
        });
        //replaceImage.recycle();
        cameraProvider.unbindAll();
        mGlSurfaceView.onPause();
        mOrientationListener.disable();

    }
    protected void deleteTextures() {
        if (yTexture != null) {
            GLES20.glDeleteTextures(1, yTexture, 0);
        }
        yTexture = null;

        if (uTexture != null) {
            GLES20.glDeleteTextures(1, uTexture, 0);
        }
        uTexture = null;

        if (vTexture != null) {
            GLES20.glDeleteTextures(1, vTexture, 0);
        }
        vTexture = null;
        if (mSegmentTexture != null) {
            GLES20.glDeleteTextures(1, mSegmentTexture, 0);
        }
        mSegmentTexture = null;

        if (mDisneyTexture != null) {
            GLES20.glDeleteTextures(1, mDisneyTexture, 0);
        }
        mDisneyTexture = null;

        if (m3dGameTexture != null) {
            GLES20.glDeleteTextures(1, m3dGameTexture, 0);
        }
        m3dGameTexture = null;
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        mCameraData = null;
        vnnHelper.destroyVNN(mEffectMode);
    }
    public void switchCamera() {
        cleanCanvas();
        cameraProvider.unbindAll();
        mCameraID = 1 - mCameraID;
        startCamera();
        if(mCameraID == CameraSelector.LENS_FACING_FRONT) {
            mMirrorFlag = true;
        }
        else {
            mMirrorFlag = false;
        }
    }
}
