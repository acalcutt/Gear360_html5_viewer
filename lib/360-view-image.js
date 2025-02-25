import * as THREE from './three.module.js';

// Configuration
const isEquirectangular = window.isEquirectangular || false; // Default to false if not defined

// Common Variables
var camera, scene, renderer, mesh;
var container = document.getElementById('container');
var canvas = document.getElementById("360canvas");
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
	history.replaceState(null, '', newURL);
}

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

	// Set up camera
	var fov = 75;
	var aspect = width / height;
	var near = 1;
	var far = 1100;
	camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
	camera.target = new THREE.Vector3(0, 0, 0);

	// Set up scene
	scene = new THREE.Scene();

	// Create texture
	const texture = new THREE.TextureLoader().load(image_src);
	texture.colorSpace = THREE.SRGBColorSpace;

	if (isEquirectangular) {
		const material = new THREE.MeshBasicMaterial({
			map: texture,
		});

		// Create geometry and material
		const geometry = new THREE.SphereGeometry(5, 60, 40);
		geometry.scale(-1, 1, 1);

		mesh = new THREE.Mesh(geometry, material);
		scene.add(mesh);
	} else { // Gear360 Dual Fisheye
		const material = new THREE.MeshBasicMaterial({
			map: texture,
			side: THREE.BackSide,
		});

		// Create geometry and material
		const geometry = new THREE.SphereGeometry(
			5,
			60,
			40,
			0,
			Math.PI * 2,
			0,
			Math.PI * 0.5
		);

		const geometryR = new THREE.SphereGeometry(
			5,
			60,
			40,
			0,
			Math.PI * 2,
			Math.PI * 0.5,
			Math.PI * 0.5
		);

		let fixProjection = (geometry, left) => {
			const uvAttribute = geometry.getAttribute('uv');
			const uvArray = uvAttribute.array;
			const positions = geometry.getAttribute('position').array;
			const normals = geometry.getAttribute('normal').array;

			for (let i = 0; i < positions.length; i += 3) {
				const x = normals[i];
				const y = normals[i + 1];
				const z = normals[i + 2];

				const uvIndex = (i / 3) * 2;

				//		if (y > 0)
				if (left) {
					// Front hemisphere (y > 0)
					const correction =
					x === 0 && z === 0
						? 1
						: (Math.acos(y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
					uvArray[uvIndex] = x * (444 / 1920) * correction + 480 / 1920;
					uvArray[uvIndex + 1] = z * (444 / 1080) * correction + 600 / 1080;
				} else {
					// Back hemisphere (y <= 0)
					const correction =
					x === 0 && z === 0
						? 1
						: (Math.acos(-y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
					uvArray[uvIndex] = -x * (444 / 1920) * correction + 1440 / 1920;
					uvArray[uvIndex + 1] = z * (444 / 1080) * correction + 600 / 1080;
				}
			}

			uvAttribute.needsUpdate = true;

			// Rotate the geometry to align with the video
			geometry.rotateZ((90 * Math.PI) / 180); // Rotate 90 degrees around the Z-axis
			geometry.rotateX((270 * Math.PI) / 180); // Rotate 270 degrees around the X-axis
		};

		fixProjection(geometry, true);
		fixProjection(geometryR, false);

		let mesh1 = new THREE.Mesh(geometryR, material);
		scene.add(mesh1);
		mesh = new THREE.Mesh(geometry, material);
		scene.add(mesh);
	}

	renderer = new THREE.WebGLRenderer({
		canvas: canvas
	});
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(width, height);
	container.appendChild(renderer.domElement);

	// Load defaults from the DOM
	initialLon = parseFloat(y_view.value);
	initialLat = parseFloat(z_view.value);
	initialXView = parseFloat(x_view.value);

	// Set rotation of the mesh
	mesh.rotation.x = initialXView * (Math.PI / 180);

	// Set absolute lon and lat
	absoluteLon = initialLon;
	absoluteLat = initialLat;
	lon = initialLon;
	lat = initialLat;

	// Set the zoom
	camera.zoom = parseFloat(zoom_range.value);
	camera.updateProjectionMatrix();

	UpdateView();
	updateURL();

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

// Update X rotation
function UpdateX() {
	var new_x = this.value;
	mesh.rotation.x = new_x * (Math.PI / 180);
	$("#default_x_view_label").text(new_x + "°");
	updateURL();
}

// Update Y rotation
function UpdateY() {
	absoluteLon = parseFloat(this.value);
	UpdateView();
	updateURL();
}

// Update Z rotation
function UpdateZ() {
	absoluteLat = parseFloat(this.value);
	UpdateView();
	updateURL();
}

// Update Zoom
function UpdateZoom() {
	var zoom = this.value;
	camera.zoom = THREE.MathUtils.clamp(zoom, .4, 3);
	camera.updateProjectionMatrix();
	$("#zoom_range_label").text(zoom + "x");
	updateURL();
}

// Handle window resize
function onWindowResize() {
	width = $("#container").width();
	height = $("#container").height();
	camera.aspect = width / height;
	camera.updateProjectionMatrix();
	renderer.setSize(width, height);
	renderLoop();
}

window.onWindowResize = onWindowResize;

// Touch event handlers
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
				camera.zoom = THREE.MathUtils.clamp(zoom, .4, 3);
				camera.updateProjectionMatrix();
				break;
		}
	}
}

// Mouse/pointer event handlers
function onPointerStart(event) {
	isUserInteracting = true;

	var clientX = event.clientX || event.touches[0].clientX;
	var clientY = event.clientY || event.touches[0].clientY;

	onMouseDownMouseX = clientX;
	onMouseDownMouseY = clientY;

	onMouseDownLon = absoluteLon;
	onMouseDownLat = absoluteLat;
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

// Mouse wheel event handler
function onDocumentMouseWheel(event) {
	var fov = camera.fov + event.deltaY * 0.05;
	camera.fov = THREE.MathUtils.clamp(fov, 10, 75);
	camera.updateProjectionMatrix();
}

// Render loop
function renderLoop() {
	requestAnimationFrame(renderLoop);
	update();
}

// Update function
function update() {
	lon = absoluteLon;
	lat = absoluteLat;

	phi = THREE.MathUtils.degToRad(90 - lat);
	theta = THREE.MathUtils.degToRad(lon);

	camera.target.x = 500 * Math.sin(phi) * Math.cos(theta);
	camera.target.y = 500 * Math.cos(phi);
	camera.target.z = 500 * Math.sin(phi) * Math.sin(theta);

	camera.lookAt(camera.target);

	renderer.render(scene, camera);
}

// Update the view based on lon and lat
function UpdateView() {
	if (absoluteLon < -180 || absoluteLon > 180) {
		absoluteLon = THREE.MathUtils.euclideanModulo(absoluteLon + 180, 360) - 180;
	}

	absoluteLat = Math.max(-90, Math.min(90, absoluteLat));

	y_view.value = absoluteLon;
	z_view.value = absoluteLat;

	$("#default_y_view_label").text(Math.round(absoluteLon) + "°");
	$("#default_z_view_label").text(Math.round(absoluteLat) + "°");
}
