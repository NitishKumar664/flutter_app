# File Drop — Flutter app

Real Dart/Flutter source for a native Android app: login, Files, Folders,
Chat, Settings. Talks to your existing File Drop server's REST API with
**zero backend changes** — `requireAuth` already accepts HTTP Basic Auth.

I don't have a Flutter/Dart SDK in my environment, so I cannot compile or
run this myself. Every file below has been re-reviewed line-by-line against
your actual `server.js`/`db/schema.js`, and I found and fixed several real
issues in this pass (a `num`/`double` type mismatch, a Dropdown API used on
a too-new Flutter version, an icon constant I wasn't fully certain existed).
You are still the first to actually build it — that's unavoidable without
a compiler on my end.

## What's included

```
pubspec.yaml
.gitignore
.github/workflows/build-android.yml   — builds an APK on GitHub's servers
lib/
  main.dart
  models/
    file_item.dart
    folder_item.dart
    chat_message.dart
  services/
    auth_service.dart      — secure credential storage
    api_client.dart        — Dio HTTP client + Basic Auth interceptor
    file_service.dart      — list/upload/delete files, storage stats
    folder_service.dart    — list/delete folders
    chat_service.dart      — list/send chat messages
    settings_service.dart  — general settings + feature toggles
  screens/
    login_screen.dart
    files_screen.dart
    folders_screen.dart
    chat_screen.dart
    settings_screen.dart
  widgets/
    app_drawer.dart         — shared navigation drawer
```

Not included: `android/` and `ios/` folders. Only Flutter's own `flutter
create` command can generate those correctly — I can't hand-write them
reliably since their exact contents change with every Flutter SDK version.
The GitHub Actions workflow below generates `android/` automatically.

## The whole process, start to finish

### 1. Create a brand new GitHub repository

On GitHub: **+ → New repository**. Name it whatever you like (e.g.
`file-drop-app`). Leave it empty — don't initialize with a README, .gitignore,
or license (avoids merge complications with what you're about to upload).

### 2. Upload every file to the repo ROOT

This is the step that broke last time — everything must land directly at
the repo's top level, not inside any subfolder.

On GitHub's repo page: **Add file → Upload files**. On a phone, the most
reliable way is to open your file manager, select the **contents** of this
package (not a folder wrapping them — go *inside* it and select
`pubspec.yaml`, `.gitignore`, `lib`, and `.github` individually, or drag
them as a group) and drop them into the upload zone. GitHub's upload page
preserves folder structure when you drag folders in, but only if you don't
accidentally wrap everything in one extra outer folder first.

**Verify before continuing**: go to your repo's main Code page. You should
see `pubspec.yaml`, `lib`, and `.github` sitting directly in the file list
— not nested inside a folder called `flutter_app` or anything else.

### 3. Commit

If uploading through the web UI, there's a commit box at the bottom of the
upload page — write a message like "Initial upload" and commit directly to
`main`.

### 4. Run the build

Go to the **Actions** tab. You should see **"Build Android APK"** listed
(it's defined in `.github/workflows/build-android.yml`, which you just
uploaded). Click it, then click **Run workflow** → confirm branch `main` →
**Run workflow**.

If Actions instead shows "Get started with GitHub Actions" (a gallery of
unrelated templates), that means the `.github/workflows/build-android.yml`
file didn't actually land at your repo root — go back to step 2 and check.

### 5. Download the APK

Once the run finishes (green checkmark, usually 3-5 minutes), click into
that run and scroll to the bottom — download the **file-drop-app-apk**
artifact. That's a real installable `.apk`. Transfer it to your phone and
install it (Android will ask you to allow "install from unknown sources"
once, since it's not from the Play Store).

### 6. Log in

Use your File Drop server's URL (e.g. `http://192.168.1.42:3000` or your
real domain) plus an existing admin/owner username and password.

**Security tip**: create a dedicated Admin account via your web dashboard's
Contributors/Users page for the phone app, rather than using your main
owner login — lets you revoke phone access independently later.

## If your server uses plain HTTP (not HTTPS)

Already handled automatically — the workflow patches the generated Android
manifest to allow cleartext traffic on every build, since `android/` isn't
committed to git and gets regenerated fresh each run.

## What this app does NOT do

Sharing/links, Contributors, API Keys, Webhooks, Support, Analytics, AI
features, Nearby Sharing, and the storage-backend/SMTP/AI parts of
Settings — none of it. Scoped deliberately. Tell me what breaks (or
doesn't) once this is running on your actual device, and we'll go from
there.
