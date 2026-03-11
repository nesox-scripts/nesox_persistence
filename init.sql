CREATE TABLE IF NOT EXISTS `persistent_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(12) NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `props` LONGTEXT NOT NULL,
    `inventory` LONGTEXT DEFAULT NULL,
    `state` LONGTEXT DEFAULT NULL, -- Engine health, body health, tire state, fuel, etc.
    `coords` LONGTEXT NOT NULL, -- JSON {x, y, z, h}
    `tarp_prop` INT DEFAULT 0, -- Tarp visibility/prop state
    `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
