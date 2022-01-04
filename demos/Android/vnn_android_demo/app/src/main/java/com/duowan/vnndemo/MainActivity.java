//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";
    private Button mBtnFace;
    private Button mBtnFaceMask;
    private Button mBtnDisneyFace;
    private Button mBtn3DGameFace;
    private Button mBtnFaceReenactment;
    private Button mBtnGesture;
    private Button mBtnObjTracking;
    private Button mBtnFaceCount;
    private Button mBtnQrCode;
    private Button mBtnDocRect;
    private Button mBtnPortraitSeg;
    private Button mBtnVideoSeg;
    private Button mBtnSkySeg;
    private Button mBtnClothesSeg;
    private Button mBtnAnimalSeg;
    private Button mBtnHeadSeg;
    private Button mBtnHairSeg;
    private Button mBtnComic;
    private Button mBtnCartoon;
    private Button mBtnObjCls;
    private Button mBtnSceneWether;
    private Button mBtnPersonAttribute;
    private Button mBtnPose;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_main);
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

        String exPath = getExternalFilesDir(null).getAbsolutePath();
        copyAssetsToFiles(getApplicationContext(), "vnn_models", exPath + "/vnn_models");
        mBtnFace = (Button) findViewById(R.id.effect_face);
        mBtnFaceMask = (Button) findViewById(R.id.effect_face_mask);
        mBtnDisneyFace = (Button) findViewById(R.id.effect_disney);
        mBtn3DGameFace = (Button) findViewById(R.id.effect_3dgame);
        mBtnFaceReenactment = (Button) findViewById(R.id.effect_reenact);
        mBtnGesture = (Button) findViewById(R.id.effect_gesture);
        mBtnObjTracking = (Button) findViewById(R.id.effect_objtracking);
        mBtnFaceCount = (Button) findViewById(R.id.effect_face_count);
        mBtnQrCode = (Button) findViewById(R.id.effect_qr);
        mBtnDocRect = (Button) findViewById(R.id.effect_docrect);
        mBtnPortraitSeg = (Button) findViewById(R.id.effect_portrait);
        mBtnVideoSeg = (Button) findViewById(R.id.effect_video_portrait);
        mBtnSkySeg = (Button) findViewById(R.id.effect_sky);
        mBtnClothesSeg = (Button) findViewById(R.id.effect_clothes);
        mBtnAnimalSeg = (Button) findViewById(R.id.effect_animal);
        mBtnHeadSeg = (Button) findViewById(R.id.effect_head);
        mBtnHairSeg = (Button) findViewById(R.id.effect_hair);
        mBtnComic = (Button) findViewById(R.id.effect_comic);
        mBtnCartoon = (Button) findViewById(R.id.effect_cartoon);
        mBtnObjCls = (Button) findViewById(R.id.effect_objcls);
        mBtnSceneWether = (Button) findViewById(R.id.effect_scene);
        mBtnPersonAttribute = (Button) findViewById(R.id.effect_person_attrib);
        mBtnPose = (Button) findViewById(R.id.effect_pose);
        initEffects();
    }
    private void initEffects(){
        mBtnFace.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_FACE_KEYPOINTS;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnFaceMask.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_FACE_MASK;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 0);
                startActivity(intent);
            }
        });
        mBtnDisneyFace.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_DISNEY_FACE;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtn3DGameFace.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_3DGAME_FACE;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnFaceReenactment.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_FACE_REENACT;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 0);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnGesture.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_GESTURE;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnObjTracking.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_OBJECT_TRACKING;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 0);
                startActivity(intent);
            }
        });
        mBtnFaceCount.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_FACE_COUNT;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnQrCode.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_QR_CODE;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnDocRect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_DOCUMENT_RECT;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnPortraitSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_PORTRAIT_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnVideoSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_VIDEO_PORTRAIT_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnSkySeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_SKY_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnClothesSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_CLOTHES_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnAnimalSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_ANIMAL_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnHeadSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_HEAD_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 0);
                startActivity(intent);
            }
        });
        mBtnHairSeg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_HAIR_SEG;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnComic.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_COMIC;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnCartoon.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_CARTOON;
                intent.putExtra("effectModeID", transferData);
                intent.putExtra("cameraVisibility", 1);
                intent.putExtra("imageVisibility", 1);
                startActivity(intent);
            }
        });
        mBtnObjCls.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_OBJECT_CLASSIFICATION;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnSceneWether.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_SCENE_WEATHER;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnPersonAttribute.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_PERSON_ATTRIBUTE;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
        mBtnPose.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, StreamProducers.class);
                int transferData = VNNHelper.VNN_EFFECT_MODE.VNN_POSE_LANDMARKS;
                intent.putExtra("effectModeID", transferData);
                startActivity(intent);
            }
        });
    }

    public void copyAssetsToFiles(Context context, String oldPath, String newPath) {
        try {
            String fileNames[] = context.getAssets().list(oldPath);//获取assets目录下的所有文件及目录名
            if (fileNames.length > 0) {//如果是目录
                File file = new File(newPath);
                if(!file.exists()) {
                    file.mkdirs();//如果文件夹不存在，则递归
                }
                for (String fileName : fileNames) {
                    String srcPath = oldPath + "/" + fileName;
                    String dstPath = newPath+"/"+fileName;
                    File f = new File(dstPath);
                    if(f.exists()) continue;
                    copyAssetsToFiles(context, srcPath, dstPath);
                }

            } else {//如果是文件
                File file = new File(newPath);
                if(!file.exists()) {
                    InputStream is = context.getAssets().open(oldPath);
                    FileOutputStream fos = new FileOutputStream(file);
                    byte[] buffer = new byte[1024];
                    int byteCount=0;
                    while((byteCount=is.read(buffer))!=-1) {//循环从输入流读取 buffer字节
                        fos.write(buffer, 0, byteCount);//将读取的输入流写入到输出流
                    }
                    fos.flush();//刷新缓冲区
                    is.close();
                    fos.close();
                }

            }
        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();

        }
    }
}