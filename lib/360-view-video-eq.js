import * as THREE from './three.module.js';

var camera, scene, renderer, mesh;

var container = document.getElementById('container');
var canvas = document.getElementById("360canvas");
var video = document.getElementById("video"); // Get the video element
var zoom_range = document.getElementById('zoom_range');
var x_view = document.getElementById('default_x_view');
var y_view = document.getElementById('default_y_view');
var z_view = document.getElementById('default_z_view');

var width = $("#content").width();
var height = $("#content").height();

var isUserInteracting = false,
	onMouseDownMouseX = 0, onMouseDownMouseY = 0,
	lon = 0, onMouseDownLon = 0,
	lat = 0, onMouseDownLat = 0,
	phi = 0, theta = 0,
	_touchZoomDistanceEnd = 0, _touchZoomDistanceStart = 0;

var absoluteLon;
var absoluteLat;
var initialLon;
var initialLat;
var initialXView;

// Function to update the URL with view parameters
function updateURL() {
	const urlParams = new URLSearchParams(window.location.search);
	urlParams.set('x', Math.round(parseFloat(x_view.value)));
	urlParams.set('y', Math.round(parseFloat(y_view.value)));
	urlParams.set('z', Math.round(parseFloat(z_view.value)));
	urlParams.set('zoom', zoom_range.value);

	const newURL = `${window.location.pathname}?${urlParams.toString()}`;
	history.replaceState(null, '', newURL); // Update URL without reload
}

// Wait for the video to load its metadata before initializing Three.js
video.addEventListener('loadeddata', function() {
	console.log("Video loaded, initializing Three.js");
	init(); // Initialize Three.js *after* the video is loaded
	renderLoop();
});

//init();
//renderLoop();

function init() {
	var fov = 75;
	var aspect = width / height;
	var near = 1;
	var far = 1100;
	camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
	camera.target = new THREE.Vector3(0, 0, 0);

	scene = new THREE.Scene();

	const texture = new THREE.VideoTexture( video );
	texture.colorSpace = THREE.SRGBColorSpace;

	const geometry = new THREE.SphereGeometry( 5, 60, 40 );
	geometry.scale( - 1, 1, 1 );

	var material = new THREE.MeshBasicMaterial({ map: texture });
	mesh = new THREE.Mesh(geometry, material); // Assign to the global mesh
	scene.add(mesh);

	renderer = new THREE.WebGLRenderer({ canvas: canvas });
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(width, height);
	container.appendChild(renderer.domElement);

	//Load defaults using the value of the the variable
	initialLon = parseFloat(y_view.value);
	initialLat = parseFloat(z_view.value);
	initialXView = parseFloat(x_view.value);

	// Set rotation of the mesh
	mesh.rotation.x = initialXView * (Math.PI / 180);

	//Set absolute and lat
	absoluteLon = initialLon
	absoluteLat = initialLat;
	lon = initialLon;
	lat = initialLat;

	//Set the zoom
	camera.zoom = parseFloat(zoom_range.value);
	camera.updateProjectionMatrix();

	UpdateView();
	updateURL();

	canvas.addEventListener('mousedown', onPointerStart, false);
	canvas.addEventListener('mousemove', onPointerMove, false);
	canvas.addEventListener('mouseup', onPointerUp, false);

	canvas.addEventListener('wheel', onDocumentMouseWheel, false);

	canvas.addEventListener('touchstart', touchstart, false);
	canvas.addEventListener('touchmove', touchmove, false);
	canvas.addEventListener('touchend', onPointerUp, false);

	zoom_range.addEventListener('change', UpdateZoom);
	zoom_range.addEventListener('input', UpdateZoom);
	x_view.addEventListener('change', UpdateX);
	x_view.addEventListener('input', UpdateX);
	y_view.addEventListener('change', UpdateY);
	y_view.addEventListener('input', UpdateY);
	z_view.addEventListener('change', UpdateZ);
	z_view.addEventListener('input', UpdateZ);

	//

	canvas.addEventListener('dragover', function(event) {

		event.preventDefault();
		event.dataTransfer.dropEffect = 'copy';

	}, false);

	canvas.addEventListener('dragenter', function() {

		canvas.body.style.opacity = 0.5;

	}, false);

	canvas.addEventListener('dragleave', function() {

		canvas.body.style.opacity = 1;

	}, false);

	canvas.addEventListener('drop', function(event) {

		event.preventDefault();

		var reader = new FileReader();
		reader.addEventListener('load', function(event) {

			material.map.image.src = event.target.result;
			material.map.needsUpdate = true;

		}, false);
		reader.readAsDataURL(event.dataTransfer.files[0]);

		canvas.body.style.opacity = 1;

	}, false);

	//

	window.addEventListener('resize', onWindowResize, false);

}

