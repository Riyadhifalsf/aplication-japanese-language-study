use App\Http\Controllers\Api\VocabularyController;

Route::prefix('admin')->group(function () {
    Route::get('vocabulary', [VocabularyController::class, 'index']);
    Route::post('vocabulary', [VocabularyController::class, 'store']);
    Route::put('vocabulary/{vocabulary}', [VocabularyController::class, 'update']);
    Route::delete('vocabulary/{vocabulary}', [VocabularyController::class, 'destroy']);
});
