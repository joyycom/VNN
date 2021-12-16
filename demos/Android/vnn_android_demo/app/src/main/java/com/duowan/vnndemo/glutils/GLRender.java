//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
package com.duowan.vnndemo.glutils;

import android.opengl.GLES20;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

public class GLRender {
    private final static String TAG = "VNNGLRender";
    private static final String VERTEX_SHADER = "" +
            "attribute vec4 position;\n" +
            "attribute vec4 iTexCoord;\n" +
            "varying vec2 texCoord;\n" +
            "void main()\n" +
            "{\n" +
            "texCoord = iTexCoord.xy;\n" +
            "gl_Position = position;\n" +
            "}";
    public static final String DRAW_IMAGE_FRAGMENT_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D imgTexture;\n" +
            "void main()\n" +
            "{\n" +
            "vec4 imgValue = texture2D(imgTexture, texCoord).rgba;\n" +
            "gl_FragColor = imgValue;\n" +
            "}";
    public static final String DRAW_RGB_IMAGE_FRAGMENT_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D imgTexture;\n" +
            "void main()\n" +
            "{\n" +
            "vec3 imgValue = texture2D(imgTexture, texCoord).rgb;\n" +
            "gl_FragColor = vec4(imgValue, 1.0);\n" +
            "}";
    public static final String DRAW_YUV_FRAGMENT_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D yTexture;\n" +
            "uniform sampler2D uTexture;\n" +
            "uniform sampler2D vTexture;\n" +
            "void main()\n" +
            "{\n" +
            "vec3 yuv;\n" +
            "vec3 rgb;\n" +
            "yuv.x = texture2D(yTexture, texCoord).r;\n" +
            "yuv.y = texture2D(uTexture, texCoord).r - 0.5;\n" +
            "yuv.z = texture2D(vTexture, texCoord).r - 0.5;\n" +
            "rgb = mat3(1.0, 1.0, 1.0,\n" +
            "0.0, -0.39465, 2.03211,\n" +
            "1.13983, -0.5806, 0.0\n" +
            ") * yuv;\n" +
            "gl_FragColor = vec4(rgb, 1);\n" +
            "}";
    public static final String DRAW_MASK_RECT_FRAGMENT_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D maskTexture;\n" +
            "void main()\n" +
            "{\n" +
            "float maskValue = texture2D(maskTexture, texCoord).r;\n" +
            "gl_FragColor = vec4(maskValue, maskValue, maskValue, maskValue);\n" +
            "}";
    public static final String DRAW_IMAGE_AND_MASK_RECT_FRAGMENT_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D maskTexture;\n" +
            "uniform sampler2D imgTexture;\n" +
            "void main()\n" +
            "{\n" +
            "float maskValue = texture2D(maskTexture, texCoord).r;\n" +
            "vec3 imgValue = texture2D(imgTexture, texCoord).rgb;\n" +
            "gl_FragColor = vec4(imgValue, maskValue);\n" +
            "}";
    public static final String DRAW_BLEND_IMAGE_MASK_BACKGROUND_SHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 texCoord;\n" +
            "uniform sampler2D maskTexture;\n" +
            "uniform sampler2D backgroundTexture;\n" +
            "void main()\n" +
            "{\n" +
            "vec4 maskValue = texture2D(maskTexture, texCoord);\n" +
            "vec4 backgroundColor = texture2D(backgroundTexture, texCoord);\n" +
            "float backgroundAlpha = maskValue.a;\n" +
            "float r = backgroundColor.r * (1.0 - backgroundAlpha) + maskValue.r * backgroundAlpha;\n" +
            "float g = backgroundColor.g * (1.0 - backgroundAlpha) + maskValue.g * backgroundAlpha;\n" +
            "float b = backgroundColor.b * (1.0 - backgroundAlpha) + maskValue.b * backgroundAlpha;\n" +
            "backgroundColor = vec4(r, g, b, 1.0);\n" +
            "gl_FragColor = backgroundColor;\n" +
            "}";


