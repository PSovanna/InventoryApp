# Flutter catalog interface

The catalog UI is written in Dart under `lib/views/`. Laravel provides the JSON API and image storage. The former Blade catalog views have been removed.

Start Laravel from the repository root:

```powershell
php artisan storage:link
php -S 127.0.0.1:8000 -t public cors-router.php
```

The development router allows localhost Flutter origins and serves uploaded images with CORS headers. Images are saved by the existing API controllers under `storage/app/public/categories` and `storage/app/public/products`, and exposed at `/storage/...`. The storage link only needs to be created once. You can also use `php artisan serve` for the API.

Run the Flutter interface in another terminal:

```powershell
cd flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Products and Categories support search, add, edit, delete, and optional image uploads (JPG, PNG, WebP, up to 2 MB). Products also support category filtering. Deletion requires confirmation; API validation errors preserve the form. Existing images are kept unless replaced. The overview shows catalog counts and average price.

`main.dart` launches `views/welcome.dart`. Screens and shared UI components are in `lib/views/`, including `catalog_actions.dart`, `catalog_row_actions.dart`, and `catalog_form.dart`; `catalog_service.dart` calls the existing category/product endpoints. The Laravel root URL returns API information; open Flutter for the interface.

For a remote API, pass its address through API_BASE_URL and allow the Flutter web origin in Laravel CORS configuration. Android emulators use http://10.0.2.2:8000/api; physical devices need the server LAN IP. Web scaffolding is included. To add mobile platforms, run `flutter create --platforms=android,ios .` and configure platform networking and image picker permissions.

Check with `flutter analyze` and `flutter test`.

