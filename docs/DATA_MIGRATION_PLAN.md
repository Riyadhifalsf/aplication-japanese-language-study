# Staged Data Migration Strategy

## Prinsip
Migrasi tidak boleh memaksa semua user upgrade data sekaligus.

### Stage 0 — Observe
Tambahkan:
- `schemaVersion`
- migration telemetry
- backup/export capability

### Stage 1 — Read old / write new
- baca format lama;
- normalisasi ke model baru;
- tulis format baru;
- simpan old data sementara.

### Stage 2 — Dual compatibility
- client hanya mengonsumsi model baru;
- remote sync menerima old/new selama grace period.

### Stage 3 — Cleanup
- hapus obsolete fields setelah mayoritas client migrated;
- naikkan minimum app version jika diperlukan.

### Stage 4 — Verify
- checksum;
- row/entity counts;
- sample integrity;
- rollback readiness.

## Migration order
1. app local state
2. progress/mastery
3. review/mistakes
4. curriculum IDs
5. content pack metadata
6. backend schema
7. entitlement/payment
8. analytics/audit

## Rules
- setiap migration punya `up()` dan rollback strategy;
- never silently discard fields;
- nullability change harus bertahap;
- ID remapping harus punya mapping table;
- content references harus divalidasi setelah migrasi.
