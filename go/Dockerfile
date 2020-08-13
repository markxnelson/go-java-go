############################
# STEP 1 build executable binary
############################
FROM golang:1.14-alpine AS builder
# Install git.
# Git is required for fetching the dependencies.
RUN apk update && apk add --no-cache git

WORKDIR /gobuild

RUN git clone https://github.com/markxnelson/go-java-go.git

WORKDIR /gobuild/go-java-go/go

# Build the binary.
# RUN go build -o go_service
#RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o go_service

RUN CGO_ENABLED=0 GOOS=linux go build -o go_service

############################
# STEP 2 build a small image
############################
FROM scratch

WORKDIR /goapp

# Copy our static executable.
COPY --from=builder /gobuild/go-java-go/go/go_service ./

EXPOSE 8080

# Run the binary.
ENTRYPOINT ["/goapp/go_service"]
