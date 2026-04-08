const express = require('express');
const path = require('path');
const compression = require('compression');
const zlib = require('zlib');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// Pre-compress the large 3MB HTML file at startup (Brotli + Gzip)
// Avoids per-request CPU overhead and enables max compression quality
const htmlPath = path.join(__dirname, 'index.html');
let gzippedHtml, brotliHtml, htmlEtag;

(function precompressHtml() {
  const raw = fs.readFileSync(htmlPath);
  htmlEtag = `"${crypto.createHash('md5').update(raw).digest('hex')}"`;
  gzippedHtml = zlib.gzipSync(raw, { level: 9 });
  brotliHtml = zlib.brotliCompressSync(raw, {
    params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 11 }
  });
  console.log(`HTML pre-compressed: ${raw.length}B raw → ${brotliHtml.length}B brotli / ${gzippedHtml.length}B gzip`);
})();

function serveCompressedHtml(req, res) {
  // 304 Not Modified for repeat visits
  if (req.headers['if-none-match'] === htmlEtag) {
    return res.sendStatus(304);
  }
  const ae = req.headers['accept-encoding'] || '';
  res.setHeader('ETag', htmlEtag);
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Vary', 'Accept-Encoding');
  if (ae.includes('br')) {
    res.setHeader('Content-Encoding', 'br');
    res.setHeader('Content-Length', brotliHtml.length);
    return res.end(brotliHtml);
  }
  if (ae.includes('gzip')) {
    res.setHeader('Content-Encoding', 'gzip');
    res.setHeader('Content-Length', gzippedHtml.length);
    return res.end(gzippedHtml);
  }
  return res.sendFile(htmlPath);
}

// Serve pre-compressed HTML for root and SPA fallback
app.get('/', serveCompressedHtml);
app.get('/index.html', serveCompressedHtml);
app.get('/index', serveCompressedHtml);
app.get('/about-csi', serveCompressedHtml);
app.get('/vertical/:verticalId', serveCompressedHtml);
app.get('/vertical/:verticalId/', serveCompressedHtml);

// Gzip compression for all other responses
app.use(compression({ level: 6 }));

// Cache: 24h for JSON data (static between deploys), 1h for other assets
app.use((req, res, next) => {
  if (req.path.endsWith('.json')) {
    res.setHeader('Cache-Control', 'public, max-age=86400');
  }
  next();
});

// Serve static files from the project root
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
app.get('*', serveCompressedHtml);

app.listen(PORT, () => {
  console.log(`CSI Vertical Markets Portal running on port ${PORT}`);
});
