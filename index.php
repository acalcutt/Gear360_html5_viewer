<?php
require "init.php";
$file = isset($_GET['file']) ? $_GET['file'] : "";

// Default values
$x = 0;
$y = 0;
$z = 0;
$zoom = 1;
$autoplay = 1;  // Default to autoplay ON
$startTime = 0;

// Validate parameters for threejs render
if (isset($_GET['x']) && is_numeric($_GET['x']) && (0 <= $_GET['x']) && ($_GET['x'] <= 360)) {
	$x = (int)$_GET['x'];
}
if (isset($_GET['y']) && is_numeric($_GET['y']) && (-180 <= $_GET['y']) && ($_GET['y'] <= 180)) {
	$y = (int)$_GET['y'];
}
if (isset($_GET['z']) && is_numeric($_GET['z']) && (-90 <= $_GET['z']) && ($_GET['z'] <= 90)) {
	$z = (int)$_GET['z'];
}
if (isset($_GET['zoom']) && is_numeric($_GET['zoom']) && (.4 <= $_GET['zoom']) && ($_GET['zoom'] <= 3)) {
	$zoom = (float)$_GET['zoom'];
}

// Validate start time
if (isset($_GET['startTime']) && is_numeric($_GET['startTime']) && ($_GET['startTime'] >= 0)) {
	$startTime = (int)$_GET['startTime'];
}

// Validate autoplay
if (isset($_GET['paused']) && $_GET['paused'] == 1) {
	$autoplay = 0; // 0 is set only when the value is manually paused
} else {
	$autoplay = 1; //Force other values to be 1
}

if($file && file_exists ($file))
{
	$path = pathinfo($file);
	$smarty->assign('file',$file);
	$smarty->assign('title',str_replace('videos/','',$file));
	$smarty->assign('video_fallback',$path['dirname']."/fallback.mp4");
	$smarty->assign('default_x',$x);
	$smarty->assign('default_y',$y);
	$smarty->assign('default_z',$z);
	$smarty->assign('zoom',$zoom);
	$smarty->assign('autoplay',$autoplay);
	$smarty->assign('startTime',$startTime);

	$ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
	$filename = strtolower(pathinfo($file, PATHINFO_FILENAME)); // Get filename without ANY extension

	$isEquirectangular = false;
	if (strpos($filename, '.eq') !== false) {
		$isEquirectangular = true;
	}

	// Check if the file path starts with any of the configured equirectangular directories
	if (!$isEquirectangular) {
	  foreach ($equirectangular_directories as $dir) {
		if (strpos($file, $dir) === 0) {
		  $isEquirectangular = true;
		  break; // No need to check other directories if one matches
		}
	  }
	}

	$smarty->assign("isEquirectangular", $isEquirectangular);

	// Check for video files
	if ($ext == "mpd") { // **Check for DASH matifest **
		$smarty->display("360video.dash.tpl");
	}
	elseif ($ext == "m3u8") { // **Check for HLS master playlist**
		$smarty->display("360video.hls.tpl");
	}
	// Check for image files
	elseif ($ext == "jpg" || $ext == "png") {
		$smarty->display("360image.tpl");
	}
	else {
		$smarty->display("index.tpl");
	}
}
else
{
	$smarty->display("index.tpl");
}
?>
