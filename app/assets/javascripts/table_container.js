// Table container functionality
document.addEventListener('turbo:load', function() {
    initTableContainers();
});

document.addEventListener('DOMContentLoaded', function() {
    initTableContainers();
});

function initTableContainers() {
    const tableContainers = document.querySelectorAll('.table-container');

    if (!tableContainers.length) return;

    // Handle each table container
    tableContainers.forEach(container => {
        // Function to check if scroll indicator should be shown
        function checkScroll() {
            container.classList.toggle('has-scroll', container.scrollWidth > container.clientWidth);
        }

        // Check on initial load
        checkScroll();

        // Check on window resize
        window.addEventListener('resize', checkScroll);

        // Function to handle scroll events
        function handleScroll() {
            if (container.scrollLeft + container.clientWidth >= container.scrollWidth - 15) {
                container.classList.remove('has-scroll');
            } else {
                container.classList.add('has-scroll');
            }
        }

        // Remove existing event listener to prevent duplicates
        container.removeEventListener('scroll', handleScroll);

        // Add scroll event listener
        container.addEventListener('scroll', handleScroll);

        // Touch events for mobile devices
        if ('ontouchstart' in window) {
            let startX, startScrollLeft;

            // Remove existing event listeners to prevent duplicates
            container.removeEventListener('touchstart', handleTouchStart);
            container.removeEventListener('touchmove', handleTouchMove);
            container.removeEventListener('touchend', handleTouchEnd);

            function handleTouchStart(e) {
                startX = e.touches[0].clientX;
                startScrollLeft = container.scrollLeft;
            }

            function handleTouchMove(e) {
                if (!startX) return;

                const x = e.touches[0].clientX;
                const distance = startX - x;
                container.scrollLeft = startScrollLeft + distance;
            }

            function handleTouchEnd() {
                startX = null;
            }

            container.addEventListener('touchstart', handleTouchStart, { passive: true });
            container.addEventListener('touchmove', handleTouchMove, { passive: true });
            container.addEventListener('touchend', handleTouchEnd, { passive: true });
        }
    });
}