# Lubook

A social network built with Ruby on Rails 8, as a personal project to learn Ruby on Rails.

Built with an emphasis on **user privacy** and **performance caching** from day one — not as an afterthought.

## Status

🚧 **Phase 3 of 8 complete.** Authentication, full data model, and the social graph UI are in place. Users can browse people, send and accept follow requests, and edit their profiles. Posts, feed, and comments arrive in the next phases.

## Stack

- **Ruby** 3.4.6
- **Rails** 8.1
- **PostgreSQL** (via Postgres.app)
- **Hotwire** (Turbo + Stimulus) for reactive UI without a SPA
- **Tailwind CSS** for styling
- **Solid Cache / Solid Queue / Solid Cable** — database-backed caching, background jobs, and Action Cable (Rails 8 defaults, no Redis needed)
- **Devise** for authentication with email/password + GitHub OAuth via OmniAuth
- **Pundit** for authorization policies
- **Rack::Attack** for rate limiting and brute-force protection
- **RSpec** + FactoryBot + Faker + shoulda-matchers for testing
- **Letter Opener** for previewing mail in development

## Features so far

- Email/password signup with mandatory email confirmation
- GitHub OAuth sign-in (scaffolded)
- Account lockout after repeated failed logins, unlockable via email
- User directory with live follow/pending/unfollow states
- User profile pages with bio, display name, and location
- Profile editing gated by a Pundit policy (only the owner can edit)
- Follow request flow: send → receiver sees pending list → accept or reject
- Unfollow and cancel-request actions from either side
- Self-follow prevented at the model level

## Data model

```
User
 ├── has_one  :profile
 ├── has_many :posts
 ├── has_many :comments
 ├── has_many :likes
 ├── has_many :following  (through accepted follows)
 └── has_many :followers  (through accepted follows)

Profile   belongs_to :user
Post      belongs_to :user;  has_many :comments, :likes (polymorphic)
Comment   belongs_to :user, :post;  has_many :likes (polymorphic)
Like      belongs_to :user, :likeable (polymorphic)
Follow    belongs_to :requester, :receiver (User); enum status { pending, accepted }
```

Key design decisions: likes are polymorphic so one table handles likes on both posts and comments; follows live in a single table with an enum status so a "pending" row is a follow request and flipping it to "accepted" makes someone a follower; every association has a DB-level foreign key with `on_delete: :cascade` so orphaned rows are impossible; and every foreign key and query-hot column is indexed (including a composite `[receiver_id, status]` index for fast follower lookups and a `[user_id, created_at]` index for fast per-user timelines).

## Security & privacy posture

Every controller requires authentication by default via a global `before_action :authenticate_user!` in `ApplicationController`. Public pages must explicitly opt out.

Authorization is handled by Pundit policies. Each sensitive action (editing a profile, accepting a follow request, destroying a follow) runs through an `authorize` call, and a rescue in `ApplicationController` redirects unauthorized users with a flash message instead of leaking a 500.

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
# Prerequisites: Ruby 3.4.6, PostgreSQL running, Node not required (importmap)

git clone git@github.com:LautaroGartner/Lubook.git
cd Lubook
bundle install
bin/rails db:create db:migrate db:seed
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
- [ ] **Phase 4** — Posts, comments, likes UI with image uploads
- [ ] **Phase 5** — Feed with Russian-doll fragment caching and Turbo Stream updates
- [ ] **Phase 6** — Hardening: CSP, force_ssl, Brakeman in CI, N+1 elimination
- [ ] **Phase 7** — Test coverage
- [ ] **Phase 8** — Production deploy with real email

## License

MIT