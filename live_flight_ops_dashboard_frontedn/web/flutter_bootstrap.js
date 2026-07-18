{{flutter_js}}
{{flutter_build_config}}

// The dashboard continuously repaints map tiles and live aircraft markers.
// Some browser/GPU combinations lose the WebGL context under that workload.
// CanvasKit's context-loss callback can run before the Flutter web surface has
// finished initializing, which produces a _handledContextLostEvent
// LateInitializationError instead of recovering. Use CanvasKit's CPU backend
// so the application does not depend on a WebGL context.
_flutter.loader.load({
  config: {
    renderer: 'canvaskit',
    canvasKitForceCpuOnly: true,
  },
});
