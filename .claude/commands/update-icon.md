Update all platform app icons and splash screens from the source image.

Steps:

1. **Verify source image exists**
   - Check: `assets/icons/app_icon.png`
   - If missing: stop and tell the user to place a 1024×1024 PNG at that path first.

2. **Run launcher icons generator**
   - Run: `dart run flutter_launcher_icons`
   - Report: SUCCESS or the error output if it fails.

3. **Run splash screen generator**
   - Run: `dart run flutter_native_splash:create`
   - Report: SUCCESS or the error output if it fails.

4. **Report**
   - List which platforms were updated (Android, iOS, etc.) based on generator output.
   - Remind the user to hot-restart or rebuild the app to see the changes.

If either generator fails, show the exact error and suggest the most likely fix (missing image, wrong format, missing pub get, etc.).
