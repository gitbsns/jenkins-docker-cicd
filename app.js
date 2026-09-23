const express = require('express');
const app = express();
const port = process.env.APP_PORT || 3000;

// ConfigMap se aane wale values
const appName = process.env.APP_NAME || 'MyApp';
const appEnv = process.env.APP_ENV || 'development';
const logLevel = process.env.LOG_LEVEL || 'info';

// Secret se aane wali values (masked rakhenge)
const hasSessionSecret = !!process.env.SESSION_SECRET;

app.get('/', (req, res) => {
    res.send(`Hello DevOps! ${appName} is running successfully in ${appEnv} mode.`);
});

app.get('/info', (req, res) => {
    res.json({
        app: appName,
        environment: appEnv,
        logLevel: logLevel,
        sessionSecretLoaded: hasSessionSecret,
        pod: process.env.HOSTNAME || 'unknown',
        port: port
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`[${logLevel.toUpperCase()}] ${appName} running on port ${port} in ${appEnv} mode`);
});
