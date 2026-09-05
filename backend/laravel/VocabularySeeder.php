<?php

namespace Database\Seeders;

use App\Models\Vocabulary;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class VocabularySeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('seeders/vocabulary.json');
        if (!is_file($path)) {
            throw new RuntimeException("File vocabulary.json tidak ditemukan: {$path}");
        }

        $rows = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
        if (!is_array($rows)) {
            throw new RuntimeException('Format vocabulary.json harus berupa array.');
        }

        $now = now();
        $payload = [];
        foreach ($rows as $row) {
            $payload[] = [
                'id' => (int) ($row['id'] ?? 0),
                'word' => (string) ($row['word'] ?? ''),
                'reading' => (string) ($row['reading'] ?? ''),
                'meaning' => (string) ($row['meaning'] ?? ''),
                'level' => (string) ($row['level'] ?? 'N5'),
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        foreach (array_chunk($payload, 500) as $chunk) {
            Vocabulary::upsert($chunk, ['id'], ['word', 'reading', 'meaning', 'level', 'updated_at']);
        }

        // Sinkronkan sequence PostgreSQL setelah memasukkan ID bawaan.
        if (DB::getDriverName() === 'pgsql') {
            DB::statement("SELECT setval(pg_get_serial_sequence('vocabularies','id'), COALESCE((SELECT MAX(id) FROM vocabularies), 1), true)");
        }
    }
}
