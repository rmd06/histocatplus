//
//  shaders.metal
//  TestMetal2
//
//  Created by Raul Catena on 9/2/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct Constants {
    float4x4 baseModelMatrix;
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float4x4 premultipliedMatrix;
    float3x3 rotationMatrix;
};

struct PositionalData{
    float leftX;
    float rightX;
    float upperY;
    float lowerY;
    float halfTotalThickness;
    uint totalLayers;
    uint widthModel;
    uint heightModel;
    uint areaModel;
};

struct VertexOut{
    float4 position [[ position ]];
    float4 color;
};


//vertex float4 vertexShader(const device packed_float3 * vertexArray [[ buffer(0)]],
//                           unsigned int vid [[ vertex_id ]])
//{
//    return float4(vertexArray[vid], 1.0);
//}

vertex VertexOut oldvertexShader(
                              const device packed_float3* vertex_array [[ buffer(0) ]],
                              constant Constants & uniforms [[ buffer(1) ]],
                              constant PositionalData & positional [[ buffer(2) ]],
                              const device bool * mask [[ buffer(3) ]],
                              const device float * zValues [[ buffer(4) ]],
                              const device float * colors [[ buffer(5) ]],
                              unsigned int vid [[ vertex_id ]],
                              unsigned int iid [[ instance_id ]]) {
    
    int x = iid % positional.widthModel;
    int y = (iid/positional.widthModel)%positional.heightModel;
    int z = iid / positional.areaModel;
    
    VertexOut out;
    unsigned int baseIndex = iid * 7;
    if(colors[baseIndex] == 0.0f){
        return out;
    }
    
    float3 pos = float3(vertex_array[vid][0] + x - positional.widthModel/2, vertex_array[vid][1] + y - positional.heightModel/2, vertex_array[vid][2]+ z);
    
    //if(mask[iid % positional.areaModel] == true){
        out.position = uniforms.projectionMatrix * uniforms.baseModelMatrix * uniforms.modelViewMatrix * float4(pos, 1);
        out.color = float4(1.0f/vid, 1.0f/36 * vid, 0.5, 0.5);
    //}
    
    return out;
    
    //return float4(vertex_array[vid], 1.0);
}

vertex VertexOut vertexShader(
                              const device packed_float3* vertex_array [[ buffer(0) ]],
                              constant Constants & uniforms [[ buffer(1) ]],
                              constant PositionalData & positional [[ buffer(2) ]],
                              const device bool * mask [[ buffer(3) ]],
                              const device float * zValues [[ buffer(4) ]],
                              const device float * colors [[ buffer(5) ]],
                              const device bool * heightDescriptor [[ buffer(6) ]],
                              unsigned int vid [[ vertex_id ]],
                              unsigned int iid [[ instance_id ]]) {

    VertexOut out;
    
    unsigned int baseIndex = iid * 7;
    if(colors[baseIndex] == 0.0f)//Precalculated 0 alpha if zero do not process further (optimization)
        return out;
    
    uint indexZ = iid/positional.areaModel * 2;
    
    float down = heightDescriptor[vid] == true? zValues[indexZ + 1] - 1.0f : 0;
    
    float3 pos = float3(vertex_array[vid][0] + colors[baseIndex + 4] - positional.widthModel/2,
                        vertex_array[vid][1] + colors[baseIndex + 5] - positional.heightModel/2,
                        vertex_array[vid][2] + colors[baseIndex + 6] - down - positional.halfTotalThickness);
    
    
    //out.position = uniforms.projectionMatrix * uniforms.baseModelMatrix * uniforms.modelViewMatrix * float4(pos, 1);
    out.position = uniforms.premultipliedMatrix * float4(pos, 1);
    out.color = float4(colors[baseIndex + 1], colors[baseIndex + 2], colors[baseIndex + 3], colors[baseIndex]);
    
    return out;
    
    //return float4(vertex_array[vid], 1.0);
}

fragment half4 fragmentShader(const VertexOut interpolated [[ stage_in ]]){
    return half4(interpolated.color);
}


