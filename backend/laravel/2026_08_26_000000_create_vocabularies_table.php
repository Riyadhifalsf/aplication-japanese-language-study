<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('vocabularies')) {
            Schema::create('vocabularies', function (Blueprint $table) {
                $table->id();
                $table->string('word');
                $table->string('reading');
                $table->text('meaning');
                $table->string('level', 16)->index();
                $table->timestamps();
            });
            return;
        }

        Schema::table('vocabularies', function (Blueprint $table) {
            if (!Schema::hasColumn('vocabularies', 'word')) $table->string('word')->default('');
            if (!Schema::hasColumn('vocabularies', 'reading')) $table->string('reading')->default('');
            if (!Schema::hasColumn('vocabularies', 'meaning')) $table->text('meaning')->nullable();
            if (!Schema::hasColumn('vocabularies', 'level')) $table->string('level', 16)->default('N5')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vocabularies');
    }
};
