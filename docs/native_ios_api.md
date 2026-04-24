# Native iOS API Starter

This repo now exposes a minimal `api/v1` contract for a SwiftUI iPhone app.

## Auth

- `POST /api/v1/auth/sign_in`
  - Params: `email`, `password`, optional `device_name`
  - Returns: bearer token, expiry, current user payload
- `DELETE /api/v1/auth/sign_out`
  - Header: `Authorization: Bearer <token>`

Store the token in the iOS Keychain and send it on every API request.

## Current user

- `GET /api/v1/me`
  - Returns the signed-in user's profile plus unread badge counts

## Feed

- `GET /api/v1/feed`
  - Returns posts from the current user and accepted follows

## Post detail

- `GET /api/v1/posts/:id`
  - Returns the post plus a flat comment array
  - `parent_id` lets SwiftUI rebuild threads client-side

## Suggested SwiftUI structure

- `AuthStore`: token persistence and session bootstrap
- `APIClient`: shared `URLSession` wrapper that injects bearer auth
- `FeedViewModel`: loads `/api/v1/feed`
- `PostDetailViewModel`: loads `/api/v1/posts/:id`
- `ProfileStore`: loads `/api/v1/me`

## Immediate next Rails endpoints to add

- `POST /api/v1/posts`
- `POST /api/v1/posts/:id/comments`
- `POST /api/v1/posts/:id/like`
- `DELETE /api/v1/posts/:id/like`
- `GET /api/v1/conversations`
- `GET /api/v1/conversations/:id/messages`
- `POST /api/v1/conversations/:id/messages`
- `GET /api/v1/notifications`
