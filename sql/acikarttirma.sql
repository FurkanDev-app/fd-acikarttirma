-- fd-acikarttirma veritabani semasi

CREATE TABLE IF NOT EXISTS `fd_auctions` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `auctioneer`    VARCHAR(64)  NOT NULL,
    `label`         VARCHAR(128) NOT NULL DEFAULT 'Mezat',
    `fee`           INT UNSIGNED NOT NULL DEFAULT 0,
    `state`         VARCHAR(24)  NOT NULL DEFAULT 'scheduled',
    `start_time`    BIGINT       NULL,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `closed_at`     TIMESTAMP    NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fd_auction_lots` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `auction_id`    INT UNSIGNED NOT NULL,
    `lot_index`     INT UNSIGNED NOT NULL DEFAULT 0,
    `type`          VARCHAR(16)  NOT NULL, -- vehicle | business | item
    `label`         VARCHAR(128) NOT NULL,
    `payload`       LONGTEXT     NOT NULL, -- json
    `start_price`   BIGINT       NOT NULL DEFAULT 0,
    `min_increment` BIGINT       NOT NULL DEFAULT 0,
    `buyout_price`  BIGINT       NULL,
    `winner`        VARCHAR(64)  NULL,
    `final_price`   BIGINT       NULL,
    `sold`          TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_auction` (`auction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fd_auction_bids` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `auction_id`    INT UNSIGNED NOT NULL,
    `lot_id`        INT UNSIGNED NOT NULL,
    `bidder`        VARCHAR(64)  NOT NULL,
    `amount`        BIGINT       NOT NULL,
    `is_auto`       TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_lot` (`lot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
