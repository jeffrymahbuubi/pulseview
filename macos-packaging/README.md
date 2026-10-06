# macOS arm64 packaging

These scripts build and package PulseView as a self-contained `PulseView.app` for Apple Silicon.

Full documentation (why this fork exists, how to launch the app, requirements, limitations, source commits and rebuild steps) is in the [repository README](../README.md).

Run order: `1-build-libs.sh`, `2-build-pulseview.sh`, `3-package-app.sh`.
