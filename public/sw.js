// Minimal service worker: lets the app shell open without a network round
// trip and makes the PWA installable. Task data always comes from Supabase
// over the network and is never cached here.
const CACHE = "wms-shell-v1"
const BASE = new URL("./", self.location).pathname // "/wms-claude-code/"

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.add(BASE)))
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  )
  self.clients.claim()
})

self.addEventListener("fetch", (event) => {
  const { request } = event
  const url = new URL(request.url)
  if (request.method !== "GET" || url.origin !== self.location.origin) return

  // Page loads: network first so a new deploy shows up right away, cached
  // shell as the offline fallback (every route is the same index.html).
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone()
          caches.open(CACHE).then((cache) => cache.put(BASE, copy))
          return response
        })
        .catch(() => caches.match(BASE))
    )
    return
  }

  // Built assets have content hashes in their names, so cache-first is safe.
  if (url.pathname.startsWith(BASE + "assets/")) {
    event.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ??
          fetch(request).then((response) => {
            const copy = response.clone()
            caches.open(CACHE).then((cache) => cache.put(request, copy))
            return response
          })
      )
    )
  }
})
