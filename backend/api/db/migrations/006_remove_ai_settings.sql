-- 006_remove_ai_settings: hapus konfigurasi AI Sensei (LLM eksternal).
--
-- Keputusan produk: tanpa LLM eksternal; adaptivitas murni on-device /
-- deterministik di aplikasi. Endpoint /api/ai/chat dihapus dari server
-- (rute lama 404 ROUTE_NOT_FOUND). Migrasi ini membersihkan baris AI di
-- tabel app_settings (dibuat oleh 004) agar tidak ada secret modelu LLM
-- yang tertinggal di database. Idempoten (aman dijalankan berulang).
DELETE FROM app_settings
WHERE key IN ('GEMINI_API_KEY', 'GEMINI_MODEL', 'AI_RATE_MAX', 'GEMINI_TIMEOUT_MS');
