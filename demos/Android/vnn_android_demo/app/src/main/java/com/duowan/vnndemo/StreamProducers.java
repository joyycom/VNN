//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.Nullable;

public class StreamProducers  extends Activity {
    private static final String TAG = "StreamProducers";
    private Button mButtonCamera;
    private Button mButtonImage;
    private int vnnModeID;

    private static final int PERMISSION_REQUEST_CAMERA = 0;
    private static final int PERMISSION_REQUEST_WRITE_EXTERNAL_STORAGE = 1;

    private int mSelectFunction = 0;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.stream_producer);
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
        mButtonCamera = (Button) findViewById(R.id.btn_camera);
        mButtonImage = (Button) findViewById(R.id.btn_image);

        Intent intent = getIntent();
        vnnModeID = intent.getIntExtra("effectModeID", 0);
        int cameraVisibility = intent.getIntExtra("cameraVisibility", 1);
        int imageVisibility = intent.getIntExtra("imageVisibility", 1);
        if(cameraVisibility == 0) {
            mButtonCamera.setVisibility(View.INVISIBLE);
        }
        if(imageVisibility == 0) {
            mButtonImage.setVisibility(View.INVISIBLE);
        }
        mButtonCamera.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                if (Build.VERSION.SDK_INT >= 23) {
                    mSelectFunction = 0;
                    if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                        if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) {}
                        requestPermissions(new String[]{Manifest.permission.CAMERA}, PERMISSION_REQUEST_CAMERA);
                    }else {
                        requestStoragePermission();
                    }
                }else {
                    Intent intent = new Intent(StreamProducers.this, CameraActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "camera");
                    startActivity(intent);
                }
            }
        });
        mButtonImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (Build.VERSION.SDK_INT >= 23) {
                    mSelectFunction = 1;
                    requestStoragePermission();
                }else {
                    Intent intent = new Intent(StreamProducers.this, ImageActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "image");
                    startActivity(intent);
                }

            }
        });
    }
    private void requestStoragePermission(){
        if (Build.VERSION.SDK_INT >= 23) {
            if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        PERMISSION_REQUEST_WRITE_EXTERNAL_STORAGE);
            }else {
                if(mSelectFunction == 0){
                    Intent intent = new Intent(StreamProducers.this, CameraActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "camera");
                    startActivity(intent);
                }else if(mSelectFunction == 1){
                    Intent intent = new Intent(StreamProducers.this, ImageActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "image");
                    startActivity(intent);
                }
            }
        }
    }

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PERMISSION_REQUEST_CAMERA) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                requestStoragePermission();

            } else {
                Toast.makeText(this, "Camera Permission Denied", Toast.LENGTH_SHORT).show();
            }
        }else if(requestCode == PERMISSION_REQUEST_WRITE_EXTERNAL_STORAGE){
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if(mSelectFunction == 0){
                    Intent intent = new Intent(StreamProducers.this, CameraActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "camera");
                    startActivity(intent);
                }else if(mSelectFunction == 1){
                    Intent intent = new Intent(StreamProducers.this, ImageActivity.class);
                    intent.putExtra("vnnModeID", vnnModeID);
                    intent.putExtra("streamType", "image");
                    startActivity(intent);
                }
            } else {
                Toast.makeText(this, "Storage Permission Denied", Toast.LENGTH_SHORT).show();
            }
        }
    }
}