    //attribute name
    private final static String POSITION_COORDINATE = "position";
    private final static String TEXTURE_COORDINATE = "iTexCoord";
    //texture name
    private final static String TEXTURE_BACKGROUND = "backgroundTexture";
    private final static String TEXTURE_MASK = "maskTexture";
    private final static String TEXTURE_IMAGE = "imgTexture";
    private final static String TEXTURE_REPLACE = "replaceTexture";
    private final static String TEXTURE_IMG = "imgTexture";
    private final static String TEXTURE_Y = "yTexture";
    private final static String TEXTURE_U = "uTexture";
    private final static String TEXTURE_V = "vTexture";

    //framebuffers
    private int[] mFrameBuffers;
    private int[] mMaskFrameBuffers;
    private int[] mImageFrameBuffers;

    //programs
    private int mDrawYUVProgram = 0;
    private int mDrawImageProgram = 0;
    private int mDrawMaskProgram = 0;
    private int mDrawBlendProgram = 0;

    //uniforms
    private int mAttribVertex = -1;
    private int mTexturePosition = -1;
    private int mImg = -1;
    private int mYImg = -1;
    private int mUImg = -1;
    private int mVImg = -1;
    private int mMask = -1;
    private int mImage = -1;
    private int mBackground = -1;
    
    //out textures
    private int mCameraDataTexture = OpenGLUtils.INVALID_TEXTURE;
    private int mMaskTexture = OpenGLUtils.INVALID_TEXTURE;
    private int mImageTexture = OpenGLUtils.INVALID_TEXTURE;

    private final FloatBuffer mGLVertexBuffer;
    private final FloatBuffer mGLTextureBuffer;
    private final FloatBuffer mGLVertexRectBuffer;
    private FloatBuffer mShowVertexBuffer;

    private FloatBuffer mAdjustTextureBuffer;
    private FloatBuffer mAdjustVertexBuffer;


    private int mViewPortWidth;
    private int mViewPortHeight;

    public GLRender() {
        mGLVertexBuffer = ByteBuffer.allocateDirect(GLRotationUtil.VERTEX.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        mGLVertexBuffer.put(GLRotationUtil.VERTEX).position(0);

        mGLTextureBuffer = ByteBuffer.allocateDirect(GLRotationUtil.TEXTURE_ROTATION_0.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        mGLTextureBuffer.put(GLRotationUtil.TEXTURE_ROTATION_0).position(0);

        mAdjustVertexBuffer = ByteBuffer.allocateDirect(GLRotationUtil.VERTEX.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        mAdjustVertexBuffer.put(GLRotationUtil.VERTEX).position(0);
        mGLVertexRectBuffer = ByteBuffer.allocateDirect(GLRotationUtil.VERTEX.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        mGLVertexRectBuffer.put(GLRotationUtil.VERTEX).position(0);
        mShowVertexBuffer = ByteBuffer.allocateDirect(GLRotationUtil.VERTEX.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        mShowVertexBuffer.put(GLRotationUtil.cubeFlipVertical()).position(0);
    }

    public void setViewPortWH(int width, int height) {
        mViewPortWidth = width;
        mViewPortHeight = height;
    }


    public void setTextureCoordBuffer(int orientation, boolean flipVertical) {
        float[] buffer = GLRotationUtil.getRotatedTextureCoord(orientation, true, flipVertical);
        if (mAdjustTextureBuffer == null) {
            mAdjustTextureBuffer = ByteBuffer.allocateDirect(buffer.length * 4)
                    .order(ByteOrder.nativeOrder())
                    .asFloatBuffer();
        }
        mAdjustTextureBuffer.clear();
        mAdjustTextureBuffer.put(buffer).position(0);
    }
   
    public int drawYUVImgeToTexture(int yTexture, int uTexture, int vTexture,
                                      int width, int height,
                                      ByteBuffer yData, ByteBuffer uData, ByteBuffer vData) {

        if (mDrawYUVProgram == 0) {
            mDrawYUVProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_YUV_FRAGMENT_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawYUVProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawYUVProgram, TEXTURE_COORDINATE);
            mYImg = GLES20.glGetUniformLocation(mDrawYUVProgram, TEXTURE_Y);
            mUImg = GLES20.glGetUniformLocation(mDrawYUVProgram, TEXTURE_U);
            mVImg = GLES20.glGetUniformLocation(mDrawYUVProgram, TEXTURE_V);
        }

        if (mCameraDataTexture == OpenGLUtils.INVALID_TEXTURE) {
            mCameraDataTexture = OpenGLUtils.createFrameBufferTexture(mViewPortWidth, mViewPortHeight);
        }
        GLES20.glViewport(0, 0, mViewPortWidth, mViewPortHeight);
        GLES20.glUseProgram(mDrawYUVProgram);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, width, height, GLES20.GL_LUMINANCE,
                GLES20.GL_UNSIGNED_BYTE, yData);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, uTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, width / 2, height / 2, GLES20.GL_LUMINANCE_ALPHA,
                GLES20.GL_UNSIGNED_BYTE, uData);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, vTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, width / 2, height / 2, GLES20.GL_LUMINANCE_ALPHA,
                GLES20.GL_UNSIGNED_BYTE, vData);

        GLES20.glUniform1i(mYImg, 0);
        GLES20.glUniform1i(mUImg, 1);
        GLES20.glUniform1i(mVImg, 2);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE3);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mCameraDataTexture);

