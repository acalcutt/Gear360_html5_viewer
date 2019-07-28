<?php
/*
	
	== PHP FILE TREE ==
	
		Let's call it...oh, say...version 1?
	
	== AUTHOR ==
	
		Cory S.N. LaViska
		http://abeautifulsite.net/
		
	== DOCUMENTATION ==
	
		For documentation and updates, visit http://abeautifulsite.net/notebook.php?article=21
		
	2019/7/20 - made it so empty directories don't show. - Andrew Calcutt
	2019/7/24 - made "Home" link show at the top. - Andrew Calcutt
	2019/7/28 - Added file array output. - Andrew Calcutt
		
*/


function php_file_tree($directory, $return_link, $extensions = array(), $file_list = array()) {
	// Generates a valid XHTML list of all directories, sub-directories, and files in $directory
	// Remove trailing slash
	if( substr($directory, -1) == "/" ) $directory = substr($directory, 0, strlen($directory) - 1);
	$arr_ret = php_file_tree_dir($directory, $return_link, $extensions, true, $file_list);
	$code .= $arr_ret["data"];
	$file_list = $arr_ret["file_list"];
	return array("data"=>$code,"file_list"=>$file_list);
}

function php_file_tree_dir($directory, $return_link, $extensions = array(), $first_call = true, $file_list = array()) {
	// Recursive function called by php_file_tree() to list directories/files
	
	// Get and sort directories/files
	if( function_exists("scandir") ) $file = scandir($directory); else $file = php4_scandir($directory);
	natcasesort($file);
	// Make directories first
	$files = $dirs = array();
	foreach($file as $this_file) {
		if( is_dir("$directory/$this_file" ) ) $dirs[] = $this_file; else $files[] = $this_file;
	}
	$file = array_merge($dirs, $files);
	
	// Filter unwanted extensions
	if( !empty($extensions) ) {
		foreach( array_keys($file) as $key ) {
			if( !is_dir("$directory/$file[$key]") ) {
				$ext = substr($file[$key], strrpos($file[$key], ".") + 1); 
				if( !in_array($ext, $extensions) ) unset($file[$key]);
			}
		}
	}
	
	if( count($file) > 2 ) { // Use 2 instead of 0 to account for . and .. "directories"
		$php_file_tree = "<ul";
		if( $first_call ) { $php_file_tree .= " class=\"php-file-tree\""; }
		$php_file_tree .= ">";
		if( $first_call ) { $php_file_tree .= "<li class=\"pft-home\"><a href=\".\">Home</a></li>"; $first_call = false; }
		foreach( $file as $this_file ) {
			if( $this_file != "." && $this_file != ".." ) {
				if( is_dir("$directory/$this_file") ) {
					$arr_ret = php_file_tree_dir("$directory/$this_file", $return_link ,$extensions, false, $file_list);
					$subdir = $arr_ret["data"];
					$file_list = $arr_ret["file_list"];
					if($subdir)
					{
						// Directory
						$php_file_tree .= "<li class=\"pft-directory\"><a href=\"#\">" . htmlspecialchars($this_file) . "</a>";
						$php_file_tree .= $subdir;
						$php_file_tree .= "</li>";
					}
				} else {
					$output_directory = 1;
					// File
					// Get extension (prepend 'ext-' to prevent invalid classes from extensions that begin with numbers)
					$ext = "ext-" . substr($this_file, strrpos($this_file, ".") + 1); 
					$link = str_replace("[link]", "$directory/" . urlencode($this_file), $return_link);
					$php_file_tree .= "<li class=\"pft-file " . strtolower($ext) . "\"><a href=\"$link\">" . htmlspecialchars($this_file) . "</a></li>";
					$file_list[] = "$directory/" . urlencode($this_file);
				}
			}
		}
		$php_file_tree .= "</ul>";
	}

	return array("data"=>$php_file_tree,"file_list"=>$file_list);
}

// For PHP4 compatibility
function php4_scandir($dir) {
	$dh  = opendir($dir);
	while( false !== ($filename = readdir($dh)) ) {
	    $files[] = $filename;
	}
	sort($files);
	return($files);
}
