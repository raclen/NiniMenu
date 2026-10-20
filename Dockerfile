# ─── Stage 1: Build Frontend ───
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install

COPY frontend/ ./
RUN npm run build

# ─── Stage 2: Build Backend ───
FROM golang:1.25-alpine AS backend-builder
WORKDIR /app/backend

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./
# Copy frontend dist to backend/static
COPY --from=frontend-builder /app/frontend/dist /app/backend/static

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/ninimenu ./cmd/server

# ─── Stage 3: Runtime ───
FROM alpine:3.20
WORKDIR /app

RUN apk --no-cache add ca-certificates tzdata

# Create runtime directories
RUN mkdir -p /app/data /app/uploads /app/uploads_backup

COPY --from=backend-builder /app/ninimenu /app/ninimenu
COPY --from=backend-builder /app/backend/static /app/static
COPY --from=backend-builder /app/backend/uploads /app/uploads

ENV PORT=10000
ENV DB_PATH=/app/data/ninimenu.db
ENV UPLOAD_DIR=/app/uploads
ENV BACKUP_DIR=/app/uploads_backup

EXPOSE 10000

CMD ["/app/ninimenu"]
