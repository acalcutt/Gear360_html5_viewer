<?php
require "config.php";
require "php_file_tree.php";

define('SMARTY_ROOT', $root_directory.'smarty/');
define('SMARTY_DIR', SMARTY_ROOT.'libs/');

require SMARTY_DIR.'Smarty.class.php';

$smarty = new Smarty();
$smarty->template_dir = $root_directory.'themes/'.$theme.'/templates/';
$smarty->compile_dir  = SMARTY_ROOT.'templates_c/';
$smarty->config_dir   = SMARTY_ROOT.'configs/';
$smarty->cache_dir    = SMARTY_ROOT.'cache/';

$smarty->assign('website_root',$root_website);
$smarty->assign('theme_dir',$root_website.'themes/'.$theme.'/');

$allowed = array("mpd", "jpg", "png");
$excluded = array("thumbnail.jpg","thumbnail.png");
$file_list = [];
$arr_ret = php_file_tree("videos/", "?video=[link]", $allowed, $excluded, $file_list);
$video_menu = $arr_ret["data"];
$file_list = $arr_ret["file_list"];

$smarty->assign('video_menu',$video_menu);
$smarty->assign('file_list',$file_list);

$smarty->assign('initialVideoBitrate',$initialVideoBitrate);
$smarty->assign('initialAudioBitrate',$initialAudioBitrate);
