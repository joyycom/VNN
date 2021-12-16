//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo.glutils;

import android.graphics.Bitmap;
import android.opengl.GLES20;
import android.opengl.GLUtils;

import androidx.annotation.Nullable;


public class OpenGLUtils {
    private static final String TAG = "OpenGLUtils";
    public static final int INVALID_TEXTURE = -1;

    public static void checkGlError(String errorTag) {
        int error;
        while ((error = GLES20.glGetError()) != GLES20.GL_NO_ERROR) {
            throw new RuntimeException(errorTag + ": glError " + error);
        }
    }

    /**
     * 编译着色器
     *
     * @param shaderType 着色器的类型
     * @param source     资源源代码
     */
    private static int loadShader(int shaderType, String source) {
        // 创建着色器 ID
        int shaderId = GLES20.glCreateShader(shaderType);
        if (shaderId != 0) {
            // 1. 将着色器 ID 和着色器程序内容关联
            GLES20.glShaderSource(shaderId, source);
            // 2. 编译着色器
            GLES20.glCompileShader(shaderId);
            // 3. 验证编译结果
            int[] status = new int[1];
            GLES20.glGetShaderiv(shaderId, GLES20.GL_COMPILE_STATUS, status, 0);
            if (status[0] != GLES20.GL_TRUE) {
                // 编译失败删除这个着色器 id
                GLES20.glDeleteShader(shaderId);
                return 0;
            }
        }
        return shaderId;
    }
    /**
     * 创建一个 OpenGL 程序
     *
     * @param vertexSource   顶点着色器源码
     * @param fragmentSource 片元着色器源码
     */
    public static int createProgram(String vertexSource, String fragmentSource) {
        // 分别加载创建着色器
        int vertexShaderId = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        int fragmentShaderId = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (vertexShaderId != 0 && fragmentShaderId != 0) {
            // 创建 OpenGL 程序 ID
            int programId = GLES20.glCreateProgram();
            if (programId == 0) {
                return 0;
            }
            // 链接上 顶点着色器
            GLES20.glAttachShader(programId, vertexShaderId);
            // 链接上 片段着色器
            GLES20.glAttachShader(programId, fragmentShaderId);
            // 链接 OpenGL 程序
            GLES20.glLinkProgram(programId);
            // 验证链接结果是否失败
            int[] status = new int[1];
            GLES20.glGetProgramiv(programId, GLES20.GL_LINK_STATUS, status, 0);
            if (status[0] != GLES20.GL_TRUE) {
                // 失败后删除这个 OpenGL 程序
                GLES20.glDeleteProgram(programId);
                return 0;
            }
            return programId;
        }
        return 0;
    }
    public static int createTextureFromBitmap(int textureTarget, @Nullable Bitmap bitmap, int minFilter,
                                    int magFilter, int wrapS, int wrapT) {
        int[] textureHandle = new int[1];

        GLES20.glGenTextures(1, textureHandle, 0);
        GLES20.glBindTexture(textureTarget, textureHandle[0]);
        GLES20.glTexParameterf(textureTarget, GLES20.GL_TEXTURE_MIN_FILTER, minFilter);
        GLES20.glTexParameterf(textureTarget, GLES20.GL_TEXTURE_MAG_FILTER, magFilter);
        GLES20.glTexParameteri(textureTarget, GLES20.GL_TEXTURE_WRAP_S, wrapS);
        GLES20.glTexParameteri(textureTarget, GLES20.GL_TEXTURE_WRAP_T, wrapT);

        if (bitmap != null) {
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
        }
        return textureHandle[0];
    }
    public static int createLuminanceTexture(int width, int height, int[] textureId, int type) {
        GLES20.glGenTextures(1, textureId, 0);
        GLES20.glBindTexture(type, textureId[0]);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(type, 0, GLES20.GL_LUMINANCE, width, height, 0,
                GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, null);
        return textureId[0];
    }
    public static int createLuminanceAlphaTexture(int width, int height, int[] textureId, int type) {
        GLES20.glGenTextures(1, textureId, 0);
        GLES20.glBindTexture(type, textureId[0]);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(type, 0, GLES20.GL_LUMINANCE_ALPHA, width, height, 0,
                GLES20.GL_LUMINANCE_ALPHA, GLES20.GL_UNSIGNED_BYTE, null);
        return textureId[0];
    }
    public static int createRGBTexture(int width, int height, int[] textureId, int type) {
        GLES20.glGenTextures(1, textureId, 0);
        GLES20.glBindTexture(type, textureId[0]);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(type, 0, GLES20.GL_RGB, width, height, 0,
                GLES20.GL_RGB, GLES20.GL_UNSIGNED_BYTE, null);
        return textureId[0];
    }
    public static int createRGBATexture(int width, int height, int[] textureId, int type) {
        GLES20.glGenTextures(1, textureId, 0);
        GLES20.glBindTexture(type, textureId[0]);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameterf(type,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(type, 0, GLES20.GL_RGBA, width, height, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
        return textureId[0];
    }

    public static int createFrameBufferTexture(int width, int height) {
        int[] texture = new int[1];
        GLES20.glGenTextures(1, texture, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture[0]);

        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D,
                GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D,
                GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D,
                GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D,
                GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, width, height, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
        return texture[0];
    }
}