        if (mFrameBuffers == null) {
            mFrameBuffers = new int[1];
            GLES20.glGenFramebuffers(1, mFrameBuffers, 0);
        }

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mFrameBuffers[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                mCameraDataTexture, 0);

        mGLVertexBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mGLVertexBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mAdjustTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0, mAdjustTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        return mCameraDataTexture;
        //return yTexture;
    }


    public void onDraw(final int textureId) {
        if (mDrawImageProgram == 0) {
            mDrawImageProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_IMAGE_FRAGMENT_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawImageProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawImageProgram, TEXTURE_COORDINATE);
            mImg = GLES20.glGetUniformLocation(mDrawImageProgram, TEXTURE_IMG);
        }
        GLES20.glUseProgram(mDrawImageProgram);

        mAdjustVertexBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mAdjustVertexBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mGLTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0,
                mGLTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);

        if (textureId != OpenGLUtils.INVALID_TEXTURE) {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        }
        GLES20.glUniform1i(mImg, 0);

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
    }
    public int drawMaskRectToTexture(int maskTexture, int width, int height,
                                       ByteBuffer data, float[] rect, boolean clearFlag) {

        if (mDrawMaskProgram == 0) {
            mDrawMaskProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_MASK_RECT_FRAGMENT_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawMaskProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawMaskProgram, TEXTURE_COORDINATE);
            mMask = GLES20.glGetUniformLocation(mDrawMaskProgram, TEXTURE_MASK);
        }

        if (mMaskTexture == OpenGLUtils.INVALID_TEXTURE) {
            mMaskTexture = OpenGLUtils.createFrameBufferTexture(mViewPortWidth, mViewPortHeight);
        }
        GLES20.glViewport(0, 0, mViewPortWidth, mViewPortHeight);
        GLES20.glUseProgram(mDrawMaskProgram);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);


        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, maskTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, width, height, GLES20.GL_LUMINANCE,
                GLES20.GL_UNSIGNED_BYTE, data);
        //GLES20.glUniform1i(mMask, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mMaskTexture);

        if (mMaskFrameBuffers == null) {
            mMaskFrameBuffers = new int[1];

            GLES20.glGenFramebuffers(1, mMaskFrameBuffers, 0);
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mMaskFrameBuffers[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                mMaskTexture, 0);
        if(clearFlag) {
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        }
        float width_f = rect[2] - rect[0];
        float height_f = rect[3] - rect[1];
        float x0 = -1.0f + rect[0] * 2.0f;
        float y0 = -1.0f + rect[1] * 2.0f;
        float x1 = x0 + width_f * 2.0f;
        float y1 = y0 + height_f * 2.0f;

        float[] rectVertexCoord = {
                x0, y1,
                x1, y1,
                x0, y0,
                x1, y0
        };
        mGLVertexRectBuffer.put(rectVertexCoord);
        mGLVertexRectBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mGLVertexRectBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mGLTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0, mGLTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        return mMaskTexture;
        //return maskTexture;
    }

    public int drawImageAndMaskRectToTexture(int maskTexture,
                                               int maskWidth,
                                               int maskHeight,
                                               ByteBuffer maskData,
                                               int disneyTexture,
                                               int disneyWidth,
                                               int disneyHeight,
                                               ByteBuffer disneyData,
                                               float[] rect,
                                               boolean clearFlag
    ) {
        if (mDrawMaskProgram == 0) {
            mDrawMaskProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_IMAGE_AND_MASK_RECT_FRAGMENT_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawMaskProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawMaskProgram, TEXTURE_COORDINATE);
            mMask = GLES20.glGetUniformLocation(mDrawMaskProgram, TEXTURE_MASK);
            mImage = GLES20.glGetUniformLocation(mDrawMaskProgram, TEXTURE_IMAGE);
        }

        if (mMaskTexture == OpenGLUtils.INVALID_TEXTURE) {
            mMaskTexture = OpenGLUtils.createFrameBufferTexture(mViewPortWidth, mViewPortHeight);
        }
        GLES20.glViewport(0, 0, mViewPortWidth, mViewPortHeight);
        GLES20.glUseProgram(mDrawMaskProgram);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);


        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, maskTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, maskWidth, maskHeight, GLES20.GL_LUMINANCE,
                GLES20.GL_UNSIGNED_BYTE, maskData);


        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, disneyTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, disneyWidth, disneyHeight, GLES20.GL_RGB,
                GLES20.GL_UNSIGNED_BYTE, disneyData);

        GLES20.glUniform1i(mMask, 0);
        GLES20.glUniform1i(mImage, 1);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mMaskTexture);

        if (mMaskFrameBuffers == null) {
            mMaskFrameBuffers = new int[1];

            GLES20.glGenFramebuffers(1, mMaskFrameBuffers, 0);
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mMaskFrameBuffers[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                mMaskTexture, 0);
        if(clearFlag) {
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        }
        float width_f = rect[2] - rect[0];
        float height_f = rect[3] - rect[1];
        float x0 = -1.0f + rect[0] * 2.0f;
        float y0 = -1.0f + rect[1] * 2.0f;
        float x1 = x0 + width_f * 2.0f;
        float y1 = y0 + height_f * 2.0f;

        float[] rectTextureCoord = {
                x0, y1,
                x1, y1,
                x0, y0,
                x1, y0
        };
        mGLVertexRectBuffer.put(rectTextureCoord);
        mGLVertexRectBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mGLVertexRectBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mGLTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0, mGLTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        return mMaskTexture;
        //return maskTexture;
        //return disneyTexture;
    }

    public int drawBlendMaskImageTexture(final int inputTexture, int maskTexture) {

        if (mDrawBlendProgram == 0) {
            mDrawBlendProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_BLEND_IMAGE_MASK_BACKGROUND_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawBlendProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawBlendProgram, TEXTURE_COORDINATE);
            mBackground = GLES20.glGetUniformLocation(mDrawBlendProgram, TEXTURE_BACKGROUND);
            mMask = GLES20.glGetUniformLocation(mDrawBlendProgram, TEXTURE_MASK);
        }

        if (mImageTexture == OpenGLUtils.INVALID_TEXTURE) {
            mImageTexture = OpenGLUtils.createFrameBufferTexture(mViewPortWidth, mViewPortHeight);
        }


        GLES20.glUseProgram(mDrawBlendProgram);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, maskTexture);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, inputTexture);

        GLES20.glUniform1i(mBackground, 0);
        GLES20.glUniform1i(mMask, 1);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mImageTexture);

        if (mImageFrameBuffers == null) {
            mImageFrameBuffers = new int[1];

            GLES20.glGenFramebuffers(1, mImageFrameBuffers, 0);
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mImageFrameBuffers[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                mImageTexture, 0);

        mShowVertexBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mShowVertexBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mGLTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0, mGLTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        return mImageTexture;
    }
    public int drawRGBImageToTexture(int maskTexture, int width, int height,
                                     ByteBuffer data) {

        if (mDrawMaskProgram == 0) {
            mDrawMaskProgram =
                    OpenGLUtils.createProgram(VERTEX_SHADER, DRAW_RGB_IMAGE_FRAGMENT_SHADER);
            mAttribVertex = GLES20.glGetAttribLocation(mDrawMaskProgram, POSITION_COORDINATE);
            mTexturePosition = GLES20.glGetAttribLocation(mDrawMaskProgram, TEXTURE_COORDINATE);
            mImage = GLES20.glGetUniformLocation(mDrawMaskProgram, TEXTURE_IMAGE);
        }

        if (mMaskTexture == OpenGLUtils.INVALID_TEXTURE) {
            mMaskTexture = OpenGLUtils.createFrameBufferTexture(mViewPortWidth, mViewPortHeight);
        }

        GLES20.glUseProgram(mDrawMaskProgram);
        OpenGLUtils.checkGlError("glUseProgram");
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);


        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, maskTexture);
        GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, width, height, GLES20.GL_RGB,
                GLES20.GL_UNSIGNED_BYTE, data);
        OpenGLUtils.checkGlError("glBindTexture");
        //GLES20.glUniform1i(mImage, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mMaskTexture);

        if (mMaskFrameBuffers == null) {
            mMaskFrameBuffers = new int[1];

            GLES20.glGenFramebuffers(1, mMaskFrameBuffers, 0);
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mMaskFrameBuffers[0]);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D,
                mMaskTexture, 0);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

        mShowVertexBuffer.position(0);
        GLES20.glVertexAttribPointer(mAttribVertex, 2, GLES20.GL_FLOAT, false, 0, mShowVertexBuffer);
        GLES20.glEnableVertexAttribArray(mAttribVertex);

        mGLTextureBuffer.position(0);
        GLES20.glVertexAttribPointer(mTexturePosition, 2, GLES20.GL_FLOAT, false, 0, mGLTextureBuffer);
        GLES20.glEnableVertexAttribArray(mTexturePosition);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(mAttribVertex);
        GLES20.glDisableVertexAttribArray(mTexturePosition);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        return mMaskTexture;
        //return maskTexture;
    }
    
    public void releaseTextures() {
        if (mCameraDataTexture != OpenGLUtils.INVALID_TEXTURE) {
            GLES20.glDeleteTextures(1, new int[]{mCameraDataTexture}, 0);
        }
        mCameraDataTexture = OpenGLUtils.INVALID_TEXTURE;

        if (mMaskTexture != OpenGLUtils.INVALID_TEXTURE) {
            GLES20.glDeleteTextures(1, new int[]{mMaskTexture}, 0);
        }
        mMaskTexture = OpenGLUtils.INVALID_TEXTURE;

        if (mImageTexture != OpenGLUtils.INVALID_TEXTURE) {
            GLES20.glDeleteTextures(1, new int[]{mImageTexture}, 0);
        }
        mImageTexture = OpenGLUtils.INVALID_TEXTURE;
    }

    public void releaseFrameBuffers() {
        if (mFrameBuffers != null) {
            GLES20.glDeleteFramebuffers(1, mFrameBuffers, 0);
            mFrameBuffers = null;
        }
        if (mMaskFrameBuffers != null) {
            GLES20.glDeleteFramebuffers(1, mMaskFrameBuffers, 0);
            mMaskFrameBuffers = null;
        }
        if (mImageFrameBuffers != null) {
            GLES20.glDeleteFramebuffers(1, mImageFrameBuffers, 0);
            mImageFrameBuffers = null;
        }
    }
    public void releaseProgams() {
        if(mDrawImageProgram != 0) {
            GLES20.glDeleteProgram(mDrawImageProgram);
            mDrawImageProgram = 0;
        }
        if(mDrawYUVProgram != 0) {
            GLES20.glDeleteProgram(mDrawYUVProgram);
            mDrawYUVProgram = 0;
        }
        if(mDrawMaskProgram != 0) {
            GLES20.glDeleteProgram(mDrawMaskProgram);
            mDrawMaskProgram = 0;
        }
        if(mDrawBlendProgram != 0) {
            GLES20.glDeleteProgram(mDrawBlendProgram);
            mDrawBlendProgram = 0;
        }
    }
    public final void destroyGLRender() {
        releaseFrameBuffers();
        releaseTextures();
        releaseProgams();
    }
}
