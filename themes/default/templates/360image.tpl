{include file="header.tpl"}
{include file="menu.tpl"}
<div class="col content" id="content">
	<div id="container" ondragstart="return false;" ondrop="return false;">
		<img id="image" class="image_default" src="{$file}">
		<canvas id="360canvas" class="canvas_default"></canvas>
		<menu id="controls">
			<span class="video-icon all_controls"><b>{$title}</b></span>
			<br />
			<span id="iconShowHideMenu" class="video-icon" title="Toggle Menu"><img src="{$theme_dir}images/close-pane-48.png" id="showhidemenubtn1" class="video-button menu_default_visible"/><img src="{$theme_dir}images/open-pane-48.png" id="showhidemenubtn2" class="video-button menu_default_hidden"/></span>
			<span id="iconShowHide" class="video-icon" title="Toggle Controls"><img class="video-button" id="showhidebtn" src="{$theme_dir}images/control-panel-64.png"></span>
			<span id="all_controls" class="all_controls">
				<span id="iconPreviousFile" class="video-icon" title="Previous File"><img class="video-button" src="{$theme_dir}images/node-up-60.png"></span>
				<span id="iconNextFile" class="video-icon" title="Next File"><img class="video-button" src="{$theme_dir}images/node-down-60.png"></span>
				<span id="iconCamView" class="video-icon" title="Source View"><img class="video-button" id="videobtn" src="{$theme_dir}images/video-camera-60.png"></span>
				<span id="iconFullscreen" class="video-icon" title="Full Screen"><img class="video-button" src="{$theme_dir}images/fit-to-width-60.png"></span>
				<span class="view_controls">
					<span class="inline nowrap player-btn video-icon">Zoom: <input class="canv_slider" id="zoom_range" type="range" max="3" min=".4" step=".1" value="{$zoom}"><label id="zoom_range_label">{$zoom}x</label></span>
					<span class="inline nowrap player-btn video-icon">Up/Down: <input class="canv_slider" id="default_z_view" type="range" max="360" min="0" step="1" value="{$default_z}"><label id="default_z_view_label">{$default_z}°</label></span>
					<span class="inline nowrap player-btn video-icon">Left/Right: <input class="canv_slider" id="default_y_view" type="range" max="360" min="0" step="1" value="{$default_y}"><label id="default_y_view_label">{$default_y}°</label></span>
					<span class="inline nowrap player-btn video-icon">Rotate: <input class="canv_slider" id="default_x_view" type="range" max="360" min="0" step="1" value="{$default_x}"><label id="default_x_view_label">{$default_x}°</label></span>
				</span>
			</span>
		</menu>
	</div>
	<script src="{if $isEquirectangular eq 1}lib/360-view-image-eq.js{else}lib/360-view-image.js{/if}" type="module"></script>
	</script> 
	<script>

		const container = document.getElementById("container");
		const image  = document.getElementById('image');
		const hide_controls = document.getElementById('iconShowHide');
		const file_forward = document.getElementById('iconNextFile');
		const file_backward = document.getElementById('iconPreviousFile');
		const full_screen = document.getElementById('iconFullscreen');
		const cam_view = document.getElementById('iconCamView');
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

		function toggleImage() {
			$('.image_default').toggleClass('active');
			$('.canvas_default').toggleClass('hidden');
			$('.view_controls').toggleClass('hidden');
		   var resizeEvent = window.document.createEvent('UIEvents'); 
		   resizeEvent.initUIEvent('resize', true, false, window, 0); 
		   window.dispatchEvent(resizeEvent);
		   
		   	var videobtn = document.getElementById('videobtn');
			if (video.classList.contains("active")) {
				videobtn.src = "{$theme_dir}images/panorama-60.png";
				cam_view.setAttribute('title', '360 View');
			} else {
				videobtn.src = "{$theme_dir}images/video-camera-60.png";
				cam_view.setAttribute('title', 'Source View');
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
		cam_view.addEventListener('click', toggleImage);

		let mousedown = false;
	</script>
</div>
{include file="footer.tpl"}