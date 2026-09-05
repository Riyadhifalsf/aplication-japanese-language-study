<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vocabulary;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VocabularyController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Vocabulary::query();
        if ($request->filled('level') && $request->string('level')->toString() !== 'Semua') {
            $query->where('level', $request->string('level')->toString());
        }
        if ($request->filled('search')) {
            $search = $request->string('search')->toString();
            $query->where(function ($q) use ($search) {
                $q->where('word', 'like', "%{$search}%")
                  ->orWhere('reading', 'like', "%{$search}%")
                  ->orWhere('meaning', 'like', "%{$search}%");
            });
        }

        return response()->json([
            'data' => $query->orderBy('id')->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'word' => ['required', 'string', 'max:255'],
            'reading' => ['required', 'string', 'max:255'],
            'meaning' => ['required', 'string'],
            'level' => ['required', 'in:N5,N4,N3,N2,N1,Tambahan'],
        ]);

        return response()->json(['data' => Vocabulary::create($data)], 201);
    }

    public function update(Request $request, Vocabulary $vocabulary): JsonResponse
    {
        $data = $request->validate([
            'word' => ['required', 'string', 'max:255'],
            'reading' => ['required', 'string', 'max:255'],
            'meaning' => ['required', 'string'],
            'level' => ['required', 'in:N5,N4,N3,N2,N1,Tambahan'],
        ]);
        $vocabulary->update($data);
        return response()->json(['data' => $vocabulary->fresh()]);
    }

    public function destroy(Vocabulary $vocabulary): JsonResponse
    {
        $vocabulary->delete();
        return response()->json(['message' => 'Kotoba berhasil dihapus.']);
    }
}
