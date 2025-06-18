document.addEventListener('turbo:load', function() {
    const sidebar = document.querySelector('.sidebar');
    const sidebarToggle = document.getElementById('sidebar-toggle');
    const mainContent = document.getElementById('main-content');
    const sidebarOverlay = document.querySelector('.sidebar-overlay');

    if (!sidebar || !sidebarToggle || !mainContent || !sidebarOverlay) {
        console.error('One or more required elements not found');
        return;
    }

    console.log('Sidebar:', sidebar);
    console.log('Toggle:', sidebarToggle);
    console.log('Main content:', mainContent);
    console.log('Overlay:', sidebarOverlay);

    // Toggle sidebar function
    sidebarToggle.addEventListener('click', function(e) {
        console.log('Toggle clicked');

        if (window.innerWidth >= 992) {
            sidebar.classList.toggle('sidebar-collapsed');
            mainContent.classList.toggle('content-expanded');
            console.log('Desktop toggle - sidebar collapsed:', sidebar.classList.contains('sidebar-collapsed'));
        } else {
            sidebar.classList.toggle('sidebar-mobile-active');
            sidebarOverlay.classList.toggle('active');
            console.log('Mobile toggle - sidebar active:', sidebar.classList.contains('sidebar-mobile-active'));
        }
    });

    // Close sidebar when clicking overlay
    sidebarOverlay.addEventListener('click', function() {
        sidebar.classList.remove('sidebar-mobile-active');
        sidebarOverlay.classList.remove('active');
    });

    window.addEventListener('resize', function() {
        if (window.innerWidth >= 992) {
            sidebarOverlay.classList.remove('active');
            sidebar.classList.remove('sidebar-mobile-active');
        } else {
            sidebar.classList.remove('sidebar-collapsed');
            mainContent.classList.remove('content-expanded');
        }
    });
});