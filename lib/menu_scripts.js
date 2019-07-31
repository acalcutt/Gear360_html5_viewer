$(document).ready( function() {
	// Expand or collapse menu on click
	$(".pft-directory A").click( function() {
		$(this).parent().find("UL:first").slideToggle("medium");
		if( $(this).parent().attr('className') == "pft-directory" ) return false;
	});	

	// Expand Selected video in menu
	var urlParams = new URLSearchParams(window.location.search);
	dash_video = urlParams.get('video')

	path = "";
	var str_array = dash_video.split('/');
	for(var i = 0; i < str_array.length; i++) {
		path += "/" + str_array[i];
		ul_id = btoa("ul" + path);
		li_id = btoa("li" + path);
		
		var element = document.getElementById(ul_id);
		if (element != null) {
			element.classList.add("ul_open");
		}

		var element2 = document.getElementById(li_id);
		if (element2 != null) {
			element2.classList.add("li_open");
		}
	}

	// Menu container toggle button
	$('.bt-menu-trigger').on('click', function () {
	   $('.menu').toggleClass('active');
	   $('.vidcontrols').toggleClass('active');
	   $('.content').toggleClass('active');
	   $(this).toggleClass('bt-menu-alt');

	   var resizeEvent = window.document.createEvent('UIEvents'); 
	   resizeEvent.initUIEvent('resize', true, false, window, 0); 
	   window.dispatchEvent(resizeEvent);
	});
});
