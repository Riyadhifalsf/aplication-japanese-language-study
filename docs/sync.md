# Sync (offline-first)

Lokal (SharedPreferences) sumber utama. Setiap mutasi:
`markProgressDirty(fields)` → `_touchFields` (timestamp per-field) →
debounce push 3 dtk → `syncNow()`: pull → `merge()` → apply →
push balik. Merge: counter max, set ID union, skor max/key, config
last-write-wins via `fieldUpdatedAt`, journal union cap 2000.
`listenRemote` untuk multi-device live. Union TIDAK BISA menghapus —
reset = hapus dokumen server (`deleteRemote`) + lokal ("Mulai dari nol").
`PUT /api/me/progress` idempoten (replace penuh milik sendiri).
Konflik: timestamp per-field menang; antar-device terakhir-menang per field.
