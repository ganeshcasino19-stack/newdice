// Change the version number with each update to avoid old cache interference
const CACHE = 'ganeshcasino-pwa-v2';
const ASSETS = [
  '/', '/index.html',
  '/ab.html',
  '/dice.html',
  '/mini-wheel.html',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/icons/maskable-512.png',
  '/icons/apple-icon-180.png'
];

// Install: Pre-cache static resources
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Activate: Clean up old cache
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Determine whether to bypass cache (e.g., Supabase / API)
function isBypass(url) {
  try {
    const u = new URL(url);
    if (u.hostname.includes('supabase.co')) return true;
    if (u.pathname.startsWith('/functions/') || u.pathname.startsWith('/rest/')) return true;
    return false;
  } catch {
    return false;
  }
}

// fetch intercept
self.addEventListener('fetch', (e) => {
  const req = e.request;
  const url = new URL(req.url);

  // Only process GET + same-origin static resources
  if (req.method !== 'GET' || url.origin !== location.origin) return;

  // Supabase / API bypass cache
  if (isBypass(req.url)) {
    e.respondWith(fetch(req).catch(() => caches.match(req)));
    return;
  }

  // HTML page: Network first
  if (req.destination === 'document' || req.headers.get('accept')?.includes('text/html')) {
    e.respondWith((async () => {
      try {
        const netRes = await fetch(req);
        const copy = netRes.clone(); // clone first
        caches.open(CACHE).then(c => c.put(req, copy));
        return netRes;
      } catch {
        return caches.match(req) || caches.match('/index.html');
      }
    })());
    return;
  }

  // Other static files: Cache first, update in background
  e.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) {
      // Background update
      fetch(req).then((netRes) => {
        if (netRes && netRes.status === 200) {
          const copy = netRes.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
      });
      return cached;
    } else {
      try {
        const netRes = await fetch(req);
        const copy = netRes.clone();
        caches.open(CACHE).then(c => c.put(req, copy));
        return netRes;
      } catch {
        return caches.match('/index.html');
      }
    }
  })());
});