function UpdateX() {
	var new_x = this.value;
	mesh.rotation.x = new_x * (Math.PI / 180);
	$("#default_x_view_label").text(new_x + "°");
	updateURL();
}

function UpdateY() {
	absoluteLon = parseFloat(this.value);
	UpdateView();
	updateURL();
}

function UpdateZ() {
	absoluteLat = parseFloat(this.value);
	UpdateView();
	updateURL();
}

function UpdateZoom() {
	var zoom = this.value;
	camera.zoom = THREE.Math.clamp(zoom, .4, 3);
	camera.updateProjectionMatrix();
	$("#zoom_range_label").text(zoom + "x");
	updateURL();
}

function onWindowResize() {
	width = $("#container").width();
	height = $("#container").height();
	camera.aspect = width / height;
	camera.updateProjectionMatrix();
	renderer.setSize(width, height);
	renderLoop();
}

window.onWindowResize = onWindowResize;

function touchstart(event) {
	isUserInteracting = true;
	switch (event.touches.length) {
		case 1:
			onPointerStart(event);
			break;
		case 2:
			var dx = event.touches[0].pageX - event.touches[1].pageX;
			var dy = event.touches[0].pageY - event.touches[1].pageY;
			_touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt(dx * dx + dy * dy);
			break;
	}
}

function touchmove(event) {
	if (isUserInteracting === true) {
		event.preventDefault();
		event.stopPropagation();
		switch (event.touches.length) {
			case 1:
				onPointerMove(event);
				break;
			case 2:
				var dx = event.touches[0].pageX - event.touches[1].pageX;
				var dy = event.touches[0].pageY - event.touches[1].pageY;
				_touchZoomDistanceEnd = Math.sqrt(dx * dx + dy * dy);

				var _Change = _touchZoomDistanceEnd - _touchZoomDistanceStart;
				var zoom = camera.zoom + _Change * 0.000075;
				camera.zoom = THREE.Math.clamp(zoom, .4, 3);
				camera.updateProjectionMatrix();
				break;
		}
	}
}

function onPointerStart(event) {
	isUserInteracting = true;

	var clientX = event.clientX || event.touches[0].clientX;
	var clientY = event.clientY || event.touches[0].clientY;

	onMouseDownMouseX = clientX;
	onMouseDownMouseY = clientY;

	onMouseDownLon = absoluteLon; // Store the absolute lon
	onMouseDownLat = absoluteLat; // Store the absolute lat
}

function onPointerMove(event) {
	if (isUserInteracting === true) {
		var clientX = event.clientX || event.touches[0].clientX;
		var clientY = event.clientY || event.touches[0].clientY;

		absoluteLon = (onMouseDownMouseX - clientX) * 0.1 + onMouseDownLon;
		absoluteLat = (clientY - onMouseDownMouseY) * 0.1 + onMouseDownLat;

		UpdateView();
		updateURL();
	}
}

function onPointerUp() {
	isUserInteracting = false;
}

function onDocumentMouseWheel(event) {
	var fov = camera.fov + event.deltaY * 0.05;
	camera.fov = THREE.Math.clamp(fov, 10, 75);
	camera.updateProjectionMatrix();
}

function renderLoop() {
	requestAnimationFrame(renderLoop);
	update();
}

function update() {
	lon = absoluteLon;
	lat = absoluteLat;

	phi = THREE.Math.degToRad(90 - lat);
	theta = THREE.Math.degToRad(lon);

	camera.target.x = 500 * Math.sin(phi) * Math.cos(theta);
	camera.target.y = 500 * Math.cos(phi);
	camera.target.z = 500 * Math.sin(phi) * Math.sin(theta);

	camera.lookAt(camera.target);

	/*
	// distortion
	camera.position.copy( camera.target ).negate();
	*/

	renderer.render(scene, camera);
}

function UpdateView() {
	if (absoluteLon < -180 || absoluteLon > 180) {
		absoluteLon = THREE.MathUtils.euclideanModulo(absoluteLon + 180, 360) - 180;
	}

	// Clamp latitude to the valid range of -90 to +90 degrees
	absoluteLat = Math.max(-90, Math.min(90, absoluteLat));

	// Update the slider values, but only Y and Z should be updated from mouse
	y_view.value = absoluteLon;  // Update Y (longitude) slider
	z_view.value = absoluteLat;  // Update Z (latitude) slider

	// Update the labels (optional)
	$("#default_y_view_label").text(Math.round(absoluteLon) + "°");
	$("#default_z_view_label").text(Math.round(absoluteLat) + "°");
}
