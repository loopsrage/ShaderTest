Shader "Custom/4 - Melt Pixels/Hard Edge" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_MeltY("Melt Y", Float) = 0.0
		_MeltDistance("Melt Distance", Float) = 1.0
		_MeltCurve("Melt Curve", Range(1.0,10.0)) = 2.0


		_MeltColor ("Color", Color) = (1,1,1,1)
		_MeltGlossiness ("Smoothness", Range(0,1)) = 0.0
		_MeltMetallic ("Metallic", Range(0,1)) = 0.0
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

			float pixelMelt; // add here to pass data from the vertex shader to the surface shader
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		half _MeltY;
		half _MeltDistance;
		half _MeltCurve;

		// add all the specific 'melt' surface settings
		half _MeltGlossiness;
		half _MeltMetallic;
		fixed4 _MeltColor;

		// add an "out" value. 
		float4 getNewVertPosition( float4 objectSpacePosition, float3 objectSpaceNormal, out float pixelMelt )
		{
			float4 worldSpacePosition = mul( unity_ObjectToWorld, objectSpacePosition );
			float4 worldSpaceNormal   = mul( unity_ObjectToWorld, float4(objectSpaceNormal,0) );

			float melt = ( worldSpacePosition.y - _MeltY ) / _MeltDistance;
			melt = 1 - saturate( melt );

			// set the melt value
			pixelMelt = melt;

			melt = pow( melt, _MeltCurve );

			worldSpacePosition.xz += worldSpaceNormal.xz * melt;

			return mul( unity_WorldToObject, worldSpacePosition );
		}

		void vert( inout appdata_full v, out Input o )
		{
			// once you add custom data to Input and have it as a parameter for your custom vert function
			// it is important that you initialiaze all values correctly. 
			// fortunately Unity has a function that will do that for us until we want full control
			UNITY_INITIALIZE_OUTPUT(Input, o);

			// create the variable to store the melt value
			float pixelMelt = 0.0;
			float4 vertPosition = getNewVertPosition( v.vertex, v.normal, pixelMelt );

			// set here to pass the variable to the surface shader
			o.pixelMelt = pixelMelt;

			float4 bitangent = float4( cross( v.normal, v.tangent ), 0 );

			float vertOffset = 0.01;

			// re-use the pixelMelt value, we have already set the value passed to the surface shader so it's ok
			float4 v1 = getNewVertPosition( v.vertex + v.tangent * vertOffset, v.normal, pixelMelt );
			float4 v2 = getNewVertPosition( v.vertex + bitangent * vertOffset, v.normal, pixelMelt );

			float4 newTangent = v1 - vertPosition;
			float4 newBitangent = v2 - vertPosition;
			v.normal = cross( newTangent, newBitangent );

			v.vertex = vertPosition;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

			// blending between the two properties using the melt value gives us a smooth blend
			// if we want a hard edge, like the model is covered in this new material
			// we can use a 'step' function to take the smooth 0 to 1 value and turn it into
			// binary 0 or 1 value. 

			// this new value will replace the last argument in the lerp methods below
			float hardMelt = step( 0.5, IN.pixelMelt );

			// 'c' controls the color of the surface
			// by default this is the texture tinted by the color
			// we want our melt color to blend into this
			o.Albedo = lerp( c.rgb, _MeltColor.rgb, hardMelt );

			// do the same calcuation to the metallic & smoothness
			o.Metallic = lerp( _Metallic, _MeltMetallic, hardMelt );
			o.Smoothness = lerp( _Glossiness, _MeltGlossiness, hardMelt );

			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
