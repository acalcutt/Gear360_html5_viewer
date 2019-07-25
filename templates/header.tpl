<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<style type="text/css">
	   
	   html, body {
	       height: 100%;
	       width: 100%;
	       font-family: sans-serif;
	   }
	   
	   td {
	       border: 1px solid black;
	   }

	   video {
	       width: 0px;
	       height: 0px;
	   }
	   
	   #progress-bar {
	       width: 20%;
	       display: inline;
	   }

	   #volume {
	       width: 10%;
	   }
	   
	   #playbackRate {
	       width: 10%;
	   }
	   
	   .inline  {
	       display: inline;
	   }

		.center {
			text-align: center;
		}
		
		#projectinfo {
			width: 80%;
			margin-left: auto;
			margin-right: auto;
			border: 1px solid black;
			
		}
		
		.pidesc {
			background-color: #53ad61;
			font-weight: bold;
			width: 180px;
		}
		
		.pitext {
			background-color: #77c984;
		}

	   .vidcontrols {
	       position: absolute;
	       height: 120px;
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
			left: 0;
			width: 300px;
			overflow: scroll;
			background-color: #fff8ea
		}

		.menu.active {
			left: -350px;
			width: 300px;
		}

		.content {
			position: absolute;
			top: 0;
			bottom: 120px;
			left: 300px;
			right: 0;
			overflow: hidden;
		}

		.content.active {
			left: 0;
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
	   
		.php-file-tree {
		   font-size: 15px;
		   line-height: 1.5;
		   background-color: #fff8ea
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
	   font-size: 20px;
	   position: relative;
	   width: 2em;
	   height: 2em;
	   cursor: pointer;
	   margin-left: 20px;
	   margin-top: 40px;
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
			left: -350px;
			width: 300px;
	   }
	   
	   .menu.active {
			left: 0;
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