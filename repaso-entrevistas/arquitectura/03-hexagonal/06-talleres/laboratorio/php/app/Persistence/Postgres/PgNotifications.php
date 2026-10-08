<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use App\Persistence\Cursors;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Notification;
use Hex\Application\Port\Notifications;
use Illuminate\Database\ConnectionInterface;

final readonly class PgNotifications implements Notifications
{
    public function __construct(private ConnectionInterface $db) {}

    public function list(?string $orderId, PageRequest $page): Page
    {
        $sql = 'SELECT id::text AS id, order_id::text AS order_id, type, recipient, created_at::text AS created_at FROM notifications WHERE true';
        $params = [];
        if ($orderId !== null) {
            $sql .= ' AND order_id = CAST(:o AS uuid)';
            $params['o'] = $orderId;
        }
        $cursor = Cursors::decodeTime($page->cursor);
        if ($cursor !== null) {
            $sql .= ' AND (created_at, id) < (CAST(:ts AS timestamptz), CAST(:cid AS uuid))';
            [$params['ts'], $params['cid']] = [Rows::bindTime($cursor[0]), $cursor[1]];
        }
        $sql .= ' ORDER BY created_at DESC, id DESC LIMIT :limit';
        $params['limit'] = $page->limit + 1;
        $rows = $this->db->select($sql, $params);
        $more = count($rows) > $page->limit;
        $rows = array_slice($rows, 0, $page->limit);
        $last = end($rows);
        $items = array_map(fn (object $r) => new Notification($r->id, $r->order_id, $r->type, $r->recipient, Rows::time($r->created_at)), $rows);

        return new Page($items, $more && $last !== false ? Cursors::encodeTime(Rows::time($last->created_at), $last->id) : null);
    }
}
