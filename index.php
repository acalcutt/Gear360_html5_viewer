<?php
require "init.php";
$video = isset($_GET['video']) ? $_GET['video'] : "";
if (isset($_GET['x']) && is_numeric($_GET['x']) && (0 <= $_GET['x']) && ($_GET['x'] <= 360)){$x = $_GET['x'];} else {$x = 0;}
if (isset($_GET['y']) && is_numeric($_GET['y']) && (0 <= $_GET['y']) && ($_GET['y'] <= 360)){$y = $_GET['y'];} else {$y = 0;}
if (isset($_GET['z']) && is_numeric($_GET['z']) && (0 <= $_GET['z']) && ($_GET['z'] <= 360)){$z = $_GET['z'];} else {$z = 0;}
if (isset($_GET['zoom']) && is_numeric($_GET['zoom']) && (.4 <= $_GET['zoom']) && ($_GET['zoom'] <= 3)){$zoom = $_GET['zoom'];} else {$zoom = 1;}
if (isset($_GET['paused']) && $_GET['paused'] == 1) {$autoplay = 0;} else {$autoplay = 1;}


if($video && file_exists ($video))
{
	$path = pathinfo($video);
	$smarty->assign('video_dash',$video);
	$smarty->assign('title',str_replace('videos/','',$video));
	$smarty->assign('video_fallback',$path['dirname']."/fallback.mp4");
	$smarty->assign('default_x',$x);
	$smarty->assign('default_y',$y);
	$smarty->assign('default_z',$z);
	$smarty->assign('zoom',$zoom);
	$smarty->assign('autoplay',$autoplay);
	$ext =  strtolower(pathinfo($video, PATHINFO_EXTENSION));
	if($ext == "mpd")
	{
		$smarty->display("360video.tpl");
	}
	else if($ext == "jpg" || $ext == "png")
	{
		$smarty->display("360image.tpl");
	}
}
else
{
	$smarty->display("index.tpl");
}	