require("dotenv").config();
const threshold = process.env.THRESHOLD || 500; // Set your threshold in meters
function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Radius of the Earth in meters
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

function isWithinThreshold(
  buyerLat,
  buyerLon,
  vendorLat,
  vendorLon,
  threshold
) {
  return true;
  const distance = calculateDistance(buyerLat, buyerLon, vendorLat, vendorLon);
  return distance <= threshold;
}

// Example usage
const buyer = { lat: 6.5244, lon: 3.3792 }; // Example buyer coordinates
const vendor = { lat: 6.5248, lon: 3.3795 }; // Example vendor coordinates

if (
  isWithinThreshold(buyer.lat, buyer.lon, vendor.lat, vendor.lon, threshold)
) {
  console.log("The buyer is within the threshold distance of the vendor.");
} else {
  console.log("The buyer is outside the threshold distance of the vendor.");
}

module.exports = {
  calculateDistance,
  threshold,
  isWithinThreshold,
};
