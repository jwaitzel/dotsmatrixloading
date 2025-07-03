//
//  Shader.metal
//  ShaderToyyToSwiftUI
//
//  Created by javi www on 6/4/23.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct Fragment {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

struct Vertex {
    float2 position [[attribute(0)]];
    float4 color;
};

struct FragmentUniforms {
    float iTime;
    float2 renderSize;
    float gridSize;
    float animSpeed;
    float minRad;
    float maxRad;
};

struct FragmentUniformsBasic {
    float iTime;
    float2 renderSize;
};


struct FragmentFreq {
    float yWaveAmpl;
    float yFreqVal;
};

/// - For each vertex
vertex Fragment vertexShader(const device Vertex *vertexArray[[buffer(0)]], unsigned int vid [[vertex_id]]) {
    
    Vertex input = vertexArray[vid];
    
    Fragment output;
    output.position = float4(input.position.x, input.position.y, 0.0, 1.0);
    output.color = input.color;
    output.texCoord = (input.position + 1.0) / 2.0;
    return output;
}

fragment float4 fragmentWaveLoop(Fragment input [[stage_in]],
                                           constant FragmentUniforms &unis [[ buffer(0) ]],
                                            constant FragmentFreq &freqs [[ buffer(1) ]]) {
    float2 resolution = unis.renderSize;
    float aspect = resolution.x / resolution.y;
    float time = unis.iTime;
    float gridWidthSize = unis.gridSize;
    float2 gridUV = input.texCoord * gridWidthSize;
    gridUV.y /= aspect;

    float animSpeed = unis.animSpeed;

    gridUV.x += time * animSpeed; // Leftward motion with speed modulation

    gridUV.x += sin(gridUV.y * 0.5 + time * 1.2) * 0.01; // X wiggle based on Y
    gridUV.y += cos(gridUV.x * 0.4 + time * 0.8) * 0.2; // Y oscillation based on X
    
    float2 uv = fract(gridUV) - 0.5;
    
    // Distance with spiral distortion
    float dist = length(uv + sin(time * 0.5 + length(gridUV)) * 0.1);
    
    // Size variation with multiple waves
    float sizeWave = sin(gridUV.y * freqs.yFreqVal + time * 1.8) * freqs.yWaveAmpl + cos(gridUV.x * 0.6 + time * 1.0) * 0.5 - 0.15;
    
    float sizePot = sizeWave; // pow(0.05, );
    float radius = clamp(sizePot, unis.minRad, unis.maxRad);
    
    // Smoothstep for soft dots
    float dot = smoothstep(radius, radius - 0.01, dist);
    
    // Fade and pulse effects
//    float fade = sin(fract(gridUV.x) * 3.14159 + time * 0.7) * 0.1 + 0.9;
//    float pulse = sin(time * 2.0 + gridUV.y * 0.3) * 0.1 + 0.9;
//    dot *= fade * pulse;
    
    // Solid white with intensity
    float intensity = dot * 1.3;
    float3 color = float3(1.0, 1.0, 1.0);
    return float4(color * intensity, 1.0);
}

fragment float4 fragmentShaderVerticalLine(Fragment input [[stage_in]],
                                           constant FragmentUniformsBasic &unis [[ buffer(0) ]] ) {

    float2 resolution = unis.renderSize;
    float aspect = resolution.x / resolution.y;
    float time = cos(unis.iTime) * -0.69 + 0.75;
    
    float gridWidthSize = 29.6;
    float2 gridUV = input.texCoord * gridWidthSize;
    gridUV.x *= aspect;
    float2 uv = fract(gridUV) - 0.5;
    
    float dist = length(uv);
    float speedAnim = 4.5;

    float waveY = pow(2.8, cos(gridUV.y * 0.12 + (1.0 * time * speedAnim) - 5.0) * 6.4 ) * 0.001 ;// pow(3.9, cos(gridUV.y * 0.5 + cos((time * speedAnim) - 0.5) ) * 2.5) * 0.01 + 0.01;

    //float animProgress = (waveY) * 0.25 + 0.5; // normalized to [0,1]
    float t = clamp(waveY, 0.0, 1.0);

    float radius = mix(0.022, 0.35, t);
    float dot = smoothstep(radius, radius - 0.01, dist);
    
    return float4(dot, dot, dot, dot);
}

fragment float4 fragmentShaderWave(Fragment input [[stage_in]],
                               constant float &time [[ buffer(0) ]],
                                   constant float2 &resolution [[ buffer(1) ]] ) {
    
    float aspect = resolution.x / resolution.y;
//    float2 uv = input.texCoord;
    float gridWidthSize = 12.0;
    float2 gridUV = input.texCoord * gridWidthSize;
    gridUV.y /= aspect;
    float2 uv = fract(gridUV) - 0.5;
    
    float dist = length(uv);
    float speedAnim = 20.5;
    float waveX = sin(gridUV.y * 0.5 + time * speedAnim);
    float waveY = cos(gridUV.x * 0.5 + time * speedAnim);

    float animProgress = (waveX + waveY) * 0.25 + 0.5; // normalized to [0,1]
    float t = clamp(animProgress, 0.0, 1.0);

    float radius = mix(0.01, 0.15, t);
    float dot = smoothstep(radius, radius - 0.01, dist);
    
    return float4(dot, dot, dot, dot);
}

fragment float4 fragmentShaderLeftToRigt(Fragment input [[stage_in]],
                                         constant float &time [[ buffer(0) ]],
                                         constant float2 &resolution [[ buffer(1) ]],
                                         constant float &leftToRightT [[ buffer(2) ]],
                                         constant float &gridSize [[ buffer(3) ]],
                                         constant float &dotSize [[ buffer(4) ]],
                                         constant float &borderStep [[ buffer(5) ]],
                                         constant float &animatedionSpeedLTR [[ buffer(6) ]],
                                         constant bool &loopAnim [[ buffer(7) ]],
                                         constant float &minDotSize [[ buffer(8) ]],
                                         constant float &grad [[ buffer(9) ]]) {
        
    float aspect = resolution.y / resolution.x;
    float2 uv = input.texCoord;
    uv.y *= aspect;

//    float gridWidthSize = gridSize;
    float2 gridUV = uv * (gridSize);
    float2 cellUV = fract(gridUV) - 0.5;
    
    // Original time calculation
    float linearTime = min(time * (animatedionSpeedLTR * 0.25), 1.0); //; //sin(() - 1.0) * 0.5 + 0.5;
    if(loopAnim) {
        linearTime = sin((time * animatedionSpeedLTR) - 1.0) * 0.5 + 0.5;
    }
    
    // Apply cubic ease-in-out
    float t = linearTime; // * linearTime * (3.0 - 2.0 * linearTime); // Cubic ease-in-out
    
    // Use eased time in the animation
    float leftToRightTime = t;

    float dist = length(cellUV);
    float sizeT = clamp( ((leftToRightTime + (0.5/gridSize)) * (gridSize+1.0)) - (gridUV.x * grad * grad), 0.0, 1.0);
    float smallSize = minDotSize;// dotSize * 0.5 * 0.1;
    float maxSize = dotSize * 0.5;
    float radius = mix(smallSize, maxSize, sizeT); // grows from 0 to 0.1 (dotSize * 0.5); //
    float dot = smoothstep(radius, radius - borderStep, dist);
    
    return float4(dot, dot, dot, dot);
}
