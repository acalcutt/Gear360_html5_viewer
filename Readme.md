# HTML5 360° Video and Image Viewer

This project provides a web-based HTML5 player for displaying both 360° videos and images.  It utilizes a configuration file for customization and supports HLS (m3u8) and DASH (mpd) streaming formats, as well as static images (jpg, png).  The player leverages the Smarty templating engine for flexible presentation and Threejs for 3d rendering.

## Features

*   **360° Video and Image Support:** Play equirectangular or samsung gear fisheye 360° videos and images.
*   **HLS and DASH Streaming:** Supports adaptive bitrate streaming using HLS (HTTP Live Streaming) and DASH (Dynamic Adaptive Streaming over HTTP) protocols.
*   **Configuration File:** Easily customize the player's behavior through a central `config.php` file.
*   **Theming:** Supports theming for customization.
*   **Initial Viewing Configuration:** Set initial X,Y,Z rotation, zoom, autoplay, and starttime.
*   **File Tree Navigation:**  Dynamically generates a file tree menu for easy video/image selection.
*   **Three.js Integration**: Uses Threejs for 3d rendering
    *   Renders 360 videos and images within a Three.js sphere.
    *   Provides interactive controls for panning, tilting, zooming, and rotating the view.
    *   Supports equirectangular projection formats and maintains some support for dual fisheye projection.

## Requirements

*   Web server (e.g., Apache, Nginx)
*   PHP 5.4 or higher
*   Smarty Templating Engine (included)
*   Three.js (included in the `lib/` directory as `three.module.js`)

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/acalcutt/html5-360-viewer.git [local folder]
    cd [local folder]
    ```

2.  **Configure `config.php`:**

    *   Copy `config.php.dist` to `config.php` if it exists.
    *   Open `config.php` and adjust the following settings to match your environment:

        ```php
        <?php
        $root_directory = '/local/path/to/website/'; // The local filesystem path to your website root (e.g., /var/www/html/myplayer/).  Important for Smarty paths.
        $root_website = '//www.example.com/360/'; // The URL to your website (e.g., //www.example.com/360/).  Used for building links within the player.
        $initialVideoBitrate = 5500000; // Initial video bitrate. Adjust based on your network conditions.  -1 to autoselect.
        $initialAudioBitrate = -1; // Initial audio bitrate. Adjust based on your network conditions. -1 to autoselect.
        $theme = 'default'; // The name of the theme to use.  Themes are located in the `/themes/` directory.

        // Array of directories to treat as equirectangular image sources.  Files in these directories will be treated as equirectangular 360 images, even if not using *.eq.* naming.
        $equirectangular_directories = array(
        	'files/equirectangular/',
        );

        // Allowed file types for the file tree.  These files will be displayed.
        $allowed = array("jpg", "png");

        // Files to exclude from the file tree (e.g., thumbnails, etc.).
        $excluded = array("thumbnail.jpg","thumbnail.png");

        // File types to include in the file tree.  Used to filter for specific video formats (HLS, DASH).
        $included = array("Play.m3u8","Play.eq.m3u8","Play.mpd","Play.eq.mpd"); #(HLS and DASH videos)
        #$included = array("Play.m3u8","Play.eq.m3u8"); #(HLS videos only)
        #$included = array("Play.mpd","Play.eq.mpd"); #(DASH videos only)
        ?>
        ```

        *   **`$root_directory`:**  The absolute path on your server to the root directory of the player.  This is crucial for Smarty to locate the template files correctly.
        *   **`$root_website`:** The URL where the player is accessible in a web browser.  Include the protocol (e.g., `http://` or `https://`).
        *   **`$initialVideoBitrate`:**  The initial video bitrate to use for HLS or DASH streams.  A higher bitrate will result in better quality, but may require a faster internet connection.  Set to `-1` for auto-selection.
        *   **`$initialAudioBitrate`:**  The initial audio bitrate to use for HLS or DASH streams. Set to `-1` for auto-selection.
        *   **`$theme`:**  The name of the theme folder located in the `themes/` directory.
        *   **`$equirectangular_directories`**: A list of directories that contain equirectangular media. This will include all subfolders. If you want all media treated as equirectangular, set this to  'files/'
        *   **`$allowed`**: Array of allowed file extensions for file tree
        *   **`$excluded`**: Array of files that are not to be shown in the file tree
        *   **`$included`**: Array of files that are to be shown in the file tree

