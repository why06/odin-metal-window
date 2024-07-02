#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

	struct Vertex_Data {
		packed_float4 position;
		packed_float2 texCoord;
	};

vertex VertexOut
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex_Data* vertexData [[buffer(0)]])
{
    VertexOut out;
    out.position = vertexData[vertexID].position;
    out.texCoord = vertexData[vertexID].texCoord;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]], texture2d<float> colorTexture [[texture(0)]]) {
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);

  const float4 colorSample = colorTexture.sample(textureSampler, in.texCoord );
  return colorSample;
}
