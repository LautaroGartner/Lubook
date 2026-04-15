# Lubook

A social network built with Ruby on Rails 8, as a personal project to learn Ruby on Rails.

Built with an emphasis on **user privacy**, **performance caching**, **security hardening**, and **test coverage** from day one — not as an afterthought.

🌐 **Live at [lubook.fly.dev](https://lubook.fly.dev)**

## Status

✅ **All 8 phases complete.** Lubook is live in production: deployed on Fly.io with Postgres on Supabase, persistent image storage on a Fly volume, transactional email via Postmark, and HTTPS everywhere. Sign up, confirm your email, post, follow, like, comment.

## Stack

- **Ruby** 3.4.6
- **Rails** 8.1
- **PostgreSQL** (Postgres.app in dev, Supabase in production)
- **Hotwire** (Turbo + Stimulus) for reactive UI without a SPA
- **Tailwind CSS** for styling
- **Active Storage** with libvips for image uploads and variant processing
- **Solid Cache / Solid Queue / Solid Cable** — database-backed caching, background jobs, and Action Cable (Rails 8 defaults, no Redis needed)
- **Devise** for authentication with email/password + GitHub OAuth via OmniAuth
- **Pundit** for authorization policies
- **Pagy** for pagination
- **Rack::Attack** for rate limiting and brute-force protection
- **Brakeman** for security static analysis
- **bundler-audit** for gem CVE scanning
- **Bullet** for N+1 query detection in development
- **RSpec** + FactoryBot + Faker + shoulda-matchers + Capybara for testing
- **Letter Opener** for previewing mail in development
- **Postmark** for transactional email in production
- **Fly.io** for hosting (gru — São Paulo region)
- **Thruster** as the production web server (HTTP/2, asset caching, X-Sendfile)

## Features

- Email/password signup with mandatory email confirmation
- GitHub OAuth sign-in (scaffolded)
- Account lockout after repeated failed logins, unlockable via email
- Account deletion with cascade cleanup of all owned content
- User directory with case-insensitive username search and pagination
- User profile pages with bio, display name, location, and avatar upload
- Profile editing gated by a Pundit policy (only the owner can edit)
- Follow request flow: send → receiver sees pending list → accept or reject
- Self-follow prevented at the model level
- Followers and following lists, paginated
- Posts with text and optional image, with a live file-picker preview
- Post editing and deletion with Pundit authorization
- Comments on posts, with delete for the comment author or post owner
- Polymorphic likes on both posts and comments, with uniqueness enforcement
- Live like toggling via Turbo Streams — no page reload, no scroll jump
- Live comment posting via Turbo Streams — new comments append without reload, form clears automatically
- Russian-doll fragment caching on the post partial, keyed on `updated_at` and touched by child likes and comments
- Low-level caching of follower and following counts on the profile page, with a 5-minute TTL
- Paginated feed showing posts from the current user plus everyone they follow
- Retina-quality image variants with a click-to-zoom lightbox
- Timestamps with relative-time display and hover-to-see-absolute tooltips
- "Edited" indicator when a post is modified more than a minute after creation
- Branded 400 / 404 / 406 / 422 / 500 error pages that work even when the Rails app is down

## Data model

```
User
 ├── has_one  :profile
 ├── has_many :posts
 ├── has_many :comments
 ├── has_many :likes
 ├── has_many :following  (through accepted follows)
 └── has_many :followers  (through accepted follows)

Profile   belongs_to :user;  has_one_attached :avatar
Post      belongs_to :user;  has_one_attached :image
                              has_many :comments, :likes (polymorphic)
Comment   belongs_to :user, :post (touch: true);  has_many :likes (polymorphic)
Like      belongs_to :user, :likeable (polymorphic, touch: true)
Follow    belongs_to :requester, :receiver (User); enum status { pending, accepted }
```

Key design decisions: likes are polymorphic so one table handles likes on both posts and comments; follows live in a single table with an enum status so a "pending" row is a follow request and flipping it to "accepted" makes someone a follower; every association has a DB-level foreign key with `on_delete: :cascade` so orphaned rows are impossible (and account deletion cascades cleanly); every foreign key and query-hot column is indexed (including a composite `[receiver_id, status]` index for fast follower lookups and a `[user_id, created_at]` index for fast per-user timelines); and likes and comments both `touch` their parent post so that fragment cache keys automatically invalidate when children change — this is what makes Russian-doll caching work.

## Performance & caching

The feed uses **Russian-doll fragment caching**: each post partial is wrapped in a `cache` block keyed on the post's `updated_at`. When a comment or like is added, `touch: true` bumps the parent's timestamp, which changes the cache key and forces a re-render of only that post's partial — every other post in the feed is served from cache. On a warm cache, rendering 20 posts is effectively free.

The like button is rendered outside the cache block inside its own `turbo_frame_tag`. When a user clicks it, the controller responds with a Turbo Stream `replace` directive that swaps only that button's HTML — no page reload, no scroll jump, no flash of unstyled content. Comment creation uses a multi-directive Turbo Stream response that appends the new comment to the list and replaces the form with a fresh empty one in a single request.

Follower and following counts on the profile page use low-level caching via `Rails.cache.fetch` with a 5-minute TTL, keyed on the user record. This avoids running `COUNT` queries on every profile page load.

N+1 queries are monitored in development via the Bullet gem, which logs warnings to the browser console, a footer overlay, and `log/bullet.log` when any controller fires more queries than it should. Feed, profile, and post show pages all preload their required associations (`:user`, `:profile`, `avatar_attachment`, `:likes`, `:comments`, `image_attachment`) in single eager-loaded queries.

In production, **Solid Cache** persists the fragment cache to the same Postgres database that holds the app data, so caches survive deploys. **Solid Queue** runs background jobs (Active Storage image analysis, etc.) without needing Redis. **Thruster** sits in front of Puma to handle HTTP/2 and serve static assets with far-future cache headers.

## Security & privacy posture

Every controller requires authentication by default via a global `before_action :authenticate_user!` in `ApplicationController`. Public pages must explicitly opt out.

Authorization is handled by Pundit policies. Each sensitive action (creating or editing a profile, creating, editing, or deleting a post, accepting a follow request, destroying a follow) runs through an `authorize` call, and a rescue in `ApplicationController` redirects unauthorized users with a flash message instead of leaking a 500. Policies are unit-tested against the full matrix of "is author", "is stranger", and "is nil user" to prevent regressions.

A strict **Content Security Policy** is enforced in production: `default-src 'self'`, scripts and styles limited to same-origin with per-request nonces, `object-src 'none'`, `frame-ancestors 'none'` (clickjacking defense), and `form-action 'self'`. Even if an attacker managed to inject a `<script>` tag into a post body, the browser would refuse to run it. In development the CSP runs in report-only mode so violations are logged but not blocked, making it safe to iterate on.

SSL is forced in production via `config.force_ssl = true`: all HTTP requests are redirected to HTTPS, cookies are marked secure, and HSTS is enabled so browsers refuse to even attempt HTTP on subsequent visits. Fly.io provisions and renews the TLS certificate automatically.

User search uses parameterized SQL with `ILIKE` so user input is never interpolated directly into queries. File uploads are validated for both content type (MIME sniffed from the actual bytes, not the filename) and size at the model level, so a user cannot upload executables or oversized files even by crafting the request manually. Avatars are capped at 5MB; post images at 10MB. Accepted formats are JPEG, PNG, WEBP, and GIF.

Account deletion is wired through Devise's standard `RegistrationsController#destroy`. Because every association uses `dependent: :destroy` at the model level and `on_delete: :cascade` at the database level, deleting a user removes their profile, posts, comments, likes, and follows in a single transaction — no orphaned rows, no leaked data.

Devise is configured with:

- **Confirmable** — new accounts must verify their email before signing in
- **Lockable** — accounts lock after 10 failed attempts and unlock via emailed link
- **Trackable** — sign-in count, timestamps, and IPs are recorded
- **Timeoutable** — sessions expire after 2 weeks of inactivity
- **12-character minimum passwords**, hashed with bcrypt (cost 12)
- **2-hour reset password window** instead of the default longer window

Usernames are normalized to lowercase before validation and enforced unique via a case-insensitive PostgreSQL index (`LOWER(username)`). Follow requests cannot target the requester themselves. Likes enforce uniqueness per `(user, likeable_type, likeable_id)` so a user can like each post or comment at most once.

**Rack::Attack** throttles several endpoints:

- Login — 5 attempts per 20 seconds per IP and per email
- Signup — 3 per hour per IP
- Post creation — 10 per hour per user
- Comment creation — 30 per hour per user
- Follow requests — 20 per hour per user

Per-user throttles use `warden.user.id` as the discriminator so users sharing an IP (dorm rooms, offices, coffee shops) are not collectively punished for one user's behavior.

**Brakeman** is run as part of the hardening checklist and currently reports zero warnings. **bundler-audit** is run against the latest CVE database and currently reports no vulnerable gems. Both tools are installed as part of the dev environment and should be run before any release.

Secrets live in Rails encrypted credentials (`config/credentials.yml.enc`) in development and in Fly.io secrets in production. The Postgres connection string and Postmark API token are never in source control.

## Testing

The test suite is built on **RSpec** with **FactoryBot**, **Faker**, **shoulda-matchers**, and **Capybara**. It's organized by concern so failures point directly to the layer that broke:

- **Model specs** exercise validations, associations, callbacks, scopes, and instance methods like `Post#liked_by?` and `User#cached_followers_count`. They also verify that `touch: true` on comments and likes actually updates the parent post's timestamp — the mechanism Russian-doll caching relies on.
- **Policy specs** use custom `permit_actions` / `forbid_actions` matchers to run every Pundit policy through a full matrix of "is author", "is stranger", and "is nil user" cases. This is how the nil-user regression in `PostPolicy#update?` was caught.
- **Request specs** drive controllers end-to-end via HTTP, with `Devise::Test::IntegrationHelpers` for auth. They cover the happy paths (post creation, follow accept, edit, delete) and the authorization failures (stranger tries to edit someone else's post, requester tries to accept their own follow request).
- **System specs** spin up a fake browser via Capybara's `rack_test` driver and exercise the critical end-to-end flows: signup, creating a post, following a user, liking a post. These catch integration breakage that slips past the isolated unit tests.

Run the suite:

```bash
bundle exec rspec              # full suite
bundle exec rspec spec/models  # just the model specs
bundle exec rspec spec/system  # just the end-to-end specs
```

Every test runs inside a transaction that rolls back after the example, so the test database stays clean. The factories generate unique emails and usernames per sequence so there are no uniqueness collisions between examples.

## Deployment

Lubook runs on **Fly.io** in the `gru` (São Paulo) region:

- **App server**: a single shared-CPU machine, 1GB RAM, scales to zero when idle and back up on demand
- **Database**: Supabase Postgres (free tier), connected via the transaction pooler with `prepared_statements: false` and `advisory_locks: false` to play nicely with PgBouncer
- **Object storage**: a 1GB Fly volume mounted at `/data/storage` for Active Storage uploads — survives every deploy
- **Email**: Postmark for confirmation, password reset, and account unlock messages
- **TLS**: automatic via Fly's edge proxy
- **Logs**: streamed to stdout, captured by `fly logs`

Deploy command from a developer machine:

```bash
fly deploy
```

Fly builds the Dockerfile in their cloud, pushes the image, runs `bin/rails db:prepare` as the release command, then boots the new app machine behind a `/up` health check before swapping traffic over. A typical deploy takes 3–5 minutes.

## Getting started (local development)

```bash
# Prerequisites: Ruby 3.4.6, PostgreSQL running, libvips installed
# On macOS: brew install vips

git clone git@github.com:LautaroGartner/Lubook.git
cd Lubook
bundle install
bin/rails db:create db:migrate db:seed
bin/rails dev:cache     # turn on dev caching to see fragment caching in action
bin/dev
```

Visit `http://localhost:3000` and you'll be redirected to the sign-in page. Create an account — the confirmation email will open automatically in a browser tab via Letter Opener. `db:seed` populates 10 fake users with follows, posts, comments, and likes via Faker.

### Running the checks

```bash
bundle exec rspec                           # Full test suite
bin/brakeman                                # Static security analysis
bundle exec bundler-audit check --update    # Gem CVE scan against the latest DB
```

All three should report zero issues on `main`.

## GitHub OAuth (optional)

To enable "Sign in with GitHub" in development:

1. Register a new OAuth app at https://github.com/settings/developers
   - Homepage URL: `http://localhost:3000`
   - Callback URL: `http://localhost:3000/users/auth/github/callback`
2. Add credentials:

   ```bash
   EDITOR="nano" bin/rails credentials:edit
   ```

   ```yaml
   github:
     client_id: your_client_id_here
     client_secret: your_client_secret_here
   ```

## Roadmap

- [x] **Phase 1** — Rails foundation, Devise + OAuth scaffold, Rack::Attack, Pundit
- [x] **Phase 2** — Data model: Profile, Follow, Post, Comment, polymorphic Like
- [x] **Phase 3** — Profiles, follow requests, users index, Pundit policies
- [x] **Phase 4** — Posts, comments, likes, Active Storage images, lightbox, post editing
- [x] **Mini features** — Pagination, follower/following lists, search, account deletion
- [x] **Phase 5** — Russian-doll fragment caching, Turbo Stream live updates, cached follower counts
- [x] **Phase 6** — Hardening: Bullet, Brakeman, bundler-audit, CSP, force_ssl, rate limits, error pages
- [x] **Phase 7** — RSpec test suite: model, policy, request, and system specs
- [x] **Phase 8** — Production deploy to Fly.io with Supabase Postgres, Postmark email, persistent volume storage

### Post-launch ideas

These aren't required by the Odin Project spec but would be natural next features:

- Frontend polish pass — accent color, custom logo, micro-animations, empty-state personality
- Threaded comment replies
- Notifications (in-app dropdown + email digest)
- @mentions in posts and comments
- Reposts / shares

### Post-launch progress

- [x] **Round 1 polish** — dusty rose accent (`#C97B84`), Cormorant Garamond wordmark, sticky navbar, hover micro-animations, empty states with personality
- [ ] Round 2 — account settings (edit email/password/delete account), Tier 2 polish (like-button animation, skeleton loaders, typography pass)
- [ ] Round 3 — threaded comment replies
- [ ] Round 4 — notifications system (in-app dropdown + unread counter)
- [ ] Round 5 — @mentions in posts/comments
- [ ] Round 6 — reposts/shares

## License

MIT