3.  **Configure Web Server:**

    *   Ensure your web server is configured to serve PHP files.
    *   Set the document root of your website to the directory where you installed the player.
    *   Make sure that `smarty/templates_c` and `smarty/cache` are writable by the web server user.

4.  **Access the Player:**

    *   Open your web browser and navigate to the URL you defined in `$root_website` (e.g., `http://www.example.com/360/`).

## Usage

The player displays a file tree on the left-hand side, allowing you to navigate through your video and image files.

### File Tree Generation

The file tree is generated dynamically using the `php_file_tree.php` script.  It scans the `files/` directory and its subdirectories, creating a navigable list of files and folders.

*   **Inclusion/Exclusion:** The `$allowed`, `$excluded`, and `$included` arrays in `config.php` control which files are displayed in the tree.
    *   `$allowed` defines the file extensions that are generally allowed.
    *   `$excluded` defines specific filenames to exclude.
    *   `$included` forces the inclusion of specific filenames, even if their extension is not in `$allowed`.  This is useful for including HLS/DASH manifest files (e.g., `Play.m3u8`, `Play.mpd`).

### Template Selection

The `index.php` script determines which Smarty template to use based on the file extension:

*   **`.mpd`:** Uses `360video.dash.tpl` for DASH videos.  Requires the `dash.all.debug.js` library.
*   **`.m3u8`:** Uses `360video.hls.tpl` for HLS videos.  Requires the `hls.min.js` library.
*   **`.jpg`, `.png`:** Uses `360image.tpl` for 360° images.
*   **Other:** Uses `index.tpl`.

### Three.js Implementation

The player uses Three.js to render the 360° environment.  The core logic is in `lib/360-view-image.js` (for images) and `lib/360-view-video.js` (for videos).

*   **Basic Setup:**
    *   Creates a Three.js `Scene`, `Camera`, and `WebGLRenderer`.
    *   Applies the selected video or image as a texture to the inside of a sphere using `THREE.SphereGeometry` and `THREE.MeshBasicMaterial`.

*   **Projection Support:**
    *   **Equirectangular:** Uses the equirectangular projection as a default.
    *   **Dual Fisheye:** The code retains some support for the dual fisheye projection used by cameras like the Samsung Gear 360.  For this format, the UV coordinates of the sphere's faces are modified to correct for the projection.  Note:  The primary focus of the project is now on equirectangular projection.

*   **Interaction and Controls:**
    *   Allows users to pan, tilt, and zoom using mouse and touch controls.
    *   The initial view (X, Y, Z rotation and zoom) can be controlled via URL parameters, which can also be set through the user interface.
    *   The `UpdateURL()` function synchronizes current view parameters (X, Y, Z rotation and zoom) in the url.

*   **Dynamic Updates:**
    *   The `UpdateView()` function handles updating the camera's orientation based on user input.
    *   The `onWindowResize()` function ensures the rendering adapts to different screen sizes.

### Dual Fisheye Correction (Legacy Support)

The original project was designed to work with the dual fisheye output of the Samsung Gear 360 camera. The following information explains how the code corrects for this projection. While equirectangular projection is the primary focus now, this information may be helpful for users with legacy content.

The fisheye correction is implemented in `360-view-image.js` and `360-view-video.js` using the following logic:

