# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

ntfy is a simple HTTP-based pub-sub notification service. The repository contains:
- **Go server/client** (`main.go`, `cmd/`, `server/`) - the core server and CLI
- **React web app** (`web/`) - single-page app for subscribing/publishing
- **MkDocs documentation** (`docs/`) - served from the server

All three components are built into a single binary using `go:embed` for the web app and docs.

## Development commands

### Quick development cycle
```bash
# Run tests
make test

# Run tests with race detector
make race

# Run single test (e.g., server tests)
go test -v ./server/...

# Build server/client for current architecture
CGO_ENABLED=1 go run main.go serve

# Build everything (web + docs + server) - SLOW
make build

# Build web app only
make web

# Build docs only
make docs

# Run full check (tests, linters, formatters)
make check
```

### Building binaries
```bash
# Build Linux amd64 binary (without web/docs - fast)
make cli-linux-amd64

# Build macOS server (for local dev)
make cli-darwin-server

# Build with GoReleaser (all architectures)
make cli
```

### Web app development
```bash
cd web
npm install    # or: make web-deps
npm start      # Dev server at http://127.0.0.1:3000
npm run build  # Production build to ../server/site
```

### Documentation development
```bash
make docs-venv      # Create Python venv
make docs-deps      # Install mkdocs dependencies
mkdocs serve        # Live-reload at http://127.0.0.1:8000
```

## Architecture

### Entry points
- `main.go` - CLI entry point, uses `urfave/cli/v2`
- `cmd/` - CLI commands (`serve`, `publish`, `subscribe`, `access`, `user`, `tier`, `token`, `webpush`)
- `server/server.go` - Main HTTP server implementation

### Core server abstractions

**Topic** (`server/topic.go`)
- A channel to which subscribers can subscribe and publishers can publish messages
- Topics are created on-demand and expunged from memory after 16 hours of inactivity
- Subscribers are callback functions invoked for each new message

**Visitor** (`server/visitor.go`)
- Represents an API user (identified by IP or authenticated user)
- Contains rate limiters for requests, messages, emails, calls, subscriptions, bandwidth
- Implements token bucket rate limiting using `golang.org/x/time/rate`

**Server** (`server/server.go`)
- Main HTTP server with optional HTTPS, Unix socket, and SMTP servers
- Manages topics map, visitors map, Firebase client, message cache, web push store, attachment store
- Uses `go:embed` to serve static files from `server/docs` and `server/site`

### Key subsystems

**Message cache** (`message/`, `db/`)
- SQLite-based (via `github.com/mattn/go-sqlite3`) or PostgreSQL (`db/pg/`)
- Messages cached with configurable TTL (default 12 hours)
- Supports poll-based fetching for subscribers who missed messages

**Attachment store** (`attachment/`)
- File-based or S3-compatible storage
- Size limits, expiry, bandwidth tracking per visitor
- Attachments are deleted after expiry (default 3 hours)

**User management** (`user/`)
- Optional authentication and tiered access control
- User tiers define limits (messages, emails, reservations, attachment size/bandwidth)
- Access control via topic permissions (ACLs)

**Web push** (`webpush/`)
- VAPID-based web push notifications
- Subscription management in SQLite or PostgreSQL

**External services**
- Firebase FCM (`server/server_firebase.go`) - can be disabled with dummy build tag
- Matrix push gateway (`server/server_matrix.go`)
- Stripe payments (`server/server_payments.go`) - can be disabled with dummy build tag
- Twilio calls (`server/server_twilio.go`) - always present

### Configuration
- Loaded from YAML file (`server/server.yml` or `/etc/ntfy/server.yml`)
- Environment variables with `NTFY_` prefix
- Command-line flags (see `cmd/*.go`)

## Important patterns

### CGO requirement
The server requires `CGO_ENABLED=1` because it uses `github.com/mattn/go-sqlite3` which depends on C.
When building without GoReleaser, always set `CGO_ENABLED=1`.

### Static file embedding
- `server/docs` and `server/site` directories are embedded using `//go:embed`
- During development, run `make cli-deps-static-sites` to create dummy files if you don't need the actual web/docs
- For production builds, run `make web` and `make docs` to populate these directories first

### HTTP routing
Routes are defined using regex patterns in `server/server.go`:
- `topicPathRegex`: `^/[-_A-Za-z0-9]{1,64}$`
- `jsonPathRegex`, `ssePathRegex`, `wsPathRegex` for subscription endpoints
- `publishPathRegex` for publishing messages

### Message flow
1. Publisher sends PUT/POST to `/{topic}` or `/{topic}/publish`
2. Server creates/retrieves `topic` from `Server.topics` map
3. Message is published to topic (calls all subscriber callbacks)
4. Subscribers (HTTP, SSE, WebSocket) receive message
5. Optionally: Firebase FCM, web push, email, SMS, Matrix, Twilio calls

### Testing patterns
- Tests are co-located with source files (`*_test.go`)
- Race tests are split into `server_race_on_test.go` and `server_race_off_test.go`
- Use `go test -v ./...` to run tests (excluding `v2/test`, `v2/examples`, `v2/tools`)

### Conditional builds
- Firebase support: `server_firebase_dummy.go` is used when Firebase is not available
- Payments: `server_payments_dummy.go` replaces Stripe integration when not configured
- Platform-specific files: `config_unix.go`, `config_windows.go`, `serve_*.go`, `publish_*.go`, `subscribe_*.go`
