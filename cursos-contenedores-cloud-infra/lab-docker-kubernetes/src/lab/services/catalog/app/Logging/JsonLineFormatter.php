<?php

namespace App\Logging;

use Monolog\Formatter\NormalizerFormatter;
use Monolog\LogRecord;

// G7: una línea JSON por evento, con los mismos campos que los otros tres: time, level, service y msg, y
// después lo que traiga el contexto. El JsonFormatter de Monolog escribe otros nombres (message,
// level_name, datetime) y anida el contexto: un tablero tendría que traducir.
class JsonLineFormatter extends NormalizerFormatter
{
    private const LEVELS = [
        'DEBUG' => 'DEBUG', 'INFO' => 'INFO', 'NOTICE' => 'INFO', 'WARNING' => 'WARN',
        'ERROR' => 'ERROR', 'CRITICAL' => 'ERROR', 'ALERT' => 'ERROR', 'EMERGENCY' => 'ERROR',
    ];

    public function format(LogRecord $record): string
    {
        $line = [
            'time' => $record->datetime->format('Y-m-d\TH:i:s.vP'),
            'level' => self::LEVELS[$record->level->getName()] ?? 'INFO',
            'service' => 'catalog',
            'msg' => $record->message,
        ] + $this->normalize($record->context) + $this->normalize($record->extra);

        return json_encode($line, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)."\n";
    }
}
