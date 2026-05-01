const express = require('express');
const path = require('path');
const compression = require('compression');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

function cacheFile(filePath) {
  const raw = fs.readFileSync(filePath);
  const etag = `"${crypto.createHash('md5').update(raw).digest('hex')}"`;
  console.log(`Cached ${path.basename(filePath)}: ${raw.length}B`);
  return {
    raw,
    etag,
    contentType: filePath.endsWith('.json') ? 'application/json; charset=utf-8' : 'text/html; charset=utf-8'
  };
}

const cached = {
  index: cacheFile(path.join(__dirname, 'index.html')),
  training: cacheFile(path.join(__dirname, 'CSITrainingManual.html')),
  tam: cacheFile(path.join(__dirname, 'CSISmallTAMAdvantageReport.html')),
  data: cacheFile(path.join(__dirname, 'CSI_Verticals_Data.json')),
};

// Gzip compression for HTML/JSON responses. Keep this before route handlers so
// startup stays fast on small Azure App Service workers.
app.use(compression({ level: 6 }));

function serveCached(entry, cacheControl) {
  return function(req, res) {
    if (req.headers['if-none-match'] === entry.etag) {
      return res.sendStatus(304);
    }
    res.setHeader('ETag', entry.etag);
    res.setHeader('Cache-Control', cacheControl || 'no-cache');
    res.setHeader('Content-Type', entry.contentType);
    return res.end(entry.raw);
  };
}

const serveIndex = serveCached(cached.index, 'no-cache');
const serveTraining = serveCached(cached.training, 'public, max-age=3600');
const serveTam = serveCached(cached.tam, 'public, max-age=3600');
const serveData = serveCached(cached.data, 'public, max-age=86400');

// SPA routes → index.html
app.get('/', serveIndex);
app.get('/index.html', serveIndex);
app.get('/index', serveIndex);
app.get('/about-csi', serveIndex);
app.get('/how-to-use', serveIndex);
app.get('/vertical/:verticalId', serveIndex);
app.get('/vertical/:verticalId/', serveIndex);

app.get('/CSITrainingManual.html', serveTraining);
app.get('/CSISmallTAMAdvantageReport.html', serveTam);
app.get('/CSI_Verticals_Data.json', serveData);

// Serve other static files with caching
app.use(express.static(path.join(__dirname), {
  index: false,
  maxAge: '1h',
  setHeaders(res, filePath) {
    if (filePath.endsWith('.html')) {
      res.setHeader('Cache-Control', 'no-cache');
    }
  }
}));

// SPA fallback
app.get('*', serveIndex);

app.listen(PORT, () => {
  console.log(`CSI Vertical Markets Portal running on port ${PORT}`);
});
