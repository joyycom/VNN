//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.ImageView;

import androidx.annotation.ColorInt;

import com.duowan.vnnlib.VNN;

public class ImageActivity  extends Activity {
    private final static String TAG = "ImageActivity";
    private ImageView mImageView;
    private int mEffectMode = 0;
    private Context mContext;
    private Button mSelectBtn;
    private final int requestPickImage = 2000;
    private Bitmap mBitmap;
    private int mImageWidth, mImageHeight;
    private byte[] mImageData = null;
    private VNNHelper vnnHelper;
    private Thread mThread;
    private boolean mCycleLabel;
    private boolean finishFlag;
    private int allTime = 0;
    private Paint mPaint = new Paint();
    private static final int MESSAGE_SHOW_IMAGE = 100;
    private static final int MESSAGE_SHOW_END = 99;
    private Handler mProcessHandler;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_image);
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
        mImageView = (ImageView) findViewById(R.id.iv_image);
        mContext = this;
        Intent intent = getIntent();
        final int transferData = intent.getIntExtra("vnnModeID", 0);
        mEffectMode = transferData;
        vnnHelper = new VNNHelper(mContext);
        vnnHelper.createModels(mEffectMode);
        mProcessHandler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch (msg.what) {
                    case MESSAGE_SHOW_IMAGE:
                        mImageView.setImageBitmap(mBitmap);
                        break;
                    case MESSAGE_SHOW_END:

                        break;
                    default:
                        break;
                }
            }
        };
        initEvents();

    }
    private void initEvents() {
        Intent imagePickerIntent = new Intent(Intent.ACTION_PICK);
        imagePickerIntent.setType("image/*");
        startActivityForResult(imagePickerIntent, requestPickImage);

        mSelectBtn = (Button) findViewById(R.id.id_img_select_button);
        mSelectBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mCycleLabel = false;
                Intent photoPickerIntent = new Intent(Intent.ACTION_PICK);
                photoPickerIntent.setType("image/*");
                startActivityForResult(photoPickerIntent, requestPickImage);
            }
        });
    }

    protected void onDestroy() {
        super.onDestroy();
        mCycleLabel = false;
        vnnHelper.destroyVNN(mEffectMode);
    }
    @Override
    protected void onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        switch (requestCode) {
            case requestPickImage:
                if (resultCode == RESULT_OK) {
                    try {
                        Uri uri = data.getData();
                        String imgPath = getFilePathByUri(mContext, uri);
                        Bitmap bitmap = BitmapFactory.decodeFile(imgPath);
                        if (bitmap != null) {
                            mBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true);
                            mImageView.setImageBitmap(mBitmap);
                            mImageWidth = mBitmap.getWidth();
                            mImageHeight = mBitmap.getHeight();
                            mImageData = getRGBAFromBitmap(mBitmap);
                            VNN.VNN_Image inputImage = new VNN.VNN_Image();
                            inputImage.width = mImageWidth;
                            inputImage.height = mImageHeight;
                            inputImage.data = mImageData;
                            inputImage.ori_fmt = VNN.VNN_OrientationFormat.VNN_ORIENT_FMT_DEFAULT;
                            inputImage.pix_fmt = VNN.VNN_PixelFormat.VNN_PIX_FMT_RGBA8888;
                            inputImage.mode_fmt = VNN.VNN_MODE_FMT.VNN_MODE_FMT_PICTURE;
                            if(mEffectMode == VNNHelper.VNN_EFFECT_MODE.VNN_FACE_REENACT) {
                                faceReenactmentProcess(inputImage);
                            }
                            else {
                                Canvas canvas = new Canvas(mBitmap);
                                vnnHelper.getBackgroundImage(mBitmap);
                                vnnHelper.apply(mEffectMode, inputImage, canvas);
                                mImageView.setImageBitmap(mBitmap);
                            }

                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }

                } else {
                    finish();
                }
                break;
            default:
                super.onActivityResult(requestCode, resultCode, data);
                break;
        }
    }
    public String getFilePathByUri(Context context, Uri uri) {
        String path = null;
        if (ContentResolver.SCHEME_FILE.equals(uri.getScheme())) {
            path = uri.getPath();
            return path;
        }
        if (ContentResolver.SCHEME_CONTENT.equals(uri.getScheme())) {
            Cursor cursor = context.getContentResolver()
                    .query(uri, new String[]{MediaStore.Images.Media.DATA}, null, null, null);
            if (cursor != null) {
                if (cursor.moveToFirst()) {
                    int columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                    if (columnIndex > -1) {
                        path = cursor.getString(columnIndex);
                    }
                }
                cursor.close();
            }
            return path;
        }
        return null;
    }
    public static byte[] getRGBAFromBitmap(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int componentsPerPixel = 4;
        int totalPixels = width * height;
        int totalBytes = totalPixels * componentsPerPixel;

        byte[] rgbValues = new byte[totalBytes];
        @ColorInt int[] argbPixels = new int[totalPixels];
        bitmap.getPixels(argbPixels, 0, width, 0, 0, width, height);
        for (int i = 0; i < totalPixels; i++) {
            @ColorInt int argbPixel = argbPixels[i];
            int red = Color.red(argbPixel);
            int green = Color.green(argbPixel);
            int blue = Color.blue(argbPixel);
            int alpha = Color.alpha(argbPixel);
            rgbValues[i * componentsPerPixel + 0] = (byte) red;
            rgbValues[i * componentsPerPixel + 1] = (byte) green;
            rgbValues[i * componentsPerPixel + 2] = (byte) blue;
            rgbValues[i * componentsPerPixel + 3] = (byte) alpha;
        }

        return rgbValues;
    }
    public void faceReenactmentProcess(VNN.VNN_Image inputImage){
        vnnHelper.faceDetectionFrameData.facesNum = 0;
        VNN.setFacePoints(vnnHelper.mVnnID, 278);
        VNN.applyFaceCpu(vnnHelper.mVnnID, inputImage, vnnHelper.faceDetectionFrameData);
        VNN.VNN_FaceFrameDataArr faceDetectionRect = new VNN.VNN_FaceFrameDataArr();
        faceDetectionRect.facesNum = 0;
        VNN.getFaceDetectionRect(vnnHelper.mVnnID, faceDetectionRect);
        String sdcard = getExternalFilesDir(null).getAbsolutePath() + "/vnn_models";
        String jsonPath = sdcard + "/vnn_face_reenactment_data/driving.kps.json";
        if(faceDetectionRect.facesNum != 0) {
            VNN.setStringFaceReenactment(vnnHelper.mVnnReenactID, "_kpJsonsPath", jsonPath);
            VNN.setRectFaceReenactment(vnnHelper.mVnnReenactID, "_faceRect",faceDetectionRect.facesArr[0].faceRect);
            VNN.setImageFaceReenactment(vnnHelper.mVnnReenactID, "_targetImage", inputImage);
            int frameCount = VNN.getIntFaceReenactment(vnnHelper.mVnnReenactID, "_frameCount");

            VNN.VNN_Image faceImg = new VNN.VNN_Image();
            faceImg.width = vnnHelper.mOutImgWidth;
            faceImg.height = vnnHelper.mOutImgHeight;
            faceImg.channels = 3;
            faceImg.data = new byte[vnnHelper.mOutImgWidth * vnnHelper.mOutImgHeight * faceImg.channels];


            Bitmap[] bitmapArray = new Bitmap[frameCount];
            finishFlag = false;
            allTime = 0;
            new Thread() {
                @Override
                public void run() {
                    for(int i = 1; i <= frameCount; i++ ) {
                        long t0 = System.currentTimeMillis();
                        VNN.applyFaceReenactmentCpu(vnnHelper.mVnnReenactID, i, faceImg);
                        long t1 = System.currentTimeMillis();
                        allTime += (t1 - t0);
                        byte[] faceData = faceImg.data;
                        if (faceData != null) {
                            mBitmap = vnnHelper.getBitmapImgFromRGB(faceData, vnnHelper.mOutImgWidth, vnnHelper.mOutImgHeight);
                            bitmapArray[i - 1] = mBitmap;
                            mBitmap = showProgressOnImage(mBitmap, i, frameCount);
                        } else {
                            Log.e(TAG, "faceReenactmentProcess: void ptr of segMask");
                        }
                        mProcessHandler.removeMessages(MESSAGE_SHOW_IMAGE);
                        mProcessHandler.sendEmptyMessage(MESSAGE_SHOW_IMAGE);
                    }
                    finishFlag = true;
                }
            }.start();

            mCycleLabel = true;
            mThread = new Thread() {
                @Override
                public void run() {
                    while (finishFlag == false) {
                        try {
                            long sleepTime = 20;
                            //Log.d(TAG, "info.presentationTimeUs : " +
                            // (info.presentationTimeUs / 1000) + " playTime: " +
                            // (System.currentTimeMillis() - startWhen) + " sleepTime : " + sleepTime);

                            if (sleepTime > 0) {
                                Thread.sleep(sleepTime);
                            }
                        } catch (InterruptedException e) {
                            // TODO Auto-generated catch block
                            e.printStackTrace();
                        }
                    }
                    String timeStr = "Frame Cost: " + allTime / frameCount + " ms,   All time: " + (allTime / 1000) + " s" ;
                    while(true && mCycleLabel) {
                        for(int i = 1; i <= frameCount && mCycleLabel; i++ ) {
                            mBitmap = drawTimeOnImage(bitmapArray[i - 1], timeStr);
                            mProcessHandler.removeMessages(MESSAGE_SHOW_IMAGE);
                            mProcessHandler.sendEmptyMessage(MESSAGE_SHOW_IMAGE);
                            try {
                                long sleepTime = 60;

                                if (sleepTime > 0) {
                                    Thread.sleep(sleepTime);
                                }
                            } catch (InterruptedException e) {
                                // TODO Auto-generated catch block
                                e.printStackTrace();
                            }
                        }
                    }

                }
            };
            mThread.start();


        }
    }

    public Bitmap showProgressOnImage(Bitmap inImg, int i, int allCount) {
        Bitmap image = Bitmap.createBitmap(inImg);
        Canvas canvas = new Canvas(image);
        if (canvas == null) {
            return image;
        }
        int strokeWidth = 20;
        if (canvas.getWidth() != 1080) {
            strokeWidth = (int) (strokeWidth * canvas.getWidth() / 1080);
        }


        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setColor(Color.parseColor("#ff0000"));
        float minSize = canvas.getWidth();
        if(canvas.getHeight() < canvas.getWidth()) minSize = canvas.getHeight();
        float textSize = minSize / 20;
        mPaint.setTextSize(textSize);
        String showText = "Progress: " + (int)(i * 100 / allCount) + "%";
        canvas.drawText(showText, canvas.getWidth() / 20, canvas.getWidth() / 10 + 10, mPaint);
        return image;
    }

    public Bitmap drawTimeOnImage(Bitmap inImg, String timeStr) {
        Bitmap image = Bitmap.createBitmap(inImg);
        Canvas canvas = new Canvas(image);
        if (canvas == null) {
            return image;
        }
        int strokeWidth = 20;
        if (canvas.getWidth() != 1080) {
            strokeWidth = (int) (strokeWidth * canvas.getWidth() / 1080);
        }

        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setColor(Color.parseColor("#ff0000"));
        float minSize = canvas.getWidth();
        if(canvas.getHeight() < canvas.getWidth()) minSize = canvas.getHeight();
        float textSize = minSize / 20;
        mPaint.setTextSize(textSize);
        canvas.drawText(timeStr, canvas.getWidth() / 20, canvas.getWidth() / 10 + 10, mPaint);
        return image;
    }
}
