// app/javascript/channels/rfid_scan_channel.js
import { createConsumer } from "@rails/actioncable";

document.addEventListener("turbo:load", () => {
  const App = window.App || {};
  App.cable = createConsumer();

  App.rfid_scans = App.cable.subscriptions.create("RfidScanChannel", {
    connected() {
      console.log("✅ Connected to RfidScanChannel");
    },

    disconnected() {
      console.log("⚠️ Disconnected from RfidScanChannel");
    },

    received(data) {
      const placeholder = document.getElementById("rfid-uid-placeholder");
      const input = document.getElementById("rfid-uid-input");

      if (data.denied) {
        if (placeholder) placeholder.textContent = "Card is already in use";
        if (input) input.value = ""; // clear value so form doesn't submit
      } else {
        if (placeholder) placeholder.textContent = `${data.uid}`;
        if (input) input.value = data.uid;
      }
    }
  });
});