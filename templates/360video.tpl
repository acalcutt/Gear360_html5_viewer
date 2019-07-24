{include file="header.tpl"}
<div class="vidcontrols">
	<video autoplay="" controls="" id="video"><source src="{$video_fallback}" type="video/mp4"></video>
	<div class="player-controls">
		<div class="bt-menu-trigger">
			<span></span>
		</div><button class="player-btn toggle-play" id='toggle-play' title="Toggle Play">
		<svg class="" viewbox="0 0 16 16" height="16" width="16">
			<title>play</title>
			<path d="M3 2l10 6-10 6z"></path>
		</svg>
		</button> 
		<span class="inline nowrap player-btn"><button class="player-btn" data-skip="-10" id='player-btn-backward'>« 10s </button><button class="player-btn" data-skip="10" id='player-btn-forward' >10s »</button></span>
		<span class="inline nowrap player-btn">Seek: <input id="progress-bar" max="100" min="0" oninput="seek(this.value)" step="0.01" type="range" value="0"></span>
		<span class="inline nowrap player-btn">Playback Rate: <input id='playbackRate' max="2.5" min="0.5" name='playbackRate' step="0.1" type="range" value="1"></span>
		<span class="inline nowrap player-btn">Volume: <input class="inline" id="volume" max="1" min="0" name="volume" step="0.05" type="range" value="1"></span>
	</div>
</div>
{include file="menu.tpl"}
<div class="col content" id="content">
	<div id="container" ondragstart="return false;" ondrop="return false;">
		<canvas id="360canvas"></canvas>
	</div>
	<script src="lib/theta-view.js" type="module">
	</script> 
	<script>
	       (function(){
				var url = "{$video_dash}";
				var initialConfig = {
					'streaming': {
						'abr': {
							limitBitrateByPortal: false,
							initialBitrate: { audio: {$initialAudioBitrate}, video: {$initialVideoBitrate} },
							autoSwitchBitrate: { audio: true, video: true }
						}
					}
				}
				
				var player = dashjs.MediaPlayer().create();
				player.updateSettings(initialConfig);
				player.initialize(document.querySelector("#video"), url, true);
				player.setAutoPlay(true);

	       })();
	</script> 
	<script>
	   const video  = document.getElementById('video');
	   const progressBar  = document.getElementById('progress-bar');
	   const toggle = document.getElementById('toggle-play');
	   const skip_forward = document.getElementById('player-btn-backward');
	   const skip_backward = document.getElementById('player-btn-forward');
	   const volume = document.getElementById('volume');
	   const playbackRate = document.getElementById('playbackRate');

	   // Logic
	   function togglePlay() {
	     const playState = video.paused ? 'play' : 'pause';
	     video[playState](); // Call play or paused method
	   }

	   function updateButton() {
	     const togglePlayBtn = document.getElementById('toggle-play');
	     if(this.paused) {
	       togglePlayBtn.innerHTML = '<svg class="" width="16" height="16" viewBox="0 0 16 16"><title>play<\/title><path d="M3 2l10 6-10 6z"><\/path><\/svg>';
	     } else {
	       togglePlayBtn.innerHTML = '<svg width="16" height="16" viewBox="0 0 16 16"><title>pause<\/title><path d="M2 2h5v12H2zm7 0h5v12H9z"><\/path><\/svg>';
	     }
	   }

	   function skip() {
	     video.currentTime += parseFloat(this.dataset.skip);
	   }

	   function rangeUpdate() {
	     video[this.name] = this.value;
	   }

	   function updateProgressBar() {
	     // Work out how much of the media has played via the duration and currentTime parameters
	     var percentage = Math.floor((100 / video.duration) * video.currentTime);
	     // Update the progress bar's value
	     progressBar.value = percentage;
	     // Update the progress bar's text (for browsers that don't support the progress element)
	     progressBar.innerHTML = percentage + '% played';
	   }
	   
	   function seek(e) {
	       progress_val = e / 100;
	     //var percent = e.offsetX / this.offsetWidth;
	     video.currentTime = progress_val * video.duration;
	     //progressBar.value = Math.floor(e / 100);
	     progressBar.innerHTML = progressBar.value + '% played';
	   }
	   
	   function scrub(e) {
	     const scrubTime = (e.offsetX / progress.offsetWidth) * video.duration;
	     video.currentTime = scrubTime;
	   }

	   // Event listeners
	   video.addEventListener('click', togglePlay);
	   video.addEventListener('play', updateButton);
	   video.addEventListener('pause', updateButton);
	   video.addEventListener('timeupdate', updateProgressBar, false);
	   
	   toggle.addEventListener('click', togglePlay);
	   skip_forward.addEventListener('click', skip);
	   skip_backward.addEventListener('click', skip);
	   volume.addEventListener('change', rangeUpdate);
	   volume.addEventListener('mousemove', rangeUpdate);
	   playbackRate.addEventListener('change', rangeUpdate);
	   playbackRate.addEventListener('mousemove', rangeUpdate);

	   let mousedown = false;
	   //progressBar.addEventListener("click", seek);
	</script>
</div>
{include file="footer.tpl"}