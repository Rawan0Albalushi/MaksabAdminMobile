# Maksab Admin Mobile

Flutter admin dashboard for **Maksab** — connected to UAT backend and Firebase chat.

## Features

- **Dashboard** — order statistics overview
- **Orders** — list, filter, search, status updates
- **Chat** — real-time customer support via Firebase Firestore (same schema as web admin)
- **Settings** — Arabic / English with RTL / LTR
- **Responsive** — phones and tablets

## Backend

Default API: `https://maksab.om/api/v1/`

Override with:

```bash
flutter run --dart-define=BASE_URL=https://maksab.om/
```

## Run

```bash
cd MaksabAdminMobile
flutter pub get
flutter run
```

Use an admin portal account (`admin`, `manager`, `admin.support`, etc.).

## Architecture

```
lib/
  core/          # theme, network, storage, widgets
  features/      # auth, dashboard, orders, chat, settings
  router/        # go_router + shell navigation
```

State: **Riverpod** · HTTP: **Dio** · i18n: **easy_localization**
