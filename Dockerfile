FROM golang:1.26-alpine AS builder

RUN apk add --no-cache gcc musl-dev sqlite-dev git make

WORKDIR /src
COPY ntfy/ .

RUN go build -ldflags "-s -w" -o /usr/bin/ntfy .

FROM alpine

RUN apk add --no-cache tzdata ca-certificates sqlite-libs

COPY --from=builder /usr/bin/ntfy /usr/bin/ntfy

EXPOSE 80/tcp
ENTRYPOINT ["ntfy"]