```javascript
// Dual Fisheye Correction (for legacy Samsung Gear 360 videos)
if (!isEquirectangular) {
    var i;
    var faceVertexUvs = geometry.faceVertexUvs[0];
    for (i = 0; i < faceVertexUvs.length; i++) {
        var uvs = faceVertexUvs[i];
        var face = geometry.faces[i];
        for (var j = 0; j < 3; j++) {
            var x = face.vertexNormals[j].x;
            var y = face.vertexNormals[j].y;
            var z = face.vertexNormals[j].z;

            if (i < faceVertexUvs.length / 2) {
                var correction = (x == 0 && z == 0) ? 1 : (Math.acos(y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
                uvs[j].x = x * (444 / 1920) * correction + (480 / 1920);
                uvs[j].y = z * (444 / 1080) * correction + (600 / 1080);

            } else {
                var correction = (x == 0 && z == 0) ? 1 : (Math.acos(-y) / Math.sqrt(x * x + z * z)) * (2 / Math.PI);
                uvs[j].x = -1 * x * (444 / 1920) * correction + (1440 / 1920);
                uvs[j].y = z * (444 / 1080) * correction + (600 / 1080);
            }
        }
    }
}
```

This code calculates a correction factor based on the vertex normals and applies it to the UV coordinates of each face in the sphere geometry. The magic numbers (e.g., `444 / 1920`, `480 / 1920`) are specific to the Samsung Gear 360's fisheye lens characteristics.

The base code refers to this code in the answer to the following question.
[Javascript - Mapping image onto a sphere in Three.js - Stack Overflow](https://stackoverflow.com/questions/21663923/mapping-image-onto-a-sphere-in-three-js)

### URL Parameters

You can control the player's behavior using URL parameters:

*   **`file`:**  Specifies the path to the video or image file to play.  (e.g. `index.php?file=files/myvideo/myvideo.m3u8`)
*   **`x`:** Initial X rotation (pan) in degrees (0-360).
*   **`y`:** Initial Y rotation (tilt) in degrees (-180-180).
*   **`z`:** Initial Z rotation (roll) in degrees (-90-90).
*   **`zoom`:** Initial zoom level (0.4-3).
*   **`startTime`:** Start time of the video in seconds.
*   **`paused`:** Set to `1` to start the video paused. Any other value will force autoplay.
*   **Example:** `index.php?file=videos/myvideo.mp4&x=45&y=-20&zoom=1.5&startTime=10&paused=1`

### File Naming Convention

*   **Equirectangular Videos/Images:**  You can either place your files in the directory declared in `$equirectangular_directories` or name your file as such: `myvideo.eq.m3u8` `myvideo.eq.mpd`.  This ensures the player treats them as 360° content.

### Directory Structure

```
[project root]
├── config.php          # Configuration file
├── index.php           # Main entry point
├── init.php            # Initialization script
├── files/              # Directory for your videos and images
│   ├── myvideo/        # Example video folder
│   │   ├── myvideo.mp4   # Fallback MP4 video file
│   │   ├── myvideo.mpd   # DASH manifest file
│   │   └── myvideo.m3u8  # HLS playlist file
│   ├── myimage.jpg     # Example image
│   └── ...
├── themes/
│   └── default/        # Default theme
│       ├── templates/
│       │   ├── index.tpl        # Default template
│       │   ├── 360video.hls.tpl  # HLS video template
│       │   ├── 360video.dash.tpl # DASH video template
│       │   └── 360image.tpl      # 360 image template
│       └── ...
├── smarty/
│   ├── libs/           # Smarty library files
│   ├── templates_c/    # Compiled Smarty templates (must be writable)
│   ├── cache/          # Smarty cache directory (must be writable)
│   └── ...
└── lib/
    ├── three.module.js   # Three.js library
└── ...
```

## Theming

To create a custom theme:

1.  Create a new directory under the `themes/` directory (e.g., `themes/mytheme/`).
2.  Copy the contents of the `themes/default/` directory to your new theme directory.
3.  Modify the template files (`.tpl` files) in your theme directory to customize the player's appearance.
4.  Set the `$theme` variable in `config.php` to the name of your theme (e.g., `$theme = 'mytheme';`).
