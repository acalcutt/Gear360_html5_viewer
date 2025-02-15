<?php
require "init.php";
$file = isset($_GET['file']) ? $_GET['file'] : "";
if (isset($_GET['x']) && is_numeric($_GET['x']) && (0 <= $_GET['x']) && ($_GET['x'] <= 360)){$x = $_GET['x'];} else {$x = 0;}
if (isset($_GET['y']) && is_numeric($_GET['y']) && (0 <= $_GET['y']) && ($_GET['y'] <= 360)){$y = $_GET['y'];} else {$y = 0;}
if (isset($_GET['z']) && is_numeric($_GET['z']) && (0 <= $_GET['z']) && ($_GET['z'] <= 360)){$z = $_GET['z'];} else {$z = 0;}
if (isset($_GET['zoom']) && is_numeric($_GET['zoom']) && (.4 <= $_GET['zoom']) && ($_GET['zoom'] <= 3)){$zoom = $_GET['zoom'];} else {$zoom = 1;}
if (isset($_GET['paused']) && $_GET['paused'] == 1) {$autoplay = 0;} else {$autoplay = 1;}


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

	$ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
	$filename = strtolower(pathinfo($file, PATHINFO_FILENAME)); // Get filename without ANY extension

	$isEquirectangular = (strpos($filename, '.eq') !== false);  // Check for .eq in filename

	// Check if the file path starts with any of the configured equirectangular directories
	if (!$isEquirectangular) {
		foreach ($equirectangular_directories as $dir) {
			if (strpos($file, $dir) === 0) {
				$isEquirectangular = true;
				break; // No need to check other directories if one matches
			}
		}
	}


	// Check for video files
	if ($ext == "mpd") {
		if ($isEquirectangular) {
			$smarty->assign("isEquirectangular", true); // Can pass to the template if needed
			$smarty->display("360video.eq.tpl");
		} else {
			$smarty->assign("isEquirectangular", false);
			$smarty->display("360video.tpl");
		}
	}
	// Check for image files
	elseif ($ext == "jpg" || $ext == "png") {
		if ($isEquirectangular) {
			$smarty->assign("isEquirectangular", true);
			$smarty->display("360image.eq.tpl");
		} else {
			$smarty->assign("isEquirectangular", false);
			$smarty->display("360image.tpl");
		}
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
