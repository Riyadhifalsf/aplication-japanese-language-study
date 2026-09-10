# Technical Implementation Contract

## A. Non-negotiable
- Jangan merusak API lama tanpa compatibility layer.
- Semua migration harus idempotent.
- Semua client write harus aman diulang.
- Semua remote feature punya offline fallback yang eksplisit.
- Secret hanya server-side.
- Jangan menganggap data content benar sebelum validator lolos.

## B. Contract layer
### Flutter
`Screen → Controller/Service → Domain → Repository → Local/Remote`

### Backend
`Route → middleware/auth → validation → handler/service → parameterized SQL`

### AI
`Flutter → backend AI route → provider adapter → normalized response`

### Payment
`Flutter → backend/OS billing → verifier → entitlement`

## C. Error model
Semua service eksternal mengembalikan kategori:
- `network`
- `timeout`
- `unauthorized`
- `rate_limited`
- `invalid_request`
- `provider_error`
- `not_configured`

UI wajib membedakan `not_configured` dari `provider_error`.

## D. Idempotency
Mutation API yang membuat order/sync event harus menerima idempotency key.

## E. Observability
Minimal:
- event name;
- anonymous/user ID sesuai privacy;
- timestamp;
- feature;
- result;
- latency;
- error class.

## F. Testing
Critical domains:
- learning engine;
- SRS;
- curriculum unlock;
- sync merge;
- entitlement;
- exam scoring;
- validator.

## G. Backward compatibility
`schemaVersion` wajib di local state dan content packs.
