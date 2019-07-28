<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<link rel="stylesheet" href="{$theme_dir}theme.css">
	<script src="lib/dash.all.debug.js">
	</script>
	<script src="lib/jquery-3.4.1.min.js" type="text/javascript">
	</script>
	<script src="lib/php_file_tree_jquery.js" type="text/javascript">
	</script>
	<script type="text/javascript">
	       $(document).ready(function () {
	           $('.bt-menu-trigger').on('click', function () {
	               $('.menu').toggleClass('active');
	               $('.vidcontrols').toggleClass('active');
	               $('.content').toggleClass('active');
	               $(this).toggleClass('bt-menu-alt');
	               
	               //window.dispatchEvent(new Event('resize'));
	               var resizeEvent = window.document.createEvent('UIEvents'); 
	               resizeEvent.initUIEvent('resize', true, false, window, 0); 
	               window.dispatchEvent(resizeEvent);
	           });
	       });
	</script>
	<title></title>
</head>
<body>