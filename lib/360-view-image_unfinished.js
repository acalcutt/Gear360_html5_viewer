import * as THREE from './three.module.js';

var camera, scene, renderer, mesh;

var container = document.getElementById('container');
var image_elem = document.getElementById("image");
var image_src = image_elem.src;
var image_width = image_elem.naturalWidth;
var image_height = image_elem.naturalHeight;
var image_height_half = (image_height * .996) / 2;
var image_width_1quarter = image_width / 4;
var image_width_3quarter = image_width_1quarter * 3;
console.log(image_width);
console.log(image_height);
console.log(image_height_half);
console.log(image_width_1quarter);
console.log(image_width_3quarter);

var canvas = document.getElementById("360canvas");

var zoom_range = document.getElementById('zoom_range');
var zoom_range_default = zoom_range.value;
var x_view = document.getElementById('x_view');
var x_view_default = x_view.value;
var y_view = document.getElementById('y_view');
var y_view_default = y_view.value;
var z_view = document.getElementById('z_view');
var z_view_default = z_view.value;

var width = $("#content").width();
var height = $("#content").height();

var isUserInteracting = false,
    onMouseDownMouseX = 0, onMouseDownMouseY = 0,
    lon = 0, onMouseDownLon = 0,
    lat = 0, onMouseDownLat = 0,
    phi = 0, theta = 0,
    _touchZoomDistanceEnd = 0, _touchZoomDistanceStart = 0;

init();
renderLoop();

function init() {
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(75, width / height, 1, 1100);
    camera.target = new THREE.Vector3(0, 0, 0);

    renderer = new THREE.WebGLRenderer({ 
        canvas: canvas,
        antialias: true 
    });
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(width, height);

    const textureLoader = new THREE.TextureLoader();
    textureLoader.load(image_src, function(texture) {
        texture.generateMipmaps = false;
        texture.minFilter = THREE.LinearFilter;
        texture.magFilter = THREE.LinearFilter;
        texture.format = THREE.RGBAFormat;
        texture.needsUpdate = true;

        const geometry = new THREE.SphereGeometry(100, 64, 64);
        geometry.scale(-1, 1, 1);

        const vertices = geometry.attributes.position.array;
        const normals = geometry.attributes.normal.array;
        const uvAttribute = geometry.getAttribute('uv');
        const uvArray = uvAttribute.array;

        // Radial mapping parameters
        const centerOffset = 0.5;
        const radialScale = 0.8;

        for (let i = 0; i < normals.length; i += 3) {
            const nx = normals[i];
            const ny = normals[i + 1];
            const nz = normals[i + 2];

            const uvIndex = (i / 3) * 2;

            // Calculate spherical coordinates
            const theta = Math.atan2(nz, nx);
            const phi = Math.acos(ny);

            // Convert to radial coordinates
            let u, v;

            if (ny >= 0) {
                // Upper hemisphere
                const r = phi / Math.PI;
                const angle = (theta + Math.PI) / (2 * Math.PI);
                
                // Calculate radial distortion
                const distortedR = Math.pow(r, radialScale);
                
                u = distortedR * Math.cos(angle * 2 * Math.PI) * 0.25 + centerOffset;
                v = distortedR * Math.sin(angle * 2 * Math.PI) * 0.25 + centerOffset;
                
                // Map to first image quadrant
                u = u * (image_width_1quarter / image_width) + (image_width_1quarter / image_width);
                v = v * image_height_half / image_height;
            } else {
                // Lower hemisphere
                const r = (Math.PI - phi) / Math.PI;
                const angle = (theta + Math.PI) / (2 * Math.PI);
                
                // Calculate radial distortion
                const distortedR = Math.pow(r, radialScale);
                
                u = distortedR * Math.cos(angle * 2 * Math.PI) * 0.25 + centerOffset;
                v = distortedR * Math.sin(angle * 2 * Math.PI) * 0.25 + centerOffset;
                
                // Map to second image quadrant
                u = u * (image_width_1quarter / image_width) + (3 * image_width_1quarter / image_width);
                v = v * image_height_half / image_height;
            }

            uvArray[uvIndex] = u;
            uvArray[uvIndex + 1] = v;
        }

        uvAttribute.needsUpdate = true;

        geometry.rotateZ(90 * Math.PI / 180);
        geometry.rotateX(270 * Math.PI / 180);

        const material = new THREE.MeshBasicMaterial({
            map: texture,
            side: THREE.DoubleSide
        });

        mesh = new THREE.Mesh(geometry, material);
        scene.add(mesh);

        mesh.rotation.x = x_view_default * (Math.PI / 180);
        mesh.rotation.y = y_view_default * (Math.PI / 180);
        mesh.rotation.z = z_view_default * (Math.PI / 180);

        camera.zoom = THREE.MathUtils.clamp(zoom_range_default, 0.4, 3);
        camera.updateProjectionMatrix();
    });

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
	camera.zoom = THREE.MathUtils.clamp( zoom, .4, 3 );
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
