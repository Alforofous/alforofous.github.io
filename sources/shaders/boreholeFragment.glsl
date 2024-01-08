#define LAMBERT
#define MAX_SECTIONS_PER_BOREHOLE 4.0
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
uniform sampler2D uBoreholeIdTexture;
uniform sampler2D uSectionsColorTexture;
uniform vec2 uResolution;
uniform float instanceCount;
uniform uint instanceID;

in float vHighlight;
in vec2 vUv;
in vec3 vPosition;
in vec4 vSectionStart;
in vec4 vSectionSize;

#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>

vec4 getInstanceSectionColor(float instanceId, float sectionIndex)
{
	vec2 uv = vec2(instanceId / float(instanceCount), sectionIndex / float(MAX_SECTIONS_PER_BOREHOLE));
	vec4 color = texture2D(uSectionsColorTexture, uv);
	//color = vec4((sectionIndex + 1.0) / MAX_SECTIONS_PER_BOREHOLE) * 255.0, 0.0, 0.0, 255.0;
	return color;
}

float grayscale(vec3 color)
{
	return (color.r + color.g + color.b) / 3.0;
}

vec3 sobelEdgeDetection(sampler2D image, vec2 uv, vec2 resolution, float scaleFactor)
{
	vec2 texel = vec2(1.0) / resolution;

	float n[9];
	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 offset = vec2(float(i), float(j)) * texel;
			vec3 color = texture2D(image, uv + offset).rgb;
			n[(i + 1) * 3 + (j + 1)] = grayscale(color);
		}
	}

	float sobel_edge_h = n[2] + 2.0 * n[5] + n[8] - n[0] - 2.0 * n[3] - n[6];
	float sobel_edge_v = n[0] + 2.0 * n[1] + n[2] - n[6] - 2.0 * n[7] - n[8];
	float sobel = sqrt(sobel_edge_h * sobel_edge_h + sobel_edge_v * sobel_edge_v);

	return vec3(sobel * scaleFactor);
}

vec4 getSectionColor()
{
	vec4 diffuseColor = vec4(diffuse, opacity);
	vec4 sectionEnd = vSectionStart + vSectionSize;
	vec3 position = vPosition + vec3(0.0, 0.5, 0.0);
	if (position.y >= vSectionStart.x && position.y <= sectionEnd.x)
		diffuseColor = getInstanceSectionColor(float(instanceID), 0.0);
	else if (position.y >= vSectionStart.y && position.y <= sectionEnd.y)
		diffuseColor = getInstanceSectionColor(float(instanceID), 1.0);
	else if (position.y >= vSectionStart.z && position.y <= sectionEnd.z)
		diffuseColor = getInstanceSectionColor(float(instanceID), 2.0);
	else if (position.y >= vSectionStart.w && position.y <= sectionEnd.w)
		diffuseColor = getInstanceSectionColor(float(instanceID), 3.0);
	diffuseColor /= 255.0;
	return diffuseColor;
}

void main()
{
	#include <clipping_planes_fragment>
	vec4 diffuseColor = getSectionColor();
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
	vec2 uv = gl_FragCoord.xy / uResolution;
	
	vec3 color = sobelEdgeDetection(uBoreholeIdTexture, uv, uResolution, 1000.0);

	if (dot(color, vec3(1.0)) < 0.9)
	{
		color = gl_FragColor.rgb;
	}
	gl_FragColor = vec4(mix(gl_FragColor.rgb, color, vHighlight), gl_FragColor.a);
}