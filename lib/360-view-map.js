import * as THREE from './three.module.js';

document.addEventListener('DOMContentLoaded', () => {
    // Three.js Panorama Setup
    let scene, camera, renderer, sphere, mesh;
    const panoramaContainer = document.getElementById('panorama-container');
    const panoramaCanvas = document.getElementById('panorama-canvas');
    const closePanoramaButton = document.getElementById('close-panorama');

    // Get the range elements
    var zoom_range = document.getElementById('zoom_range');
    var x_view = document.getElementById('default_x_view');
    var y_view = document.getElementById('default_y_view');
    var z_view = document.getElementById('default_z_view');

    let width = document.getElementById("content").offsetWidth;
    let height = document.getElementById("content").offsetHeight;
    let isUserInteracting = false,
        onMouseDownMouseX = 0, onMouseDownMouseY = 0,
        lon = 0,
        onMouseDownLon = 0,
        lat = 0,
        onMouseDownLat = 0,
        phi = 0,
        theta = 0,
        _touchZoomDistanceEnd = 0,
        _touchZoomDistanceStart = 0;
    let absoluteLon;
    let absoluteLat;
    let initialLon;
    let initialLat;
    let initialXView;

    let isEquirectangular = window.isEquirectangular || true; // Default to false if not defined


    function initThree(imageUrl) {
        scene = new THREE.Scene();
        camera = new THREE.PerspectiveCamera(75, width / height, 1, 1100); //  near and far
        camera.target = new THREE.Vector3(0, 0, 0);

        renderer = new THREE.WebGLRenderer({ canvas: panoramaCanvas });
        renderer.setSize(width, height);
        renderer.setPixelRatio(window.devicePixelRatio);

        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(imageUrl, (texture) => {
            texture.colorSpace = THREE.SRGBColorSpace; // Important for color accuracy

            let material;
            if (isEquirectangular) {
                material = new THREE.MeshBasicMaterial({
                    map: texture,
                });

                // Create geometry and material
                const geometry = new THREE.SphereGeometry(5, 60, 40);
                geometry.scale(-1, 1, 1);

                mesh = new THREE.Mesh(geometry, material);
                scene.add(mesh);
            } else { // Gear360 Dual Fisheye
                material = new THREE.MeshBasicMaterial({
                    map: texture,
                    side: THREE.BackSide, // Important for dual fisheye
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

            // Load defaults from the DOM
            initialLon = parseFloat(y_view.value);
            initialLat = parseFloat(z_view.value);
            initialXView = parseFloat(x_view.value);

            // Set rotation of the mesh
            //mesh.rotation.x = initialXView * (Math.PI / 180);

            // Set absolute lon and lat
            absoluteLon = initialLon;
            absoluteLat = initialLat;
            lon = initialLon;
            lat = initialLat;

            // Set the zoom
            camera.zoom = parseFloat(zoom_range.value);
            camera.updateProjectionMatrix();

            UpdateView();

            console.log("Attaching touch event listeners"); // Debugging

            // Add event listeners
            panoramaCanvas.addEventListener('mousedown', onPointerStart, false);
            panoramaCanvas.addEventListener('mousemove', onPointerMove, false);
            panoramaCanvas.addEventListener('mouseup', onPointerUp, false);

            panoramaCanvas.addEventListener('wheel', onDocumentMouseWheel, false);

            panoramaCanvas.addEventListener('touchstart', touchstart, false);
            panoramaCanvas.addEventListener('touchmove', touchmove, false);
            panoramaCanvas.addEventListener('touchend', onPointerUp, false);

            zoom_range.addEventListener('change', UpdateZoom);
            zoom_range.addEventListener('input', UpdateZoom);
            x_view.addEventListener('change', UpdateX);
            x_view.addEventListener('input', UpdateX);
            y_view.addEventListener('change', UpdateY);
            y_view.addEventListener('input', UpdateY);
            z_view.addEventListener('change', UpdateZ);
            z_view.addEventListener('input', UpdateZ);

            renderLoop(); // Start the render loop AFTER initialization
        });
    }

    function renderLoop() {
        requestAnimationFrame(renderLoop);
        update();
        renderer.render(scene, camera);
    }

    function showPanorama(imageUrl) {
        console.log("showPanorama called, window.isPanoramaActive =", window.isPanoramaActive); // Debugging

        if (scene) {
            // Clean up existing scene if any
            scene.traverse(function(node) {
                if (node instanceof THREE.Mesh) {
                    node.geometry.dispose();
                    node.material.dispose();
                }
            });
            renderer.dispose();
            scene = null;
            renderer = null;
            sphere = null;
            mesh = null;
        }

        // reset the values for all the views
        zoom_range = document.getElementById('zoom_range');
        x_view = document.getElementById('default_x_view');
        y_view = document.getElementById('default_y_view');
        z_view = document.getElementById('default_z_view');
        width = document.getElementById("content").offsetWidth;
        height = document.getElementById("content").offsetHeight;

        window.isPanoramaActive = true; // Set the flag to true
        panoramaContainer.classList.add('active'); // Add the active class

        // Hide the map
        document.getElementById('map').classList.add('hidden'); // Add 'hidden' to map
		
		document.getElementById('file_controls').classList.remove('hidden'); 
		document.getElementById('all_controls').classList.remove('hidden'); 

        panoramaContainer.style.display = 'block'; // Show the panorama container
        initThree(imageUrl);
    }

    window.showPanorama = showPanorama;

    function hidePanorama() {
        console.log("hidePanorama called, window.isPanoramaActive =", window.isPanoramaActive); // Debugging

        panoramaContainer.style.display = 'none';
        panoramaContainer.classList.remove('active'); // Remove the active class
        window.isPanoramaActive = false; // Set the flag to false

        // Show the map
        document.getElementById('map').classList.remove('hidden'); // Remove 'hidden' from map

		document.getElementById('file_controls').classList.add('hidden'); 
		document.getElementById('all_controls').classList.add('hidden'); 

    }

    closePanoramaButton.addEventListener('click', (event) => {
        console.log("Close button clicked"); // Debugging
        hidePanorama()
    });

    // ---  CONTROL FUNCTIONS (Adapted to check isPanoramaActive) ---

    function UpdateX() {
        if (window.isPanoramaActive) {
            var new_x = this.value;
            mesh.rotation.x = new_x * (Math.PI / 180);
            document.getElementById("default_x_view_label").innerText = new_x + "°";
        }
    }

    function UpdateY() {
        if (window.isPanoramaActive) {
            absoluteLon = parseFloat(this.value);
            UpdateView();
        }
    }

    function UpdateZ() {
        if (window.isPanoramaActive) {
            absoluteLat = parseFloat(this.value);
            UpdateView();
        }
    }

    function UpdateZoom() {
        if (window.isPanoramaActive) {
            var zoom = this.value;
            camera.zoom = THREE.MathUtils.clamp(zoom, .4, 3);
            camera.updateProjectionMatrix();
            document.getElementById("zoom_range_label").innerText = zoom + "x";
        }
    }

    function touchstart(event) {
        if (window.isPanoramaActive) {
            console.log("Touch start event fired"); // Debugging
            event.preventDefault(); // Prevent default browser behavior
            event.stopPropagation(); // Stop event from propagating

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
    }

    function touchmove(event) {
        if (window.isPanoramaActive) {
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
    }

    function onPointerStart(event) {
        if (window.isPanoramaActive) {
            isUserInteracting = true;

            var clientX = event.clientX || event.touches[0].clientX;
            var clientY = event.clientY || event.touches[0].clientY;

            onMouseDownMouseX = clientX;
            onMouseDownMouseY = clientY;

            onMouseDownLon = absoluteLon;
            onMouseDownLat = absoluteLat;
        }
    }

    function onPointerMove(event) {
        if (window.isPanoramaActive) {
            if (isUserInteracting === true) {
                var clientX = event.clientX || event.touches[0].clientX;
                var clientY = event.clientY || event.touches[0].clientY;

                absoluteLon = (onMouseDownMouseX - clientX) * 0.1 + onMouseDownLon;
                absoluteLat = (clientY - onMouseDownMouseY) * 0.1 + onMouseDownLat;

                UpdateView();
            }
        }
    }

    function onPointerUp() {
        if (window.isPanoramaActive) {
            isUserInteracting = false;
        }
    }

    function onDocumentMouseWheel(event) {
        if (window.isPanoramaActive) {
            var fov = camera.fov + event.deltaY * 0.05;
            camera.fov = THREE.MathUtils.clamp(fov, 10, 75);
            camera.updateProjectionMatrix();
        }
    }

    function update() {
        if (!camera || !camera.target || !window.isPanoramaActive) {
            return; // Exit if camera or target is not initialized
        }

        lon = absoluteLon;
        lat = absoluteLat;

        phi = THREE.MathUtils.degToRad(90 - lat);
        theta = THREE.MathUtils.degToRad(lon);

        camera.target.x = 500 * Math.sin(phi) * Math.cos(theta);
        camera.target.y = 500 * Math.cos(phi);
        camera.target.z = 500 * Math.sin(phi) * Math.sin(theta);

        camera.lookAt(camera.target);
    }

    function UpdateView() {
        if (window.isPanoramaActive) {
            if (absoluteLon < -180 || absoluteLon > 180) {
                absoluteLon = THREE.MathUtils.euclideanModulo(absoluteLon + 180, 360) - 180;
            }

            absoluteLat = Math.max(-90, Math.min(90, absoluteLat));

            y_view.value = absoluteLon;
            z_view.value = absoluteLat;

            document.getElementById("default_y_view_label").innerText = Math.round(absoluteLon) + "°";
            document.getElementById("default_z_view_label").innerText = Math.round(absoluteLat) + "°";
        }
    }

    function onWindowResize() {
        let width = document.getElementById("content").offsetWidth;
        let height = document.getElementById("content").offsetHeight;
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        renderer.setSize(width, height);
    }

    window.onWindowResize = onWindowResize;

});
