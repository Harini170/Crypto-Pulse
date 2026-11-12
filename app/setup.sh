#!/usr/bin/env bash
# One-time setup: generates android/ios platform folders and applies the network config.
set -e
cd "$(dirname "$0")"
flutter create . --project-name crypto_pulse --org com.cryptopulse --platforms android,ios
rm -f test/widget_test.dart

M=android/app/src/main/AndroidManifest.xml
grep -q 'usesCleartextTraffic' "$M" || sed -i.bak 's/<application/<application android:usesCleartextTraffic="true"/' "$M"
grep -q 'android.permission.INTERNET' "$M" || sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
rm -f "$M.bak"

flutter pub get
echo "Done. Start the backend, then: flutter run"
