<?php

// Include the php_file_tree.php file. Adjust the path if necessary.
require_once 'php_file_tree.php';

// Define the directory to scan
$directory = "files/";

// Define allowed extensions (only JPG in this case)
$allowed = array("jpg", "jpeg");

// Define excluded files (optional)
$excluded = array();

// Define included files (optional, overrides extension filtering)
$included = array();

// Initialize the file list
$file_list = [];

// Call the php_file_tree function
$arr_ret = php_file_tree($directory, "?file=[link]", $allowed, $excluded, $included, $file_list);
$video_menu = $arr_ret["data"];
$file_list = $arr_ret["file_list"];

// Function to extract GPS EXIF data from a JPG file
function get_gps_data($image_path) {
    $exif = exif_read_data($image_path);

    if ($exif) {
        // Debug: Print the raw EXIF data to see what's available
        echo "<pre>EXIF data for $image_path:\n";
        print_r($exif);
        echo "</pre>";

        // Extract Latitude and Longitude from DMS format *only*
        $latitude = null;
        $longitude = null;

        if (isset($exif['GPSLatitude']) && isset($exif['GPSLongitude']) && isset($exif['GPSLatitudeRef']) && isset($exif['GPSLongitudeRef'])) {
            // Convert GPS coordinates to decimal degrees
            echo "Before gps2num latitude: " . print_r($exif['GPSLatitude'], true) . "<br>"; //Debug
            $lat_degrees = gps2num($exif['GPSLatitude']);
            echo "After gps2num latitude: " . $lat_degrees . "<br>"; // Debug

            echo "Before gps2num longitude: " . print_r($exif['GPSLongitude'], true) . "<br>"; //Debug
            $lon_degrees = gps2num($exif['GPSLongitude']);
            echo "After gps2num longitude: " . $lon_degrees . "<br>"; // Debug

            // Adjust for hemisphere
            $lat_direction = $exif['GPSLatitudeRef'];
            $lon_direction = $exif['GPSLongitudeRef'];

            if ($lat_direction == 'S') {
                $lat_degrees = -$lat_degrees;
            }
            if ($lon_direction == 'W') {
                $lon_degrees = -$lon_degrees;
            }

            $latitude = $lat_degrees;
            $longitude = $lon_degrees;
            echo "DMS lat/lon found<br>";
        }


        // Extract Altitude
        $altitude = null;
        if(isset($exif['GPSAltitude'])){
            $altitude = $exif['GPSAltitude'];
             // Convert to a number. ExifTool's output may need some cleaning
            $altitude = preg_replace('/[^0-9\.]/', '', $altitude); // Remove non-numeric chars
          //Add debug
            echo "Before floatval altitude: " . $altitude . "<br>"; //Debug
            $altitude = floatval($altitude); //Convert to number
            echo "After floatval altitude: " . $altitude . "<br>"; //Debug


        }

        if ($latitude !== null && $longitude !== null) {
            return array(
                'latitude' => $latitude,
                'longitude' => $longitude,
                'altitude' => $altitude
            );
        } else {
           echo "No usable GPS data found in EXIF<br>";
           return null;
        }
    } else {
        echo "exif_read_data failed for $image_path<br>";
        return null; // No EXIF data found
    }
}

// Helper function to convert GPS coordinates from EXIF format to decimal degrees
function gps2num($coord_parts) { // Changed $coord_part to $coord_parts (plural)
    echo "gps2num input: " . print_r($coord_parts, true) . "<br>"; // Debug

    $degrees = 0;
    $minutes = 0;
    $seconds = 0;

    if (is_array($coord_parts) && count($coord_parts) == 3) {
        $degrees = gps2float($coord_parts[0]);
        $minutes = gps2float($coord_parts[1]);
        $seconds = gps2float($coord_parts[2]);
    } else {
        echo "Error: Invalid coordinate format!<br>";
        return 0; // Or throw an exception
    }

    $result = $degrees + ($minutes / 60) + ($seconds / 3600);
    echo "gps2num output: " . $result . "<br>"; // Debug

    return $result;
}

function gps2float($coord_part) {
    echo "gps2float input: " . $coord_part . "<br>"; // Debug
    $parts = explode('/', $coord_part);
    if (count($parts) > 0) {
        $result = floatval($parts[0]) / floatval($parts[1]);
         echo "gps2float output: " . $result . "<br>"; // Debug
        return $result;
    }
     echo "gps2float output: 0.0<br>"; // Debug
    return 0.0;
}


// Process the file list and extract GPS data
$gps_data = array();
foreach ($file_list as $file_path) {
    // Check if the file is a JPG (redundant, but good practice)
    $ext = strtolower(pathinfo($file_path, PATHINFO_EXTENSION));
    if (in_array($ext, $allowed)) {
        $gps = get_gps_data($file_path);
        if ($gps) {
            $gps_data[$file_path] = $gps;
            echo "GPS data found for: $file_path<br>";
            echo "Latitude: " . $gps['latitude'] . "<br>";
            echo "Longitude: " . $gps['longitude'] . "<br>";
            echo "Altitude: " . ($gps['altitude'] ?? 'N/A') . "<br><br>"; // Use null coalescing operator for Altitude

        } else {
            echo "No GPS data found for: $file_path<br><br>";
        }
    }
}

// Output the results (you can format this as needed)
echo "<h2>GPS Data Summary:</h2>";
if (empty($gps_data)) {
    echo "No JPG images with GPS data were found.";
} else {
   echo "<pre>";
   print_r($gps_data);
   echo "</pre>";
}

?>
