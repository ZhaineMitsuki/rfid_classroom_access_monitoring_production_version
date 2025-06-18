// Status toggle functionality
document.addEventListener('turbo:load', function() {
    initStatusToggles();
});

document.addEventListener('DOMContentLoaded', function() {
    initStatusToggles();
});

function initStatusToggles() {
    const toggleSwitches = document.querySelectorAll('.toggle-switch');

    if (!toggleSwitches.length) return;

    toggleSwitches.forEach(toggle => {
        // Remove existing event listener to prevent duplicates
        toggle.removeEventListener('change', handleToggleChange);

        // Add event listener for change
        toggle.addEventListener('change', handleToggleChange);
    });
}

function handleToggleChange() {
    const statusBadge = this.closest('td').querySelector('.status-badge');
    if (!statusBadge) return;

    if (this.checked) {
        statusBadge.className = 'status-badge active';
        statusBadge.textContent = 'Active';
    } else {
        statusBadge.className = 'status-badge inactive';
        statusBadge.textContent = 'Inactive';
    }
}