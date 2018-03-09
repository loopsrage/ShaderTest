
Shader "Custom/ShaderTest" {
	SubShader {
		Tags {Queue = Transparent}
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 uv3 : TEXCOORD3;
				float4 tan : TANGENT;
				float4 col : COLOR;
				uint vid : SV_VertexID;
				
			};
			struct v2f
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 uv3 : TEXCOORD3;
				float4 tan : TANGENT;
				float4 col : COLOR;
			};
			float4 NewVertex(float4 vt, float f){
				float speed = 1;
				float Half = 0.5;
				int waveHeight = 5;
				// Use f and _Time.y to make it per vertex, otherwise it will behave as follows
				// on vt.y it will cause the whole object to rise and FallBack
				// Adding f (Operator) _Time.y will cause it to have a wave effect
				vt.y += sin(f + _Time.y) + sin(speed * _Time.y) * Half;
				for(int i = 0; i < waveHeight; i++){
					// Increase I for higher waves
					// Add .x or .y to wave over different vertex
					// On a Sphere this will cause a wave down the object
					vt.y += sin(f + speed * _Time.y);
				}
				return vt;
			}
			float3 NewNormal(float3 n, float f){
				n.y += sin(f + _Time.y) + sin(1 * _Time.y) * 0.5;
				n.x += sin(f + _Time.y) + sin(1 * _Time.y) * 0.5;
				n.z += sin(f + _Time.y) + sin(1 * _Time.y) * 0.5;
				return n;
			}
			float4 NewColor(float4 c, float f){
				// Using -= Will color the bottom of a wave
				// Using += Will color the top of the wave
				c.r = 0;
				c.g = 0; //sin(-f + -_Time.y) + sin(-3 * -_Time.y) * 0.1;
				c.b += sin(f + _Time.y) + sin(1 * _Time.y) * 0.1;
				return c;
			}
			float4 NewTangent(float4 t, float f){
				t.y += sin(f + _Time.y) + sin(1 * _Time.y) * 0.5;
				return t;
			}
			float4 NewUV(float4 u, float f)
			{
				u.xy += sin(f + _Time.y) + sin(1 * _Time.y) * 0.1;
				return u;
			}
			v2f vert(appdata v)
			{
				v2f o;
				// Vert ID
				// Vertex Identity allows for moving wave functions 
				float f = (float)v.vid;
				// Vertex Morph
				v.vertex = NewVertex(v.vertex,f);
				// Normal Morph
				v.normal = NewNormal(v.normal,f);
				// UVs
				v.uv = NewUV(v.uv,f);
				// End Uvs
				// tan
				v.tan = NewTangent(v.tan, f);
				//o.col = v.tan * 0.5 + 0.5; // Visualize Tangent
				// COLOR Morph
				o.col =  NewColor(v.col,f); // Base Color
				o.col += v.tan * 0.5; // Color on Tan
				o.col += float4(v.uv.xy * 0.5,0,0); // Color on UV
				o.col.r = 0.1;

				// Applying
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				// Visualize UV
				//  half4 c = frac(i.uv);
				//  if(any(saturate(i.uv) - i.uv))
				//		c.b = 0.5;
				// Color Output
				return i.col;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
