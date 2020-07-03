$(document).ready( function() {

	$('#iconShowHideMenu').on('click', function () {
		$('.menu').toggleClass('active');
		$('.content').toggleClass('active');
		
		var menu_img2 = document.getElementById('showhidemenubtn2');
		var menu_img1 = document.getElementById('showhidemenubtn1');
		var src_dir = menu_img1.src;
		src_dir = src_dir.substr(0, src_dir.lastIndexOf("/"))

		var menu_elem = document.getElementById('menu');
		if (menu_elem.classList.contains("active")) {
			menu_img1.src = src_dir + "/open-pane-48.png";
			menu_img2.src = src_dir + "/close-pane-48.png";
		} else {
			menu_img1.src = src_dir + "/close-pane-48.png";
			menu_img2.src = src_dir + "/open-pane-48.png";
		}
		
	   var resizeEvent = window.document.createEvent('UIEvents'); 
	   resizeEvent.initUIEvent('resize', true, false, window, 0); 
	   window.dispatchEvent(resizeEvent);
	});
	
	// Expand or collapse menu on click
	$(".pft-directory A").click( function() {
		$(this).parent().find("UL:first").slideToggle("medium");
		if( $(this).parent().attr('className') == "pft-directory" ) return false;
	});	

	// Expand Selected file in menu
	var urlParams = new URLSearchParams(window.location.search);
	if(urlParams.has("file"))	{
		dash_video = urlParams.get('file')
		path = "";
		var str_array = dash_video.split('/');
		for(var i = 0; i < str_array.length; i++) {
			path += "/" + str_array[i];
			//Set any UL's at this path to be open
			ul_id = btoa("ul" + path); //Base64 ul path
			var element = document.getElementById(ul_id);
			if (element != null) {
				element.classList.add("ul_open");
			}
			//Set any LI' at this path to be open
			li_id = btoa("li" + path); //Base64 li path
			var element = document.getElementById(li_id);
			if (element != null) {
				element.classList.add("li_open");
			}
		}
	}


});
