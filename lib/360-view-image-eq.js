import * as THREE from './three.module.js';

var camera, scene, renderer, mesh;

var container = document.getElementById( 'container' );
var canvas = document.getElementById("360canvas");
var width = $("#content").width();
var height = $("#content").height();

var zoom_range = document.getElementById('zoom_range');
var x_view = document.getElementById('default_x_view');
var y_view = document.getElementById('default_y_view');
var z_view = document.getElementById('default_z_view');

var isUserInteracting = false,
	onMouseDownMouseX = 0, onMouseDownMouseY = 0,
	lon = 0, onMouseDownLon = 0,
	lat = 0, onMouseDownLat = 0,
	phi = 0, theta = 0,
	onPointerDownMouseX = 0,  // Add these declarations
	onPointerDownMouseY = 0,  // Add these declarations
	onPointerDownLon = 0,	 // Add these declarations
	onPointerDownLat = 0;	 // Add these declarations

var image_elem = document.getElementById("image");
var image_src = image_elem.src;
image_elem.onload = function() {
	console.log("Image loaded, initializing Three.js");
	init(image_elem); // Pass the EXISTING image element to the init function
	renderLoop();
};
image_elem.src = image_src;
if (image_elem.complete) {
	// Image might have already been in the cache *before* we changed the src
	console.log("Image already in cache, initializing Three.js");
	init(image_elem);
	renderLoop();
}

function init(image_elem) {

	scene = new THREE.Scene();

	var fov	= 75;
	var aspect = width / height;
	var near   = 1;
	var far	= 1100;
	camera = new THREE.PerspectiveCamera( fov, aspect, near, far );
	camera.target = new THREE.Vector3( 0, 0, 0 );

	var geometry = new THREE.SphereGeometry(100, 32, 32, 0);
	
	const texture = new THREE.TextureLoader().load( image_elem.src );
	texture.minFilter = THREE.LinearFilter;
	texture.magFilter = THREE.LinearFilter;

	const uniforms = {
		tDiffuse: { value: texture },
		contrast: { value: 1.0 },  // Adjust this: > 1 increases contrast
		brightness: { value: 0.0 }, // Adjust this:  -1 to 1 range
		blackPoint: {value: 0.0},  // Adjust this: 0 to 1 range.  Higher values darken blacks
		whitePoint: {value: 1.0},	// Adjust this: 0 to 1 range.  Lower values brighten whites
		redBrightness:   { value: 0.0 },  // Adjust this:  -1 to 1,  negative to darken
		greenBrightness: { value: 0.0 },  // Adjust this:  -1 to 1
		blueBrightness:  { value: 0.0 }   // Adjust this:  -1 to 1
	};

	const fragmentShader = `
		uniform sampler2D tDiffuse;
		uniform float contrast;
		uniform float brightness;
		uniform float blackPoint;
		uniform float whitePoint;
		uniform float redBrightness;   // New: Red channel brightness
		uniform float greenBrightness; // New: Green channel brightness
		uniform float blueBrightness;  // New: Blue channel brightness
		varying vec2 vUv;

		void main() {
			vec2 flippedUv = vec2(1.0 - vUv.x, vUv.y);  // Flip U coordinate

			vec4 texel = texture2D( tDiffuse, flippedUv );

			// Adjust brightness for each channel
			texel.r += brightness + redBrightness;
			texel.g += brightness + greenBrightness;
			texel.b += brightness + blueBrightness;

			// Adjust the levels: Map the original range [blackPoint, whitePoint] to [0, 1]
			texel.rgb = (texel.rgb - vec3(blackPoint)) / (vec3(whitePoint - blackPoint));
			texel.rgb = clamp(texel.rgb, 0.0, 1.0);


			// Apply contrast
			texel.rgb = (texel.rgb - 0.5) * contrast + 0.5;
			texel.rgb = clamp(texel.rgb, 0.0, 1.0);

			gl_FragColor = texel;
		}
	`;

	const vertexShader = `
	varying vec2 vUv;
	void main() {
		vUv = uv;
		gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
	}
	`;
	const material = new THREE.ShaderMaterial( {
		uniforms: uniforms,
		fragmentShader: fragmentShader,
		vertexShader: vertexShader,
		side: THREE.BackSide // Ensure inside the sphere is visible
	} );


	mesh = new THREE.Mesh( geometry, material );
	scene.add( mesh );


	renderer = new THREE.WebGLRenderer({ canvas: canvas });
	renderer.toneMapping = THREE.ACESFilmicToneMapping;
	renderer.toneMappingExposure = .5; // Adjust this value.  Lower values darken, higher brighten.
	renderer.outputEncoding = THREE.sRGBEncoding; // Necessary for the tone mapping to actually work.
	renderer.setPixelRatio( window.devicePixelRatio );
	renderer.setSize( width, height );
	container.appendChild( renderer.domElement );

	canvas.addEventListener( 'mousedown', onPointerStart, false );
	canvas.addEventListener( 'mousemove', onPointerMove, false );
	canvas.addEventListener( 'mouseup', onPointerUp, false );

	canvas.addEventListener( 'wheel', onDocumentMouseWheel, false );

	canvas.addEventListener( 'touchstart', touchstart, false );
	canvas.addEventListener( 'touchmove', touchmove, false );
	canvas.addEventListener( 'touchend', onPointerUp, false );

	document.addEventListener( 'keydown', onDocumentKeyDown );

	zoom_range.addEventListener('change', UpdateZoom);
	zoom_range.addEventListener('input', UpdateZoom);
	x_view.addEventListener('change', UpdateX);
	x_view.addEventListener('input', UpdateX);
	y_view.addEventListener('change', UpdateY);
	y_view.addEventListener('input', UpdateY);
	z_view.addEventListener('change', UpdateZ);
	z_view.addEventListener('input', UpdateZ);

	//

	window.addEventListener( 'resize', onWindowResize );

}

