// Simple demo app — CI/CD pipeline ka "product" yehi hai.
// Iska kaam sirf itna hai: run ho, aur bata de ke ye kaunsa version/build hai.
// Isse hum pipeline ke end-to-end flow (build -> image -> deploy) ko test kar sakte hain.

const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const BUILD_VERSION = process.env.BUILD_VERSION || 'local-dev';

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from the project1 CI/CD demo app!',
    build: BUILD_VERSION,
    timestamp: new Date().toISOString(),
  });
});

// Health check endpoint - Kubernetes liveness/readiness probes isi tarah ka
// endpoint use karte hain, isliye abhi se practice karna useful hai.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`App running on port ${PORT}, build version: ${BUILD_VERSION}`);
});
