# live_flight_ops_dashboard_frontedn

A new Flutter project.

## Flutter web keyboard assertion

An assertion such as

```text
Should never encounter KeyData when transitMode is rawKeyData.
```

comes from Flutter's web engine while it is processing the pointer event. It
happens before the event reaches an `ElevatedButton` and is not caused by the
button's `onPressed` callback or by the application's theme state.

Do not rely on hot reload after changing the Flutter SDK or web dependencies.
Stop the running application, close every tab for its localhost origin, and
rebuild it from a clean state:

```powershell
flutter channel stable
flutter upgrade
flutter clean
Remove-Item -Recurse -Force .dart_tool, build -ErrorAction SilentlyContinue
flutter pub get
flutter run -d chrome
```

If the assertion remains, clear the localhost site's data in Chrome DevTools
(`Application` > `Storage` > `Clear site data`) and unregister any localhost
service worker under `Application` > `Service workers`. Then close Chrome and
run the application again. `flutter doctor -v` can be used to confirm that the
project is not mixing Flutter installations.

To rule out a browser extension that modifies keyboard or pointer events, run
once in a fresh Chrome profile:

```powershell
flutter run -d chrome --web-browser-flag="--user-data-dir=$env:TEMP\flight-ops-chrome"
```
