<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\User;
use Hex\Application\Port\Users;
use Hex\Application\Role;
use Illuminate\Database\ConnectionInterface;

final readonly class PgUsers implements Users
{
    public function __construct(private ConnectionInterface $db) {}

    public function findByEmail(string $email): ?User
    {
        $rows = $this->db->select('SELECT id::text AS id, email, password_hash, role FROM users WHERE email = :email', ['email' => $email]);

        return $rows === [] ? null : self::toUser($rows[0]);
    }

    public function findById(string $id): ?User
    {
        $rows = $this->db->select('SELECT id::text AS id, email, password_hash, role FROM users WHERE id = CAST(:id AS uuid)', ['id' => $id]);

        return $rows === [] ? null : self::toUser($rows[0]);
    }

    private static function toUser(object $row): User
    {
        return new User($row->id, $row->email, $row->password_hash, Role::from(strtoupper($row->role)));
    }
}
