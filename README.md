# Lubook

A social network built with Ruby on Rails 8, as a personal project to learn Ruby on Rails.

Built with an emphasis on **user privacy** and **performance caching** from day one — not as an afterthought.

## Status

🚧 **Phase 5 of 8 complete.** The feed now uses Russian-doll fragment caching, likes and comments update live via Turbo Streams without page reloads, and follower counts are cached in memory. Posts, profiles, search, follower lists, and account deletion all work. Hardening, tests, and production deploy are still ahead.

## Stack

- **Ruby** 3.4.6
- **Rails** 8.1
- **PostgreSQL** (via Postgres.app)
- **Hotwire** (Turbo + Stimulus) for reactive UI without a SPA
- **Tailwind CSS** for styling
- **Active Storage** with libvips for image uploads and variant processing
- **Solid Cache / Solid Queue / Solid Cable** — database-backed caching, background jobs, and Action Cable (Rails 8 defaults, no Redis needed)
- **Devise** for authentication with email/password + GitHub OAuth via OmniAuth
- **Pundit** for authorization policies
- **Pagy** for pagination
- **Rack::Attack** for rate limiting and brute-force protection
- **RSpec** + FactoryBot + Faker + shoulda-matchers for testing
- **Letter Opener** for previewing mail in development

## Features so far

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
- **Live like toggling via Turbo Streams** — no page reload, no scroll jump
- **Live comment posting via Turbo Streams** — new comments append without reload, form clears automatically
- **Russian-doll fragment caching** on the post partial, keyed on `updated_at` and touched by child likes and comments
- **Low-level caching** of follower and following counts on the profile page, with a 5-minute TTL
- Paginated feed showing posts from the current user plus everyone they follow
- Retina-quality image variants with a click-to-zoom lightbox
- Timestamps with relative-time display and hover-to-see-absolute tooltips
- "Edited" indicator when a post is modified more than a minute after creation

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

Dev caching is enabled via `bin/rails dev:cache` and backed by `MemoryStore`. In production, Solid Cache (Rails 8 default) will back the same cache API against a database table.

## Security & privacy posture

Every controller requires authentication by default via a global `before_action :authenticate_user!` in `ApplicationController`. Public pages must explicitly opt out.

Authorization is handled by Pundit policies. Each sensitive action (editing a profile, editing or deleting a post, accepting a follow request, destroying a follow) runs through an `authorize` call, and a rescue in `ApplicationController` redirects unauthorized users with a flash message instead of leaking a 500.

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

Rack::Attack throttles the login endpoint at 5 attempts per 20 seconds per IP and per email, and the signup endpoint at 3 per hour per IP.

Secrets live in Rails encrypted credentials (`config/credentials.yml.enc`), never in environment files or git.

## Getting started

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
- [ ] **Phase 6** — Hardening: CSP, force_ssl, Brakeman in CI, N+1 elimination, polish pass
- [ ] **Phase 7** — Test coverage
- [ ] **Phase 8** — Production deploy with real email

## License

MIT