//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo.glutils;

public class GLRotationUtil {

    public static final float[] TEXTURE_ROTATION_0 = {
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
    };

    public static final float[] TEXTURE_ROTATED_90 = {
            1.0f, 1.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            0.0f, 0.0f,
    };
    public static final float[] TEXTURE_ROTATED_180 = {
            1.0f, 0.0f,
            0.0f, 0.0f,
            1.0f, 1.0f,
            0.0f, 1.0f,
    };
    public static final float[] TEXTURE_ROTATED_270 = {
            0.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 0.0f,
            1.0f, 1.0f,
    };

    public static final float[] VERTEX = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f,
    };

    private GLRotationUtil() {
    }

    public static float[] getRotatedTextureCoord(final int rotation, final boolean flipHorizontal,
                                                 final boolean flipVertical) {
        float[] rotatedTex;
        switch (rotation) {
            case 90:
                rotatedTex = TEXTURE_ROTATED_90;
                break;
            case 180:
                rotatedTex = TEXTURE_ROTATED_180;
                break;
            case 270:
                rotatedTex = TEXTURE_ROTATED_270;
                break;
            case 0:
            case 360:
            default:
                rotatedTex = TEXTURE_ROTATION_0;
                break;
        }
        if (flipHorizontal) {
            rotatedTex = new float[]{
                    flip(rotatedTex[0]), rotatedTex[1],
                    flip(rotatedTex[2]), rotatedTex[3],
                    flip(rotatedTex[4]), rotatedTex[5],
                    flip(rotatedTex[6]), rotatedTex[7],
            };
        }
        if (flipVertical) {
            rotatedTex = new float[]{
                    rotatedTex[0], flip(rotatedTex[1]),
                    rotatedTex[2], flip(rotatedTex[3]),
                    rotatedTex[4], flip(rotatedTex[5]),
                    rotatedTex[6], flip(rotatedTex[7]),
            };
        }
        return rotatedTex;
    }
    public static float[] cubeFlipVertical() {
        float[] rotatedTex = new float[]{
                VERTEX[0], -VERTEX[1],
                VERTEX[2], -VERTEX[3],
                VERTEX[4], -VERTEX[5],
                VERTEX[6], -VERTEX[7],
        };
        return rotatedTex;
    }

    private static float flip(final float i) {
        if (i == 0.0f) {
            return 1.0f;
        }
        return 0.0f;
    }
}