function onWindowResize() {

	camera.aspect = window.innerWidth / window.innerHeight;
	camera.updateProjectionMatrix();

	renderer.setSize( window.innerWidth, window.innerHeight );

}

function onDocumentKeyDown( event ) {

	const keyCode = event.code;

	// console.log(keyCode);

}

function onPointerStart( event ) {
	isUserInteracting = true;

	var clientX = event.clientX || event.touches[ 0 ].clientX;
	var clientY = event.clientY || event.touches[ 0 ].clientY;

	onMouseDownMouseX = clientX;
	onMouseDownMouseY = clientY;

	onMouseDownLon = lon;
	onMouseDownLat = lat;
}

function onPointerMove( event ) {
	if ( isUserInteracting === true ) {
		var clientX = event.clientX || event.touches[ 0 ].clientX;
		var clientY = event.clientY || event.touches[ 0 ].clientY;

		lon = ( onMouseDownMouseX - clientX ) * 0.1 + onMouseDownLon;
		lat = ( clientY - onMouseDownMouseY ) * 0.1 + onMouseDownLat;
	}
}

function onPointerUp() {
	isUserInteracting = false;
}

function onDocumentMouseWheel( event ) {
	var fov = camera.fov + event.deltaY * 0.05;
	camera.fov = THREE.Math.clamp( fov, 10, 75 );
	camera.updateProjectionMatrix();
}

function touchstart( event ) {
	isUserInteracting = true;
	switch ( event.touches.length )
	{
		case 1:
			onPointerStart( event );
			break;
		case 2:
			var dx = event.touches[ 0 ].pageX - event.touches[ 1 ].pageX;
			var dy = event.touches[ 0 ].pageY - event.touches[ 1 ].pageY;
			_touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt( dx * dx + dy * dy );
			break;
	}
}

function touchmove( event ) {
	if ( isUserInteracting === true ) {
		event.preventDefault();
		event.stopPropagation();
		switch ( event.touches.length ) 
		{
			case 1:
				onPointerMove( event );
				break;
			case 2:
				var dx = event.touches[ 0 ].pageX - event.touches[ 1 ].pageX;
				var dy = event.touches[ 0 ].pageY - event.touches[ 1 ].pageY;
				_touchZoomDistanceEnd = Math.sqrt( dx * dx + dy * dy );
				
				var _Change = _touchZoomDistanceEnd - _touchZoomDistanceStart;
				var zoom = camera.zoom + _Change * 0.000075;
				camera.zoom = THREE.Math.clamp( zoom, .4, 3 );
				camera.updateProjectionMatrix();
				break;
		}
	}
}

function renderLoop() {

	requestAnimationFrame( renderLoop );
	update();

}

function update() {

	lat = Math.max( - 85, Math.min( 85, lat ) );
	phi = THREE.MathUtils.degToRad( 90 - lat );
	theta = THREE.MathUtils.degToRad( lon );

	// Calculate the base target vector using latitude and longitude
	const targetX = 500 * Math.sin( phi ) * Math.cos( theta );
	const targetY = 500 * Math.cos( phi );
	const targetZ = 500 * Math.sin( phi ) * Math.sin( theta );

	// Apply the rotation from the Rotate slider (around the Z-axis)
	const rotationMatrix = new THREE.Matrix4().makeRotationZ(mesh.rotation.z);
	const rotatedTarget = new THREE.Vector3(targetX, targetY, targetZ).applyMatrix4(rotationMatrix);

	camera.target.x = rotatedTarget.x;
	camera.target.y = rotatedTarget.y;
	camera.target.z = rotatedTarget.z;

	camera.lookAt( camera.target );

	renderer.render( scene, camera );

}

function UpdateZoom() {
	var zoom = parseFloat(zoom_range.value); // Get the slider value as a number

	// Adjust the formula to allow zooming out more
	// Experiment with these values to find the desired zoom range
	var baseFOV = 90;  // Increased base FOV for wider view
	var newFOV = baseFOV / zoom;

	// Adjust the clamp values to allow more zoom out
	var minFOV = 5;   // Reduced minimum FOV for more zoom in
	var maxFOV = 120;  // Increased maximum FOV for more zoom out

	camera.fov = THREE.MathUtils.clamp( newFOV, minFOV, maxFOV );  // Clamp FOV within new limits
	camera.updateProjectionMatrix(); // Update the camera's projection

	$("#zoom_range_label").text(zoom.toFixed(1) + "x"); // Update label (optional)
}

function UpdateX() {
	var new_x = parseFloat(x_view.value);
	// Convert degrees to radians for rotation around the Z-axis
	mesh.rotation.z = THREE.MathUtils.degToRad(new_x);
	$("#default_x_view_label").text(Math.round(new_x) + "°"); // Round x value
}

function UpdateY() {
	var new_y = parseFloat(y_view.value);
	lon = new_y;
	$("#default_y_view_label").text(Math.round(new_y) + "°"); // Round y value
}

function UpdateZ() {
	var new_z = parseFloat(z_view.value); // Get the slider value as a number

	// Convert the slider value to degrees and update the latitude
	lat = new_z;  // Directly set latitude to the slider value

	$("#default_z_view_label").text(Math.round(new_z) + "°"); // Round z value
}
