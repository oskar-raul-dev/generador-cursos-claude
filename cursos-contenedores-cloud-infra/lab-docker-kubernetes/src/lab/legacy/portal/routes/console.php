<?php

use Illuminate\Support\Facades\Schedule;

// Todas las noches a las 2:00. Un producto nuevo tarda un día en aparecer en el portal.
Schedule::command('catalog:sync')->dailyAt('02:00');
