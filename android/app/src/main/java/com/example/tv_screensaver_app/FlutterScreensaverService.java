package com.example.tv_screensaver_app;

import android.service.dreams.DreamService;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.FlutterInjector;

public class FlutterScreensaverService extends DreamService {

    private FlutterEngine flutterEngine;
    private FlutterView flutterView;

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(false);
        setFullscreen(true);

        // Initialize Flutter system
        FlutterInjector.instance().flutterLoader().startInitialization(getApplicationContext());
        FlutterInjector.instance().flutterLoader().ensureInitializationComplete(this, null);

        // Create and configure FlutterEngine
        flutterEngine = new FlutterEngine(this);
        flutterEngine.getNavigationChannel().setInitialRoute("/screensaver");
        flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
        );

        // Attach FlutterView to FlutterEngine
        FlutterSurfaceView surfaceView = new FlutterSurfaceView(this, false); // Changed true to false here
        flutterView = new FlutterView(this, surfaceView);
        flutterView.attachToFlutterEngine(flutterEngine);

        // Set content view
        setContentView(flutterView);
    }

    @Override
    public void onDetachedFromWindow() {
        if (flutterView != null) {
            flutterView.detachFromFlutterEngine();
        }
        if (flutterEngine != null) {
            flutterEngine.destroy();
            flutterEngine = null;
        }
        super.onDetachedFromWindow();
    }
}
