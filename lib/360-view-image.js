import * as THREE from './three.module.js';
var camera, scene, renderer, mesh;

var container = document.getElementById( 'container' );
var canvas = document.getElementById("360canvas");
var zoom_range = document.getElementById('zoom_range');
var zoom_range_default = zoom_range.value;
var x_view = document.getElementById('default_x_view');
var x_view_default = x_view.value;
var y_view = document.getElementById('default_y_view');
var y_view_default = y_view.value;
var z_view = document.getElementById('default_z_view');
var z_view_default = z_view.value;
var width = $("#content").width();
var height = $("#content").height();

var isUserInteracting = false,
onMouseDownMouseX = 0, onMouseDownMouseY = 0,
lon = 0, onMouseDownLon = 0,
lat = 0, onMouseDownLat = 0,
phi = 0, theta = 0,
_touchZoomDistanceEnd = 0, _touchZoomDistanceStart = 0;

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

	var image_width = image_elem.naturalWidth;
	var image_height = image_elem.naturalHeight;
	var image_height_half = (image_height * .996) / 2;
	var image_width_1quarter = image_width / 4;
	var image_width_3quarter = image_width_1quarter * 3;

	var i;

	scene = new THREE.Scene();

	var fov	= 75;
	var aspect = width / height;
	var near   = 1;
	var far	= 1100;
	camera = new THREE.PerspectiveCamera( fov, aspect, near, far );
	camera.target = new THREE.Vector3( 0, 0, 0 );

	renderer = new THREE.WebGLRenderer({ canvas: canvas });
	renderer.setPixelRatio( window.devicePixelRatio );
	renderer.setSize( width, height);
	container.appendChild( renderer.domElement );
	console.log(image_src);
	var texture = new THREE.TextureLoader().load(image_src);
	texture.minFilter = THREE.LinearFilter;
		texture.magFilter = THREE.LinearFilter;
	texture.format = THREE.RGBFormat;
	
	var geometry = new THREE.SphereGeometry(100, 32, 32, 0);
	geometry.scale(-1, 1, 1);

	var maxY = Math.cos(Math.PI * (360 - 75) / 180 / 2);
	var faceVertexUvs = geometry.faceVertexUvs[ 0 ];
	for ( i = 0; i < faceVertexUvs.length; i++ ) {
		var uvs = faceVertexUvs[ i ];
		var face = geometry.faces[ i ];
		for ( var j = 0; j < 3; j ++ ) {
			var x = face.vertexNormals[ j ].x;
			var y = face.vertexNormals[ j ].y;
			var z = face.vertexNormals[ j ].z;

			if (i < faceVertexUvs.length / 2) {
				var correction = (x == 0 && z == 0) ? 1 : (Math.acos(y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
				uvs[ j ].x = x * ((image_width_1quarter * .947) / image_width) * correction + ((image_width_1quarter * .9996) / image_width);
				uvs[ j ].y = z * ((image_width_1quarter * .947) / image_height) * correction + ((image_height_half) / image_height);

			  } else {
				var correction = ( x == 0 && z == 0) ? 1 : (Math.acos(-y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
				uvs[ j ].x = -1 * x * ((image_width_1quarter * .947) / image_width) * correction + ((image_width - (image_width_1quarter *.9996)) / image_width);
				uvs[ j ].y = z * ((image_width_1quarter * .947) / image_height) * correction + ((image_height_half) / image_height);
			}
		}
	}

	geometry.rotateZ(90 * Math.PI / 180);//radians
	geometry.rotateX(270 * Math.PI / 180);

	var material = new THREE.MeshBasicMaterial( { map: texture } );
	mesh = new THREE.Mesh( geometry, material );
	scene.add( mesh );
	
	mesh.rotation.x = x_view_default * (Math.PI/180);
	mesh.rotation.y = y_view_default * (Math.PI/180);
	mesh.rotation.z = z_view_default * (Math.PI/180);
	
	camera.zoom = THREE.Math.clamp( zoom_range_default, .4, 3 );
	camera.updateProjectionMatrix();

	canvas.addEventListener( 'mousedown', onPointerStart, false );
	canvas.addEventListener( 'mousemove', onPointerMove, false );
	canvas.addEventListener( 'mouseup', onPointerUp, false );

	canvas.addEventListener( 'wheel', onDocumentMouseWheel, false );

	canvas.addEventListener( 'touchstart', touchstart, false );
	canvas.addEventListener( 'touchmove', touchmove, false );
	canvas.addEventListener( 'touchend', onPointerUp, false );

	zoom_range.addEventListener('change', UpdateZoom);
	zoom_range.addEventListener('input', UpdateZoom);
	x_view.addEventListener('change', UpdateX);
	x_view.addEventListener('input', UpdateX);
	y_view.addEventListener('change', UpdateY);
	y_view.addEventListener('input', UpdateY);
	z_view.addEventListener('change', UpdateZ);
	z_view.addEventListener('input', UpdateZ);

	//

	canvas.addEventListener( 'dragover', function ( event ) {

		event.preventDefault();
		event.dataTransfer.dropEffect = 'copy';

	}, false );

	canvas.addEventListener( 'dragenter', function () {

		canvas.body.style.opacity = 0.5;

	}, false );

	canvas.addEventListener( 'dragleave', function () {

		canvas.body.style.opacity = 1;

	}, false );

	canvas.addEventListener( 'drop', function ( event ) {

		event.preventDefault();

		var reader = new FileReader();
		reader.addEventListener( 'load', function ( event ) {

			material.map.image.src = event.target.result;
			material.map.needsUpdate = true;

		}, false );
		reader.readAsDataURL( event.dataTransfer.files[ 0 ] );

		canvas.body.style.opacity = 1;

	}, false );

	//

	window.addEventListener( 'resize', onWindowResize, false );

}

function UpdateX() {
	var new_x = this.value;
	mesh.rotation.x = new_x * (Math.PI/180);
	$("#default_x_view_label").text(new_x + "°");
}

function UpdateY() {
	var new_y = this.value;
	mesh.rotation.y = new_y * (Math.PI/180);
	$("#default_y_view_label").text(new_y + "°");
}

function UpdateZ() {
	var new_z = this.value;
	mesh.rotation.z = new_z * (Math.PI/180);
	$("#default_z_view_label").text(new_z + "°");
}

function UpdateZoom() {
	var zoom = this.value;
	camera.zoom = THREE.Math.clamp( zoom, .4, 3 );
	camera.updateProjectionMatrix();
	$("#zoom_range_label").text(zoom + "x");
}



function onWindowResize() {
	width = $("#container").width();
	height = $("#container").height();
	camera.aspect = width/height;
	camera.updateProjectionMatrix();
	renderer.setSize( width, height );
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

		// Update the slider values, but only Y and Z should be updated from mouse
		y_view.value = Math.round(lon);	// Update Y (longitude) slider
		z_view.value = Math.round(lat);  // Update Z (latitude) slider

		// Update the labels (optional)
		$("#default_y_view_label").text(Math.round(lon) + "°");
		$("#default_z_view_label").text(Math.round(lat) + "°");
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

function renderLoop() {
	requestAnimationFrame( renderLoop );
	update();
}

function update() {
	lat = Math.max( - 85, Math.min( 85, lat ) );
	phi = THREE.Math.degToRad( 90 - lat );
	theta = THREE.Math.degToRad( lon );

	camera.target.x = 500 * Math.sin( phi ) * Math.cos( theta );
	camera.target.y = 500 * Math.cos( phi );
	camera.target.z = 500 * Math.sin( phi ) * Math.sin( theta );

	camera.lookAt( camera.target );

	/*
	// distortion
	camera.position.copy( camera.target ).negate();
	*/

	renderer.render( scene, camera );

}