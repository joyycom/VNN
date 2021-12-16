//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#include <metal_stdlib>
using namespace metal;

#define YCbCr2RGB_Mat half3x3(half3(1.h,1.h,1.h),half3(0.h,-0.18732h,1.8556h),half3(1.57481h,-0.46813h,0.h))
#define YCBCR2RGB(ycbcr) YCbCr2RGB_Mat * ((ycbcr) - half3(0.h, 0.5h, 0.5h))

struct RasterizerData {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinate;
};

struct VertexData {
    float4 position;
    float4 color;
};
struct VertexTextureData {
    float4 position;
    float2 textureCoordinate;
};

#pragma makr Compute Shades Part ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

kernel void render_yuv(
                       texture2d<half, access::sample> YTexture    [[texture(0)]],
                       texture2d<half, access::sample> CbCrTexture [[texture(1)]],
                       texture2d<half, access::write>  outTexture  [[texture(2)]],
                       ushort2                         gid         [[thread_position_in_grid]]
                       ) {
                           if(gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
                           const float2 p = static_cast<float2>(gid) / float2(outTexture.get_width(), outTexture.get_height());
                           constexpr sampler spr(coord::normalized, filter::linear, address::clamp_to_edge);
                           half3 YCbCr = half3(YTexture.sample(spr, p).r, CbCrTexture.sample(spr, p).rg);
                           outTexture.write(half4(YCBCR2RGB(YCbCr), 1.0h), gid);
                       }

kernel void render_bgra(
                        texture2d<half, access::sample> srcTexture  [[texture(0)]],
                        texture2d<half, access::write>  outTexture  [[texture(1)]],
                        ushort2                         gid         [[thread_position_in_grid]]
                        ) {
                            if(gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
                            const float2 p = static_cast<float2>(gid) / float2(outTexture.get_width(), outTexture.get_height());
                            constexpr sampler spr(coord::normalized, filter::linear, address::clamp_to_edge);
                            outTexture.write(srcTexture.sample(spr, p), gid);
                        }

kernel void render_blended_yuv(
                               texture2d<half, access::sample> foregroundYTexture      [[texture(0)]],
                               texture2d<half, access::sample> foregroundCbCrTexture   [[texture(1)]],
                               texture2d<half, access::sample> backgroundTexture       [[texture(2)]],
                               texture2d<half, access::sample> maskTexture             [[texture(3)]],
                               texture2d<half, access::write>  blendedTexture          [[texture(4)]],
                               ushort2                         gid                     [[thread_position_in_grid]]
                               ) {
                                   if(gid.x >= blendedTexture.get_width() || gid.y >= blendedTexture.get_height()) return;
                                   const float2 p = static_cast<float2>(gid) / float2(blendedTexture.get_width(), blendedTexture.get_height());
                                   constexpr sampler spr(coord::normalized, filter::linear, address::clamp_to_edge);
                                   half3 YCbCr = half3(foregroundYTexture.sample(spr, p).r, foregroundCbCrTexture.sample(spr, p).rg);
                                   half4 f = half4(YCBCR2RGB(YCbCr), 1.0h);
                                   half4 b = backgroundTexture.sample(spr, p);
                                   half4 m = maskTexture.sample(spr, p);
                                   half4 res = (f - b) * m.x + b; // = f * m.x + b * (1.h - m.x)
                                   blendedTexture.write(res, gid);
                               }

kernel void render_blended_bgra(
                                texture2d<half, access::sample> foregroundTexture   [[texture(0)]],
                                texture2d<half, access::sample> backgroundTexture   [[texture(1)]],
                                texture2d<half, access::sample> maskTexture         [[texture(2)]],
                                texture2d<half, access::write>  blendedTexture      [[texture(3)]],
                                ushort2                         gid         [[thread_position_in_grid]]
                                ) {
                                    if(gid.x >= blendedTexture.get_width() || gid.y >= blendedTexture.get_height()) return;
                                    const float2 p = static_cast<float2>(gid) / float2(blendedTexture.get_width(), blendedTexture.get_height());
                                    constexpr sampler spr(coord::normalized, filter::linear, address::clamp_to_edge);
                                    half4 f = foregroundTexture.sample(spr, p);
                                    half4 b = backgroundTexture.sample(spr, p);
                                    half4 m = maskTexture.sample(spr, p);
                                    half4 res = (f - b) * m.x + b; // = f * m.x + b * (1.h - m.x)
                                    blendedTexture.write(res, gid);
                                }

struct BoxFilterParam {
    int2 _kernel_size;
};
kernel void boxfilter_c4hw4_f16_tex(
                                    texture2d<half, access::read> src      [[ texture (0) ]],
                                    texture2d<half, access::write> dst     [[ texture (1) ]],
                                    constant BoxFilterParam& param         [[ buffer (0) ]],
                                    ushort2 thread_position_in_grid        [[ thread_position_in_grid ]]
                                    ) {
                                        if( thread_position_in_grid.x >= dst.get_width() || thread_position_in_grid.y >= dst.get_height() ) return;
                                        int2 offset = static_cast<int2>(thread_position_in_grid) - (param._kernel_size / 2);
                                        float4 res(0.f);
                                        int n = 0;
                                        for (int ky = 0; ky < param._kernel_size.y; ky++) {
                                            for (int kx = 0; kx < param._kernel_size.x; kx++) {
                                                int2 sample_coor = offset + int2(ky, kx);
                                                if (sample_coor.x >= 0 && sample_coor.y >= 0 && sample_coor.x < (int)src.get_width() && sample_coor.y < (int)src.get_height()) {
                                                    half4 dat = src.read(static_cast<uint2>(sample_coor));
                                                    res += static_cast<float4>(dat);
                                                    n += 1;
                                                }
                                            }
                                        }
                                        res = res / float(n);
                                        dst.write(static_cast<half4>(res), thread_position_in_grid);
                                    }

#pragma makr Render Shaders Part ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

vertex RasterizerData render_camframe_vert(
                                           const device VertexData *vertexDatArr [[ buffer(0) ]],
                                           uint vid                              [[ vertex_id ]]
                                           ) {
                                               RasterizerData out;
                                               out.position = vertexDatArr[vid].position;
                                               out.textureCoordinate.x = (out.position.x + 1.f) * 0.5;
                                               out.textureCoordinate.y = 1.f - (out.position.y + 1.f) * 0.5;
                                               return out;
                                           }


fragment float4 render_camframe_bgra_frag(
                                          RasterizerData in            [[ stage_in ]],
                                          texture2d<half> colorTexture [[ texture(0) ]]
                                          ) {
                                              constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                              const half4 colorSample = colorTexture.sample(spr, in.textureCoordinate);
                                              return float4(colorSample);
                                          }

fragment float4 render_camframe_420f_frag(
                                          RasterizerData in         [[ stage_in ]],
                                          texture2d<half> yTexture  [[ texture(0) ]],
                                          texture2d<half> uvTexture [[ texture(1) ]]
                                          ) {
                                              constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                              half3 YCbCr = half3(yTexture.sample(spr, in.textureCoordinate).r, uvTexture.sample(spr, in.textureCoordinate).rg);
                                              return float4(half4(YCBCR2RGB(YCbCr), 1.0h));
                                          }

fragment float4 render_blended_camframe_bgra_frag(
                                                  RasterizerData in                 [[ stage_in ]],
                                                  texture2d<half> colorTexture      [[ texture(0) ]],
                                                  texture2d<half> backgroundTexture [[ texture(1) ]],
                                                  texture2d<half> maskTexture       [[ texture(2) ]]
                                                  ) {
                                                      constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                                      half4 f = colorTexture.sample(spr, in.textureCoordinate);
                                                      half4 b = backgroundTexture.sample(spr, in.textureCoordinate);
                                                      half4 m = maskTexture.sample(spr, in.textureCoordinate);
                                                      const half4 colorSample = (f - b) * m.w + b; // = f * m.x + b * (1.h - m.x)
                                                      return float4(colorSample);
                                                  }

fragment float4 render_blended_camframe_420f_frag(
                                                  RasterizerData in                 [[ stage_in ]],
                                                  texture2d<half> yTexture          [[ texture(0) ]],
                                                  texture2d<half> uvTexture         [[ texture(1) ]],
                                                  texture2d<half> backgroundTexture [[ texture(2) ]],
                                                  texture2d<half> maskTexture       [[ texture(3) ]]
                                                  ) {
                                                      constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                                      half3 YCbCr = half3(yTexture.sample(spr, in.textureCoordinate).r, uvTexture.sample(spr, in.textureCoordinate).rg);
                                                      half4 f = half4(YCBCR2RGB(YCbCr), 1.0h);
                                                      half4 b = backgroundTexture.sample(spr, in.textureCoordinate);
                                                      half4 m = maskTexture.sample(spr, in.textureCoordinate);
                                                      const half4 colorSample = (f - b) * m.x + b; // = f * m.x + b * (1.h - m.x)
                                                      return float4(colorSample);
                                                  }

fragment float4 render_image_mask_background_frag(
                                                  RasterizerData in                 [[ stage_in ]],
                                                  texture2d<half> imgMaskTexture      [[ texture(0) ]],
                                                  texture2d<half> backgroundTexture [[ texture(1) ]]
                                                  ) {
                                                      constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                                      half4 f = imgMaskTexture.sample(spr, in.textureCoordinate);
                                                      half4 b = backgroundTexture.sample(spr, in.textureCoordinate);
                                                      const half4 colorSample = half4(f.xyz * f.w + b.xyz * (1.h - f.w), 1.h); // = f * m.x + b * (1.h - m.x)
                                                      return float4(colorSample);
                                                  }

fragment float4 render_mask_image_frag(
                                       RasterizerData in                 [[ stage_in ]],
                                       texture2d<half> maskTexture      [[ texture(0) ]],
                                       texture2d<half> imgTexture       [[ texture(1) ]]
                                       ) {
                                           constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                           half4 f = imgTexture.sample(spr, in.textureCoordinate);
                                           half4 m = maskTexture.sample(spr, in.textureCoordinate);
                                           const half4 colorSample = half4(f.xyz, m.x); // = f * m.x + b * (1.h - m.x)
                                           return float4(colorSample);
                                       }

vertex RasterizerData render_image_vert(
                                        const device float4 *vertexDatArr [[ buffer(0) ]],
                                        uint vid                          [[ vertex_id ]]
                                        ) {
                                            RasterizerData out;
                                            out.position = float4(vertexDatArr[vid][0], vertexDatArr[vid][1], 0, 1);
                                            out.textureCoordinate.x = (vertexDatArr[vid][2] + 1.f) * 0.5;
                                            out.textureCoordinate.y = (vertexDatArr[vid][3] + 1.f) * 0.5;
                                            return out;
                                        }

fragment float4 render_image_frag(
                                  RasterizerData in            [[ stage_in ]],
                                  texture2d<half> colorTexture [[ texture(0) ]]
                                  ) {
                                      constexpr sampler spr(coord::normalized, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
                                      const half4 colorSample = colorTexture.sample(spr, in.textureCoordinate);
                                      return float4(colorSample);
                                  }

vertex RasterizerData render_tritangle_2d_vert(
                                               const device VertexData* vertices [[buffer(0)]],
                                               const device uint* vertex_adds    [[buffer(1)]],
                                               uint vid                          [[vertex_id]]
                                               )
{
                                                   RasterizerData out;
                                                   out.position = float4(vertices[vertex_adds[vid]].position.x, vertices[vertex_adds[vid]].position.y, 0.0, 1.0);
                                                   out.color = vertices[vertex_adds[vid]].color;
                                                   return out;
                                               }

fragment float4 render_tritangle_2d_frag(RasterizerData in [[stage_in]]) {
    return float4(in.color.x, in.color.y, in.color.z, in.color.x + in.color.y + in.color.z > 0? 1.f: 0.f);
}

vertex RasterizerData render_offscreen_vert(
                                            const device VertexTextureData *vertexDatArr [[ buffer(0) ]],
                                            uint vid                              [[ vertex_id ]]
                                            ) {
                                                RasterizerData out;
                                                out.position = vertexDatArr[vid].position;
                                                out.textureCoordinate = vertexDatArr[vid].textureCoordinate;
                                                return out;
                                            }
