"""Pure ASGI sliding-window rate limiter middleware (HTTP-safe, WebSocket passthrough)."""
from __future__ import annotations

import json
import time
from collections import defaultdict, deque

from app.config import settings


class RateLimitMiddleware:
    def __init__(self, app, max_requests: int | None = None, window_seconds: int | None = None) -> None:
        self.app = app
        self.max_requests = max_requests or settings.rate_limit_requests
        self.window_seconds = window_seconds or settings.rate_limit_window_sec
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    async def __call__(self, scope, receive, send) -> None:
        if scope["type"] != "http" or scope.get("path") in {"/health", "/docs", "/openapi.json"}:
            await self.app(scope, receive, send)
            return
        client = scope.get("client")
        client_ip = client[0] if client else "unknown"
        now = time.monotonic()
        bucket = self._hits[client_ip]
        while bucket and now - bucket[0] > self.window_seconds:
            bucket.popleft()
        if len(bucket) >= self.max_requests:
            body = json.dumps({"detail": "Rate limit exceeded. Please try again shortly."}).encode("utf-8")
            await send({
                "type": "http.response.start",
                "status": 429,
                "headers": [(b"content-type", b"application/json")],
            })
            await send({"type": "http.response.body", "body": body})
            return
        bucket.append(now)
        await self.app(scope, receive, send)
