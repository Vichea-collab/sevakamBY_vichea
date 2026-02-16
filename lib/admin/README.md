# Admin Web Architecture

This admin frontend is separated from the mobile app and uses its own Flutter entrypoint.

## Structure

- `lib/admin/main.dart`
  - admin web entrypoint
- `lib/admin/app/`
  - admin routes and app shell
- `lib/admin/domain/`
  - admin entities and repository contracts
- `lib/admin/data/`
  - backend API client, remote datasource, repository implementation
- `lib/admin/presentation/`
  - state + admin login/dashboard pages

## Run Admin Web Only

```bash
flutter run -d chrome -t lib/admin/main.dart --web-port=8099
```

This does not use the mobile route tree from `lib/main.dart`.

## Backend Dependency

The admin web app calls backend admin APIs:

- `/api/admin/overview`
- `/api/admin/users`
- `/api/admin/orders`
- `/api/admin/posts`
- `/api/admin/tickets`
- `/api/admin/services`

All list endpoints are paginated with max `10` rows per page.

Make sure backend is running first:

```bash
cd lib/backend
npm run dev
```
