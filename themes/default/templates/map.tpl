{include file="header.tpl"}
{include file="menu.tpl"}
<div class="col content" id="content">
    <div id="container" ondragstart="return false;" ondrop="return false;">
        <div id="map" class="map_default"></div>
		<!-- Panorama Container -->
		<div id="panorama-container" class="canvas_default hidden">
			<canvas id="panorama-canvas" style="width: 100%; height: 100%;"></canvas>
			<button id="close-panorama" style="position: absolute; top: 10px; right: 10px; background: white; color: black; border: none; padding: 5px 10px; cursor: pointer;">Close</button>
		</div>

        <menu id="controls">
            <span class="video-icon all_controls"><b>{$title}</b></span>
            <br />
            <span id="iconShowHideMenu" class="video-icon" title="Toggle Menu"><img src="{$theme_dir}images/close-pane-48.png" id="showhidemenubtn1" class="video-button menu_default_visible"/><img src="{$theme_dir}images/open-pane-48.png" id="showhidemenubtn2" class="video-button menu_default_hidden"/></span>
            <span id="iconFullscreen" class="video-icon" title="Full Screen"><img class="video-button" src="{$theme_dir}images/fit-to-width-60.png"></span>
            <span id="file_controls" class="file_controls hidden">
                <span id="iconPreviousFile" class="video-icon" title="Previous File"><img class="video-button" src="{$theme_dir}images/node-up-60.png"></span>
                <span id="iconNextFile" class="video-icon" title="Next File"><img class="video-button" src="{$theme_dir}images/node-down-60.png"></span>
                <span id="iconShowHide" class="video-icon" title="Toggle Controls"><img class="video-button" id="showhidebtn" src="{$theme_dir}images/control-panel-64.png"></span>
            </span>
            <span id="all_controls" class="all_controls hidden">
                <span class="view_controls">
                    <span class="inline nowrap player-btn video-icon">Zoom: <input class="canv_slider" id="zoom_range" type="range" max="3" min=".4" step=".1" value="{$zoom}"><label id="zoom_range_label">{$zoom}x</label></span>
                    <span class="inline nowrap player-btn video-icon">Up/Down: <input class="canv_slider" id="default_z_view" type="range" max="90" min="-90" step="1" value="{$default_z}"><label id="default_z_view_label">{$default_z}°</label></span>
                    <span class="inline nowrap player-btn video-icon">Left/Right: <input class="canv_slider" id="default_y_view" type="range" max="180" min="-180" step="1" value="{$default_y}"><label id="default_y_view_label">{$default_y}°</label></span>
                    <span class="inline nowrap player-btn video-icon">Rotate: <input class="canv_slider" id="default_x_view" type="range" max="360" min="0" step="1" value="{$default_x}"><label id="default_x_view_label">{$default_x}°</label></span>
                </span>
            </span>
        </menu>
    </div>

    <script>
        window.isEquirectangular = {if $isEquirectangular eq 1}true{else}false{/if};
        window.isPanoramaActive = false; // Initialize the flag
    </script>

    <link href="https://unpkg.com/maplibre-gl@latest/dist/maplibre-gl.css" rel="stylesheet" />
    <script src="https://unpkg.com/maplibre-gl@latest/dist/maplibre-gl.js"></script>

    <!-- Load your 360-view-map.js as a module -->
    <script type="module" src="lib/360-view-map.js"></script>

    <script>
        // Initialize MapLibre GL JS
        const map = new maplibregl.Map({
            container: 'map',
            style: 'https://tiles.wifidb.net/styles/WDB_OSM/style.json',
            center: [-86.84656, 21.17429],
            zoom: 5
        });
		
		//Add GlobeControl Button
		var gc = new maplibregl.GlobeControl();
		map.addControl(gc);

		//Add Fullscreen Button
		var fs = new maplibregl.FullscreenControl();
		map.addControl(fs);

		fs._fullscreenButton.classList.add('needsclick'); //Add Navigation Control
		map.addControl(new maplibregl.NavigationControl({
			visualizePitch: true,
			showZoom: true,
			showCompass: true
		}));

        map.on('load', function() {
            // Load the GPS data (replace with your JSON file path)
            fetch('https://media.techidiots.net/360/exifjson.php')
                .then(response => response.json())
                .then(imageData => {
                    // Add markers to the map
                    imageData.forEach(item => {
                        const marker = new maplibregl.Marker()
                            .setLngLat([item.longitude, item.latitude])
                            .addTo(map);

                        // Add click event listener to the marker
                        marker.getElement().addEventListener('click', () => {
                            window.isPanoramaActive = true;
                            window.showPanorama(item.image_url); // Call the global function
                        });
                    });
                })
                .catch(error => console.error('Error loading image data:', error));
        });

        const container = document.getElementById("container");
        const contentElement = document.getElementById('content');
        const mapdiv = document.getElementById('mapcontainer'); // Get the CONTAINER
        const hide_controls = document.getElementById('iconShowHide');
        const file_forward = document.getElementById('iconNextFile');
        const file_backward = document.getElementById('iconPreviousFile');
        const full_screen = document.getElementById('iconFullscreen');
        const CurrentFile = '{$file}';
        const FileList = {$file_list|json_encode};

        function PlayNextFile() {
            var i = FileList.indexOf(CurrentFile);
            i = i + 1; // increase i by one
            i = i % FileList.length; // if we've gone too high, start from `0` again
            var url = "{$website_root}index.php?file=" + FileList[i]
            window.location.href = url

        }

        function PlayPrevFile() {
            var i = FileList.indexOf(CurrentFile);
            if (i === 0) { // i would become 0
                i = FileList.length; // so put it at the other end of the array
            }
            i = i - 1; // decrease by one
            var url = "{$website_root}index.php?file=" + FileList[i]
            window.location.href = url
        }

        function goFullScreen(){
            if (!document.fullscreenElement) {
                container.requestFullscreen();
            } else {
                document.exitFullscreen();
            }
        }

        function HideControls() {
            $('.all_controls').toggleClass('hidden');
        }

        // Event listeners
        hide_controls.addEventListener('click', HideControls);
        file_forward.addEventListener('click', PlayNextFile);
        file_backward.addEventListener('click', PlayPrevFile);
        full_screen.addEventListener('click', goFullScreen);

        contentElement.addEventListener('transitionend', function(event) {
            if (event.propertyName === 'left') {
                onWindowResize();
            }
        });

        let mousedown = false;

    </script>
</div>
{include file="footer.tpl"}
