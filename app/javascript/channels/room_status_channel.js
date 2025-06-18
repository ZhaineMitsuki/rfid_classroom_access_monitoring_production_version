// app/javascript/channels/room_status_channel.js
import { createConsumer } from "@rails/actioncable";

document.addEventListener("turbo:load", () => {
    window.App = window.App || {};
    App.cable = App.cable || createConsumer();

    App.room_status = App.cable.subscriptions.create("RoomStatusChannel", {
        connected() {
            console.log("✅ Connected to RoomStatusChannel");
        },

        disconnected() {
            console.log("⚠️ Disconnected from RoomStatusChannel");
        },

        received(data) {
            console.log("📦 Received data from RoomStatusChannel:", data);

            data.forEach(function(item) {
                console.log(`🔍 Looking for room ID ${item.room_id}...`);

                const roomCard = document.querySelector(`[data-room-id="${item.room_id}"]`);
                if (roomCard) {
                    console.log("✅ Found room card", roomCard);

                    const statusElement = roomCard.querySelector('.room-status');
                    if (statusElement) {
                        console.log("🎯 Found status element", statusElement);
                        console.log(`⚙️ Updating to status: ${item.status}`);

                        // Clear all classes first
                        statusElement.className = 'room-status text-center fw-bold';

                        // Add appropriate classes
                        if (item.status === 'time_in') {
                            statusElement.classList.add('text-danger');
                            statusElement.textContent = 'Occupied';
                        } else if (item.status === 'time_out') {
                            statusElement.classList.add('text-success');
                            statusElement.textContent = 'Vacant';
                        } else if (item.status === 'unavailable') {
                            statusElement.classList.add('text-secondary');
                            statusElement.textContent = 'Unavailable';
                        }
                    } else {
                        console.warn("⚠️ No .room-status element found in room card");
                    }
                } else {
                    console.warn(`❌ No card found for room_id=${item.room_id}`);
                }
            });
        }
    });
});