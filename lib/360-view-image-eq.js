import * as THREE from './three.module.js';

var camera, scene, renderer, mesh;

var container = document.getElementById( 'container' );
var canvas = document.getElementById("360canvas");
var image = document.getElementById("image"); // Get the image element

var width = $("#content").width();
var height = $("#content").height();

var zoom_range = document.getElementById('zoom_range');
var x_view = document.getElementById('x_view');
var y_view = document.getElementById('y_view');
var z_view = document.getElementById('z_view');

var isUserInteracting = false,
    onMouseDownMouseX = 0, onMouseDownMouseY = 0,
    lon = 0, onMouseDownLon = 0,
    lat = 0, onMouseDownLat = 0,
    phi = 0, theta = 0,
    onPointerDownMouseX = 0,  // Add these declarations
    onPointerDownMouseY = 0,  // Add these declarations
    onPointerDownLon = 0,     // Add these declarations
    onPointerDownLat = 0;     // Add these declarations

init();
animate();

function init() {

    camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 1, 1100 );
    camera.target = new THREE.Vector3( 0, 0, 0 );

    scene = new THREE.Scene();

    const texture = new THREE.TextureLoader().load( image.src ); // Load the image from <img>
    const geometry = new THREE.SphereGeometry( 500, 60, 40 );
    geometry.scale( - 1, 1, 1 );

    const material = new THREE.MeshBasicMaterial( { map: texture } );

    mesh = new THREE.Mesh( geometry, material );
    scene.add( mesh );

    renderer = new THREE.WebGLRenderer({ canvas: canvas });
    renderer.setPixelRatio( window.devicePixelRatio );
    renderer.setSize( width, height );
    container.appendChild( renderer.domElement );

    container.addEventListener( 'mousedown', onPointerStart );
    container.addEventListener( 'mousemove', onPointerMove );
    container.addEventListener( 'mouseup', onPointerUp );

    container.addEventListener( 'wheel', onDocumentMouseWheel );

    container.addEventListener( 'touchstart', onPointerStart );
    container.addEventListener( 'touchmove', onPointerMove );
    container.addEventListener( 'touchend', onPointerUp );

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

    onPointerDownMouseX = event.clientX;
    onPointerDownMouseY = event.clientY;

    onPointerDownLon = lon;
    onPointerDownLat = lat;

}

function onPointerMove( event ) {

    if ( isUserInteracting === true ) {

        lon = ( onPointerDownMouseX - event.clientX ) * 0.1 + onPointerDownLon;
        lat = ( event.clientY - onPointerDownMouseY ) * 0.1 + onPointerDownLat;

        // Update the slider values, but only Y and Z should be updated from mouse
        y_view.value = Math.round(lon);    // Update Y (longitude) slider
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

    const fov = camera.fov + event.deltaY * 0.05;

    camera.fov = THREE.MathUtils.clamp( fov, 10, 75 );

    camera.updateProjectionMatrix();

}

function animate() {

    requestAnimationFrame( animate );
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
