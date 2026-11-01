# Vendor API notes

Read from the vendor dashboard on 2026-11-01, because the API has no written
documentation yet. Replace this file when the web developer shares one.

- Base URL: `https://washup-vendor.vercel.app/api/v1`
- Replies: `{status, message, data, meta?, pagination?}`. Errors carry an Arabic
  `message` and 4xx/5xx codes.
- Auth: `Authorization: Bearer <access_token>`. On 401 call refresh once, then
  retry. If the server answers refresh with an error, the session is over.
- Filters: the dashboard leaves out empty values and the value `all`.
- Pagination: `pagination.{current_page, per_page, total, last_page, has_next}`.

## Auth and push

| Call | Body |
|---|---|
| `POST /vendor/auth/login` | `{phone, password}`, returns tokens plus `account` |
| `POST /vendor/auth/refresh` | `{refresh_token}` |
| `POST /vendor/auth/logout` | |
| `GET /vendor/auth/me` | |
| `POST /vendor/push/register` | `{token, appVersion}` |
| `POST /vendor/push/unregister` | `{token}` |

## Orders

- `GET /vendor/dashboard?branchId&period`
- `GET /vendor/live?branchId`
- `GET /vendor/orders?view=orders|bookings&tab&source&sort&order&page`
- `GET /vendor/orders/:id`
- `POST /vendor/orders`: `{branchId, source, plate, customerPhone, customerName, serviceIds, scheduledAt, notes}`
- `POST /vendor/orders/:id/actions`: `{action, ...}`
- `POST /vendor/orders/bulk-confirm`: `{ids}`
- `GET /vendor/price-preview?branchId&serviceIds`
- `GET /vendor/recognize?plate&phone`
- `GET /vendor/availability?branchId&date&serviceIds`
- `GET /vendor/search?q`

| Action | Extra fields |
|---|---|
| `confirm`, `check_in`, `complete`, `no_show` | none |
| `start`, `assign` | `staffId` |
| `collect_payment` | `method`, `amountReceived` |
| `discount` | `discountType`, `discountValue`, `reason` |
| `add_service` | `serviceId` |
| `note` | `text` |
| `cancel`, `refund` | `reason` |

## Management

A cancelled order carries `order.cancel` `{reason, byType, byId, at}`. `reason` is free text or a code such as `expired_unconfirmed`, `expired_not_started` or the customer app's `cancel.r1`.

- `GET /vendor/schedule?branchId&date`, `POST /vendor/schedule/blocks` `{branchId, start, end, reason}`, `DELETE /vendor/schedule/blocks/:id`
- `GET|POST /vendor/services`, `PATCH /vendor/services/:id`
- `GET|POST /vendor/offers`, `PATCH /vendor/offers/:id`, `POST /vendor/offers/:id/status` `{enabled}`
- `GET|POST /vendor/staff`, `PATCH /vendor/staff/:id`, `POST /vendor/staff/:id/status` `{active, reason}`, `PUT /vendor/staff/:id/schedule`
- `GET /vendor/shifts?filter&page`, `GET /vendor/shifts/:id`, `POST /vendor/shifts/:id/review` `{status, note}`
- `GET|POST /vendor/day-closing`
- `GET /vendor/customers?page`, `GET /vendor/customers/:id`
- `GET /vendor/reviews?page`, `POST /vendor/reviews/:id/reply` `{text}`, `POST /vendor/reviews/:id/report` `{reason}`
- `GET /vendor/finance?branchId&period`, `GET /vendor/reports?type&from&to`
- `GET /vendor/branches`, `PATCH /vendor/branches/:id`, `PUT /vendor/branches/:id/settings`
- `GET /vendor/audit?page`
- `GET|PUT /vendor/settings`
- `GET /vendor/notifications?filter&page`, `POST /vendor/notifications/:id/read`, `POST /vendor/notifications/read-all`
