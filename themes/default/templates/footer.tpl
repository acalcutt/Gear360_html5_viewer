    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const menuToggle = document.getElementById('mobile-menu-toggle');
            const menuContainer = document.getElementById('mobile-menu-container');
            const menuClose = document.getElementById('mobile-menu-close');

            //Initialise menuOverlay
            overlay = document.getElementsByClassName('menu-overlay')[0];
            overlay.style.display = 'none';

            // Function to open menu
            function openMenu() {
                menuContainer.classList.add('menu-open');
                overlay.style.display = 'block'; // Show overlay
            }

            // Function to close menu
            function closeMenu() {
                menuContainer.classList.remove('menu-open');
                overlay.style.display = 'none'; // Hide overlay
            }

            //Event to open the menu with the burger menu
            if (menuToggle && menuContainer) {
                menuToggle.addEventListener('click', function() {
                    //Toggles the menu to be opened
                    if (menuContainer.classList.contains('menu-open')) {
                        closeMenu();
                    } else {
                        openMenu();
                    }
                });
            }

            // Event to close the menu with the close button
            if (menuClose && menuContainer) {
                menuClose.addEventListener('click', function() {
                    closeMenu();
                });
            }

            // Event to close the menu when overlay is clicked
            overlay.addEventListener('click', function() {
                closeMenu();
            });

             // Prevent page reload on folder expansion
            const fileTree = document.getElementById('menu');
            if (fileTree) {
                fileTree.addEventListener('click', function(event) {
                    const target = event.target; // Get the clicked element

                    // Check if the clicked element is a directory LI (not a link)
                    if (target.tagName === 'LI' && target.classList.contains('pft-directory')) {
                        const subMenu = target.querySelector('ul'); // Find the sub-menu (UL)
                        if (subMenu) {
                            subMenu.style.display = (subMenu.style.display === 'none' || subMenu.style.display === '') ? 'block' : 'none';
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>