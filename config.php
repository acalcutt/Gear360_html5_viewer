<?php
$root_directory = '/local/path/to/website/';
$root_website = '//www.example.com/360/';
$initialVideoBitrate = 5500000;
$initialAudioBitrate = -1;
$theme = 'default';

// Array of directories to treat as equirectangular image sources
$equirectangular_directories = array(
	'files/equirectangular/',
);

// Allowed file types
$allowed = array("jpg", "png");

// Files to exclude from the file tree
$excluded = array("thumbnail.jpg","thumbnail.png");

// File types to include (HLS and DASH videos)
$included = array("Play.m3u8","Play.eq.m3u8","Play.mpd","Play.eq.mpd"); #(HLS and DASH videos)
#$included = array("Play.m3u8","Play.eq.m3u8"); #(HLS videos only)
#$included = array("Play.mpd","Play.eq.mpd"); #(DASH videos only)
?>