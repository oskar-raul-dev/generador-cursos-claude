<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Application\Page;
use Hex\Application\PageRequest;

interface Notifications
{
    /** @return Page<Notification> */
    public function list(?string $orderId, PageRequest $page): Page;
}
