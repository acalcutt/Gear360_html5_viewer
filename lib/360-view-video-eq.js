import * as THREE from './three.module.js';

var camera, scene, renderer, mesh;
var container = document.getElementById('container');
var video = document.getElementById("video" );
var canvas = document.getElementById("360canvas");

var zoom_range = document.getElementById('zoom_range');
var default_x_view = document.getElementById('default_x_view');
var default_y_view = document.getElementById('default_y_view');
var default_z_view = document.getElementById('default_z_view');

var width = $("#content").width();
var height = $("#content").height();

var isUserInteracting = false,
	onMouseDownMouseX = 0, onMouseDownMouseY = 0,
	lon = 0, onMouseDownLon = 0,
	lat = 0, onMouseDownLat = 0,
	phi = 0, theta = 0,
	onPointerDownMouseX = 0,
	onPointerDownMouseY = 0,
	onPointerDownLon = 0,
	onPointerDownLat = 0;

let _touchZoomDistanceStart = 0;
let _touchZoomDistanceEnd = 0;

init();
renderLoop();

function init() {
	scene = new THREE.Scene();

	// Set up camera at center of sphere
	camera = new THREE.PerspectiveCamera(75, width / height, 1, 1100);
	camera.position.set(0, 0, 0.1); // Place camera slightly offset from center
	camera.target = new THREE.Vector3(0, 0, 0);
	
	var geometry = new THREE.SphereGeometry(100, 32, 32, 0);
	geometry.scale(-1, 1, 1);


	const texture = new THREE.VideoTexture( video );
	texture.colorSpace = THREE.SRGBColorSpace;
	const material = new THREE.MeshBasicMaterial( { map: texture } );

	const mesh = new THREE.Mesh( geometry, material );
	scene.add( mesh );

	renderer = new THREE.WebGLRenderer({ 
		canvas: canvas,
		antialias: true
	});
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(width, height);
	container.appendChild( renderer.domElement );


	// Event listeners
	container.addEventListener('mousedown', onPointerStart, false);
	container.addEventListener('mousemove', onPointerMove, false);
	container.addEventListener('mouseup', onPointerUp, false);
	container.addEventListener('wheel', onDocumentMouseWheel, false);
	container.addEventListener('touchstart', touchstart, false);
	container.addEventListener('touchmove', touchmove, false);
	container.addEventListener('touchend', onPointerUp, false);
	window.addEventListener('resize', onWindowResize, false);

	// Controls event listeners
	zoom_range.addEventListener('change', UpdateZoom);
	zoom_range.addEventListener('input', UpdateZoom);
	default_x_view.addEventListener('change', UpdateX);
	default_x_view.addEventListener('input', UpdateX);
	default_y_view.addEventListener('change', UpdateY);
	default_y_view.addEventListener('input', UpdateY);
	default_z_view.addEventListener('change', UpdateZ);
	default_z_view.addEventListener('input', UpdateZ);

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
	camera.zoom = THREE.MathUtils.clamp( zoom, .4, 3 );
	camera.updateProjectionMatrix();
	$("#zoom_range_label").text(zoom + "x");
}

function onWindowResize() {
	width = $("#content").width();
	height = $("#content").height();
	camera.aspect = width/height;
	camera.updateProjectionMatrix();
	renderer.setSize( width, height );
}

window.onWindowResize = onWindowResize;

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
				camera.zoom = THREE.MathUtils.clamp( zoom, .4, 3 );
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
	}
}

function onPointerUp() {
	isUserInteracting = false;
}

function onDocumentMouseWheel( event ) {
	var fov = camera.fov + event.deltaY * 0.05;
	camera.fov = THREE.MathUtils.clamp( fov, 10, 75 );
	camera.updateProjectionMatrix();
}

function renderLoop() {
	requestAnimationFrame( renderLoop );
	update();
}

function update() {
	lat = Math.max( - 85, Math.min( 85, lat ) );
	phi = THREE.MathUtils.degToRad( 90 - lat );
	theta = THREE.MathUtils.degToRad( lon );

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