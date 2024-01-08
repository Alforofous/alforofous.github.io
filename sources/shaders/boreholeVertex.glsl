#define LAMBERT

attribute float highlight;
attribute float instanceHeight;
attribute vec4 instanceSectionStart;
attribute vec4 instanceSectionSize;

out float vHighlight;
out vec3 vViewPosition;
out vec2 vUv;
out vec3 vPosition;
out vec4 vSectionStart;
out vec4 vSectionSize;

#include <common>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

void main()
{
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	vHighlight = highlight;
	vPosition = position;
	vUv = uv;
	vSectionStart = instanceSectionStart;
	vSectionSize = instanceSectionSize;
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = -mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
	vec3 newPosition = position;
	newPosition.y *= instanceHeight;
	gl_Position = projectionMatrix * modelViewMatrix * instanceMatrix * vec4(newPosition, 1.0);
}