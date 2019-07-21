<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<style type="text/css">
	   
	   html, body {
	       height: 100%;
	       width: 100%;
	       margin: 0;
	       font-family: sans-serif;
	   }

	   video {
	       width: 0px;
	       height: 0px;
	   }
	   
	   #progress-bar {
	       width: 200px;
	       display: inline;
	   }

	   #volume {
	       width: 100px;
	   }
	   
	   #playbackRate {
	       width: 100px;
	   }
	   
	   .inline{
	       display: inline;
	   }

	   .vidcontrols {
	       position: absolute;
	       height: 100px;
	       left: 300px;
	       right: 0;
	       bottom: 0;
	       background-color: grey;
	       text-align: center;
	       overflow: hidden;
	   }
	   
	   .vidcontrols.active {
	       left: 0;
	   }
	   
	   .menu {
	       position: absolute;
	       top: 0;
	       bottom: 0;
	       width: 300px;
		   overflow: scroll;
	   }
	   
	   .menu.active {
	       width: 0px;
	       transform: rotateY(90deg);
	   }

	   .content {
	       position: absolute;
	       top: 0;
	       bottom: 100px;
	       left: 300px;
	       right: 0;
	       overflow: hidden;
	   }
	   
	   .content.active {
	       left: 0;
	   }

	   .footer {
	     flex: 0 1 40px;
	   }
	   
	   .nowrap {
	       white-space: nowrap;
	   }

	   .player-btn {
	     background: none;
	     border: 0;
	     color: white;
	     text-align: center;
	     max-width: 60px;
	     padding: 5px 8px;

	     svg {
	       fill: #FFFFFF;
	     }

	     &:hover,
	     &:focus {
	       border-color: $accent-color;
	       background: rgba(255, 255, 255, .2);
	     }
	   }

	   .player-slider {
	     width: 10px;
	     height: 30px;
	   }


	   progress[value] {
	     -webkit-appearance: none;
	     appearance: none;
	     background-color: white;
	     color: blue;
	     height: 5px;
	   }
	   
	   progress[value]::-webkit-progress-bar {
	     background-color: white;
	     border-radius: 2px;
	     border: 1px solid lighten(#acacac, 20%);
	     color: blue;
	   }
	   
	   progress::-webkit-progress-value {
	     background-color: blue;
	   }

	   .sliders {
	     max-width: 200px;
	     display: flex;
	   }

	   input[type=range] {
	     -webkit-appearance: none;
	     background: transparent;
	     width: 100%;
	     margin: 0 5px;
	   }

	   input[type=range]:focus {
	     outline: none;
	   }

	   input[type=range]::-webkit-slider-runnable-track {
	     width: 100%;
	     height: 8px;
	     cursor: pointer;
	     box-shadow: 1px 1px 1px rgba(0, 0, 0, 0), 0 0 1px rgba(13, 13, 13, 0);
	     background: rgba(255, 255, 255, 0.5);
	     border-radius: 10px;
	     border: 0.2px solid rgba(1, 1, 1, 0);
	   }

	   input[type=range]::-webkit-slider-thumb {
	     height: 15px;
	     width: 15px;
	     border-radius: 50px;
	     background: white;
	     cursor: pointer;
	     -webkit-appearance: none;
	     margin-top: -3.5px;
	     box-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
	   }

	   input[type=range]:focus::-webkit-slider-runnable-track {
	     background: rgba(255, 255, 255, 0.8);
	   }

	   input[type=range]::-moz-range-track {
	     width: 100%;
	     height: 8px;
	     cursor: pointer;
	     box-shadow: 1px 1px 1px rgba(0, 0, 0, 0), 0 0 1px rgba(13, 13, 13, 0);
	     background: #ffffff;
	     border-radius: 10px;
	     border: 0.2px solid rgba(1, 1, 1, 0);
	   }

	   input[type=range]::-moz-range-thumb {
	     box-shadow: 0 0 3px rgba(0, 0, 0, 0), 0 0 1px rgba(13, 13, 13, 0);
	     height: 15px;
	     width: 15px;
	     border-radius: 50px;
	     background: white;
	     cursor: pointer;
	   }
	   
	.php-file-tree {
	   font-size: 15px;
	   line-height: 1.5;
	}

	   .php-file-tree A {
	       color: #000000;
	       text-decoration: none;
	   }
	   
	   .php-file-tree A:hover {
	       color: #666666;
	   }

	   .php-file-tree .open {
	       font-style: italic;
	   }
	   
	   .php-file-tree .closed {
	       font-style: normal;
	   }
	   
	   .php-file-tree .pft-directory {
	       list-style-image: url(images/directory.png);
	   }
	   
	   /* Default file */
	   .php-file-tree LI.pft-file { list-style-image: url(images/file.png); }
	   /* Additional file types */
	   .php-file-tree LI.ext-mpd { list-style-image: url(images/film.png); }
	   
	.bt-menu-trigger {
	   float:left;
	   display: inline;
	   font-size: 14px;
	   position: relative;
	   width: 2em;
	   height: 2em;
	   cursor: pointer;
	}

	.bt-menu-trigger span {
	   position: absolute;
	   top: 50%;
	   left: 0;
	   display: block;
	   width: 100%;
	   height: 0.2em;
	   margin-top: -0.1em;
	   background-color: #fff;
	   -webkit-touch-callout: none;
	   -webkit-user-select: none;
	   -khtml-user-select: none;
	   -moz-user-select: none;
	   -ms-user-select: none;
	   user-select: none;
	   -webkit-transition: background-color 0.3s;
	   transition: background-color 0.3s;
	}


	.bt-menu-trigger span:after,
	.bt-menu-trigger span:before {
	   position: absolute;
	   left: 0;
	   width: 100%;
	   height: 100%;
	   background: #fff;
	   content: '';
	   -webkit-transition: -webkit-transform 0.3s;
	   transition: transform 0.3s;
	}

	.bt-menu-trigger.bt-menu-alt span:before {
	   -webkit-transform: translateY(-0.5em);
	   transform: translateY(-0.5em);
	}

	.bt-menu-trigger.bt-menu-alt span:after {
	   -webkit-transform: translateY(0.5em);
	   transform: translateY(0.5em);
	}

	.bt-menu-trigger span:before {
	   -webkit-transform: translateY(-0.36em) translateX(-0.65em) rotate(-45deg) scaleX(0.6);
	   transform: translateY(-0.35em) translateX(-0.65em) rotate(-45deg) scaleX(0.6);
	}

	.bt-menu-trigger span:after {
	   -webkit-transform: translateY(0.36em) translateX(-0.65em) rotate(45deg) scaleX(0.6);
	   transform: translateY(0.35em) translateX(-0.65em) rotate(45deg) scaleX(0.6);
	}

	.wrapper {
	 margin-left: auto;
	 padding: 8px 16px;
	 border: none;
	 background: #d0dce7;
	 color: #000000;
	 border-radius: 2px;
	 list-style-type: none;
	}
	.form-row {
	display: flex;
	justify-content: flex-end;
	}
	/* ---------------------------------------------------
	   MEDIAQUERIES
	----------------------------------------------------- */
	@media (max-width: 768px), only screen and (-webkit-min-device-pixel-ratio: 2), only screen and (min--moz-device-pixel-ratio: 2), only screen and ( -o-min-device-pixel-ratio: 2/1), only screen and ( min-device-pixel-ratio: 2), only screen and ( min-resolution: 192dpi), only screen and ( min-resolution: 2dppx) {

	   .vidcontrols {
	       left: 0;
	   }
	   
	   .vidcontrols.active {
	       left: 300px;
	   }
	   
	   .menu {
	       width: 0px;
	       transform: rotateY(90deg);
	   }
	   
	   .menu.active {
	       width: 300px;
	   }

	   .content {
	       left: 0;
	   }
	   
	   .content.active {
	       left: 300px;
	   }   

	   .bt-menu-trigger span:before {
	       -webkit-transform: translateY(-0.5em);
	       transform: translateY(-0.5em);
	   }

	   .bt-menu-trigger span:after {
	       -webkit-transform: translateY(0.5em);
	       transform: translateY(0.5em);
	   }

	   .bt-menu-trigger.bt-menu-alt span:before {
	       -webkit-transform: translateY(-0.36em) translateX(-0.65em) rotate(-45deg) scaleX(0.6);
	       transform: translateY(-0.35em) translateX(-0.65em) rotate(-45deg) scaleX(0.6);
	   }

	   .bt-menu-trigger.bt-menu-alt span:after {
	       -webkit-transform: translateY(0.36em) translateX(-0.65em) rotate(45deg) scaleX(0.6);
	       transform: translateY(0.35em) translateX(-0.65em) rotate(45deg) scaleX(0.6);
	   }
	}

	@media only screen and (-webkit-min-device-pixel-ratio: 2), only screen and (min--moz-device-pixel-ratio: 2), only screen and ( -o-min-device-pixel-ratio: 2/1), only screen and ( min-device-pixel-ratio: 2), only screen and ( min-resolution: 192dpi), only screen and ( min-resolution: 2dppx) {
	   body {
	       font-size: 130%;
	   }
	   
	   button {
	       font-size: 130%;
	   }
	   
	   textarea {
	       font-size: 130%;
	   }
	   
	   input[type=file] {
	       font-size: 130%;
	   }
	   
	   input[type=text] {
	       font-size: 130%;
	   }
	   
	   input[type=submit] {
	       font-size: 130%;
	   }
	   
	   select {
	       font-size: 130%;
	   }
	   
	   input[type=password] {
	       font-size: 130%;
	   }   
	   input[type=radio] {
	       width: 20px;
	       height: 20px;
	   }
	}


	</style>
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