<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vocabulary extends Model
{
    protected $fillable = [
        'word',
        'reading',
        'meaning',
        'level',
    ];
}
