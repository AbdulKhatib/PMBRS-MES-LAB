# PMBRS — API Reference

Base URL: `http://<app-tier-public-ip>:8080`

All endpoints are read-only (GET) and return JSON, except `/` which returns plain text. There is no authentication layer in this version — see `scope.md` for what is explicitly out of scope.

## GET /

Basic liveness check for the Flask application itself, independent of the database.

**Response:** `text/plain`
```
PMBRS is alive
```

## GET /health

Application and database health check. Attempts a real query against Oracle (`SELECT 1 FROM dual`) rather than just confirming the Flask process is running — this is the deployment verification endpoint referenced in `scope.md` and used during CI/CD pipeline stages.

**Response:** `application/json`
```json
{
  "application": "OK",
  "database": "OK",
  "version": "1.0.0"
}
```

If the database connection fails, `database` will contain `"FAIL: <error detail>"` instead of `"OK"`, and the application will still respond (it does not crash on a database outage) — this is deliberate, so the health check itself remains a reliable signal even when the database tier is down.

## GET /batches

Returns all production batches, most recent first.

**Response:** `application/json`
```json
[
  {
    "BATCH_NUMBER": "BATCH-1003",
    "PRODUCT_CODE": "PRD-A",
    "STATUS": "FAILED",
    "START_TIME": "Mon, 07 Sep 2026 03:19:26 GMT",
    "END_TIME": "Mon, 07 Sep 2026 03:19:26 GMT"
  }
]
```

## GET /equipment

Returns all equipment records with current status.

**Response:** `application/json`
```json
[
  {
    "EQUIPMENT_NAME": "FILL-01",
    "AREA": "Filling",
    "STATUS": "RUNNING",
    "LAST_UPDATED": "..."
  }
]
```

## GET /events

Returns production events, most recent first, joined to their associated batch and equipment names.

**Response:** `application/json`
```json
[
  {
    "EVENT_TYPE": "FAILURE",
    "DESCRIPTION": "Batch 1003 failed - equipment fault",
    "SEVERITY": "CRITICAL",
    "EVENT_TIMESTAMP": "...",
    "BATCH_NUMBER": "BATCH-1003",
    "EQUIPMENT_NAME": "FILL-02"
  }
]
```

## Known Limitations (current version)

- No pagination — all rows are returned on every call. Acceptable at current data volume; would need addressing before any real-scale use.
- No authentication or authorization.
- Each request opens and closes its own database connection rather than using a connection pool. Simplest correct approach for this stage; connection pooling is a reasonable later optimization, not a current defect.
- JSON field names are uppercase, reflecting Oracle's default column-name casing — not yet normalized to a consistent API convention (e.g. lowercase/camelCase).
