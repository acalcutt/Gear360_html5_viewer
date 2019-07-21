<?php
require "config.php";
require "php_file_tree.php";

define('SMARTY_ROOT', $root_directory.'smarty/');
define('SMARTY_DIR', SMARTY_ROOT.'libs/');

require SMARTY_DIR.'Smarty.class.php';

$smarty = new Smarty();
$smarty->template_dir = $root_directory.'templates/';
$smarty->compile_dir  = SMARTY_ROOT.'templates_c/';
$smarty->config_dir   = SMARTY_ROOT.'configs/';
$smarty->cache_dir    = SMARTY_ROOT.'cache/';

$allowed = array("mpd");
$video_menu = php_file_tree("videos/", "?video=[link]", $allowed);