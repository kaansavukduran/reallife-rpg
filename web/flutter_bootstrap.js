{{flutter_js}}
{{flutter_build_config}}

// Serve the renderer with the app; startup must not depend on Google's CDN.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
