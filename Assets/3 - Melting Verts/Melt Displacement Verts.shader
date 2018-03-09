Shader "Custom/3 - Melt Verts/Base" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_MeltY("Melt Y", Float) = 0.0
		_MeltDistance("Melt Distance", Float) = 1.0
		_MeltCurve("Melt Curve", Range(1.0,10.0)) = 2.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow

		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// world y values below this are fully melted
		half _MeltY;

		// values within this distance of the _MeltY value are melted
		half _MeltDistance;

		// controls the shape of the melt. (melt ^ curve)
		half _MeltCurve;

		float4 getNewVertPosition( float4 objectSpacePosition, float3 objectSpaceNormal )
		{
			float4 worldSpacePosition = mul( unity_ObjectToWorld, objectSpacePosition );

			// we need to find the normal of the vertex in world space to know which way to push the verts
			// need to make normal a float4. opengl/metal wont build with mul(float4x4, float3)
			float4 worldSpaceNormal   = mul( unity_ObjectToWorld, float4(objectSpaceNormal,0) );

			// we have a 'melt' value, but it's actually the reverse of what we want
			// also it will affect verts above the distance we melt by sucking them in (because it's negative)
			float melt = ( worldSpacePosition.y - _MeltY ) / _MeltDistance;

			// saturate is like Clamp01, giving us a nice value between 0 and 1,
			// then we flip it so it's greater the closer to the floor
			melt = 1 - saturate( melt );

			// will take the linear 0 - 1 value of the melt and give it a nice curve
			melt = pow( melt, _MeltCurve );

			// push the vert out forwards and sideways by how much 'melt' is
			worldSpacePosition.xz += worldSpaceNormal.xz * melt;

			// all that's left now is to update the actual vertex data that's sent to the surf function
			// we take our modified world space vert and put it back into object space
			return mul( unity_WorldToObject, worldSpacePosition );
		}

		void vert( inout appdata_full v )
		{
			float4 vertPosition = getNewVertPosition( v.vertex, v.normal );

			// calculate the bitangent (sometimes called binormal) from the cross product of the normal and the tangent
			float4 bitangent = float4( cross( v.normal, v.tangent ), 0 );

			// how far we want to offset our vert position to calculate the new normal
			float vertOffset = 0.01;

			float4 v1 = getNewVertPosition( v.vertex + v.tangent * vertOffset, v.normal );
			float4 v2 = getNewVertPosition( v.vertex + bitangent * vertOffset, v.normal );

			// now we can create new tangents and bitangents based on the deformed positions
			float4 newTangent = v1 - vertPosition;
			float4 newBitangent = v2 - vertPosition;

			// recalculate the normal based on the new tangent & bitangent
			v.normal = cross( newTangent, newBitangent );

			v.vertex = vertPosition;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
