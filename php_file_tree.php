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
	2025/02/18 - Added file array output $includedfiles and made folder links no longer clickable. - Andrew Calcutt

*/

function php_file_tree(
	$directory,
	$return_link,
	$extensions = [],
	$excludedfiles = [],
	$includedfiles = [],
	$file_list = []
) {
	// Generates a valid XHTML list of all directories, sub-directories, and files in $directory
	// Remove trailing slash
	if (substr($directory, -1) == "/") {
		$directory = substr($directory, 0, strlen($directory) - 1);
	}
	$arr_ret = php_file_tree_dir(
		$directory,
		$return_link,
		$extensions,
		$excludedfiles,
		$includedfiles,
		true,
		$file_list
	);
	$code .= $arr_ret["data"];
	$file_list = $arr_ret["file_list"];
	return ["data" => $code, "file_list" => $file_list];
}

function php_file_tree_dir(
	$directory,
	$return_link,
	$extensions = [],
	$excludedfiles = [],
	$includedfiles = [],
	$first_call = true,
	$file_list = []
) {
	// Recursive function called by php_file_tree() to list directories/files

	// Get and sort directories/files
	if (function_exists("scandir")) {
		$file = scandir($directory);
	} else {
		$file = php4_scandir($directory);
	}
	natcasesort($file);
	// Make directories first
	$files = $dirs = [];
	foreach ($file as $this_file) {
		if (is_dir("$directory/$this_file")) {
			$dirs[] = $this_file;
		} else {
			$files[] = $this_file;
		}
	}
	$file = array_merge($dirs, $files);

	// PRE-FILTERING: Include explicitly included files, regardless of extension
	if (!empty($includedfiles)) {
		foreach ($includedfiles as $included_file) {
			$full_included_path = $directory . "/" . $included_file;
			if (
				file_exists($full_included_path) &&
				!is_dir($full_included_path)
			) {
				// Check if the included file is already in the $file array
				if (!in_array($included_file, $file)) {
					$file[] = $included_file; // Add the included file if it's not already there
				}
			}
		}
	}

	// Filter unwanted extensions
	$filtered = []; // Initialize the $filtered array
	if (!empty($extensions)) {
		foreach (array_keys($file) as $key) {
			if (!is_dir("$directory/$file[$key]")) {
				$ext = strtolower(
					substr($file[$key], strrpos($file[$key], ".") + 1)
				);
				if (!in_array($ext, $extensions)) {
					$filtered[] = $key; // Mark the key for filtering
				}
			}
		}
	}

	$has_content = false;

	if (count($file) > 2) {
		$id = base64_encode("ul/$directory");
		$php_file_tree = "<ul id=\"" . $id . "\"";
		if ($first_call) {
			$php_file_tree .= " class=\"php-file-tree\"";
		}
		$php_file_tree .= ">";
		if ($first_call) {
			$php_file_tree .=
				"<li class=\"pft-home\"><a href=\".\">Home</a></li>";
			$first_call = false;
		}
		foreach ($file as $this_file) {
			if ($this_file != "." && $this_file != "..") {
				if (is_dir("$directory/$this_file")) {
					$arr_ret = php_file_tree_dir(
						"$directory/$this_file",
						$return_link,
						$extensions,
						$excludedfiles,
						$includedfiles,
						false,
						$file_list
					);
					$subdir = $arr_ret["data"];
					$file_list = $arr_ret["file_list"];
					if ($subdir) {
						$has_content = true;

						// Directory
						$link = str_replace(
							"[link]",
							"$directory/$this_file",
							$return_link
						);
						$id = base64_encode("li/$directory/" . $this_file);
						// Removed the <a> tag here
						$php_file_tree .=
							"<li id=\"" .
							$id .
							"\" class=\"pft-directory\">" .
							htmlspecialchars($this_file);
						$php_file_tree .= $subdir;
						$php_file_tree .= "</li>";
					}
				} else {
					// Inclusion logic - AFTER Extension Filtering
					$included = in_array($this_file, $includedfiles);
					$is_filtered = in_array(
						array_search($this_file, $file),
						$filtered
					); // Check if the file is marked as filtered

					if (
						(!in_array($this_file, $excludedfiles) &&
							!$is_filtered) ||
						$included
					) {
						$has_content = true;
						// File
						// Get extension (prepend 'ext-' to prevent invalid classes from extensions that begin with numbers)
						$ext =
							"ext-" .
							substr($this_file, strrpos($this_file, ".") + 1);
						$link = str_replace(
							"[link]",
							"$directory/" . urlencode($this_file),
							$return_link
						);
						$id = base64_encode("li/$directory/" . $this_file);
						$php_file_tree .=
							"<li id=\"" .
							$id .
							"\" class=\"pft-file " .
							strtolower($ext) .
							"\"><a href=\"$link\">" .
							htmlspecialchars($this_file) .
							"</a></li>";
						$file_list[] = "$directory/" . urlencode($this_file);
					}
				}
			}
		}
		$php_file_tree .= "</ul>";
	}
	if ($has_content) {
		return ["data" => $php_file_tree, "file_list" => $file_list];
	} else {
		return ["data" => "", "file_list" => $file_list];
	}
}

// For PHP4 compatibility
function php4_scandir($dir)
{
	$dh = opendir($dir);
	while (false !== ($filename = readdir($dh))) {
		$files[] = $filename;
	}
	sort($files);
	return $files;
}
