-- Drop unused indexes
DROP INDEX IF EXISTS `idx_ca_algorithm`;
--> statement-breakpoint
-- Add kms_certificate_id to certificates table
ALTER TABLE `certificates` ADD `kms_certificate_id` text NOT NULL DEFAULT '';
--> statement-breakpoint
-- Create index for KMS certificate lookups
CREATE INDEX `idx_cert_kms_cert` ON `certificates` (`kms_certificate_id`);
--> statement-breakpoint
CREATE INDEX `idx_ca_kms_cert` ON `certificate_authorities` (`kms_certificate_id`);

--> statement-breakpoint
-- Note: SQLite doesn't support DROP COLUMN directly in all versions
-- We'll need to recreate tables to remove certificate_pem and key_algorithm

-- Recreate certificate_authorities table without certificate_pem and key_algorithm
CREATE TABLE `certificate_authorities_new` (
	`id` text PRIMARY KEY NOT NULL,
	`kms_certificate_id` text NOT NULL,
	`kms_key_id` text NOT NULL,
	`subject_dn` text NOT NULL,
	`serial_number` text NOT NULL,
	`not_before` integer NOT NULL,
	`not_after` integer NOT NULL,
	`status` text DEFAULT 'active' NOT NULL,
	`revocation_date` integer,
	`revocation_reason` text,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
--> statement-breakpoint
-- Copy data from old table
INSERT INTO `certificate_authorities_new`
SELECT
	`id`,
	`kms_certificate_id`,
	`kms_key_id`,
	`subject_dn`,
	`serial_number`,
	`not_before`,
	`not_after`,
	`status`,
	`revocation_date`,
	`revocation_reason`,
	`created_at`,
	`updated_at`
FROM `certificate_authorities`;
--> statement-breakpoint
-- Drop old table and rename new one
DROP TABLE `certificate_authorities`;
--> statement-breakpoint
ALTER TABLE `certificate_authorities_new` RENAME TO `certificate_authorities`;
--> statement-breakpoint
-- Recreate indexes for certificate_authorities
CREATE UNIQUE INDEX `certificate_authorities_serial_number_unique` ON `certificate_authorities` (`serial_number`);
--> statement-breakpoint
CREATE INDEX `idx_ca_serial` ON `certificate_authorities` (`serial_number`);
--> statement-breakpoint
CREATE INDEX `idx_ca_status` ON `certificate_authorities` (`status`);
--> statement-breakpoint
CREATE INDEX `idx_ca_kms_cert` ON `certificate_authorities` (`kms_certificate_id`);

--> statement-breakpoint
-- Recreate certificates table without certificate_pem
CREATE TABLE `certificates_new` (
	`id` text PRIMARY KEY NOT NULL,
	`ca_id` text NOT NULL,
	`kms_certificate_id` text NOT NULL,
	`kms_key_id` text,
	`subject_dn` text NOT NULL,
	`serial_number` text NOT NULL,
	`certificate_type` text NOT NULL,
	`not_before` integer NOT NULL,
	`not_after` integer NOT NULL,
	`status` text DEFAULT 'active' NOT NULL,
	`revocation_date` integer,
	`revocation_reason` text,
	`san_dns` text,
	`san_ip` text,
	`san_email` text,
	`renewed_from_id` text,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL,
	FOREIGN KEY (`ca_id`) REFERENCES `certificate_authorities`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`renewed_from_id`) REFERENCES `certificates_new`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
-- Copy data from old table (if kms_certificate_id was already populated)
INSERT INTO `certificates_new`
SELECT
	`id`,
	`ca_id`,
	COALESCE(`kms_certificate_id`, ''),  -- Use empty string if NULL
	`kms_key_id`,
	`subject_dn`,
	`serial_number`,
	`certificate_type`,
	`not_before`,
	`not_after`,
	`status`,
	`revocation_date`,
	`revocation_reason`,
	`san_dns`,
	`san_ip`,
	`san_email`,
	`renewed_from_id`,
	`created_at`,
	`updated_at`
FROM `certificates`;
--> statement-breakpoint
-- Drop old table and rename new one
DROP TABLE `certificates`;
--> statement-breakpoint
ALTER TABLE `certificates_new` RENAME TO `certificates`;
--> statement-breakpoint
-- Recreate indexes for certificates
CREATE UNIQUE INDEX `certificates_serial_number_unique` ON `certificates` (`serial_number`);
--> statement-breakpoint
CREATE INDEX `idx_certificates_ca_id` ON `certificates` (`ca_id`);
--> statement-breakpoint
CREATE INDEX `idx_certificates_status` ON `certificates` (`status`);
--> statement-breakpoint
CREATE INDEX `idx_certificates_serial` ON `certificates` (`serial_number`);
--> statement-breakpoint
CREATE INDEX `idx_certificates_type` ON `certificates` (`certificate_type`);
--> statement-breakpoint
CREATE INDEX `idx_cert_kms_cert` ON `certificates` (`kms_certificate_id`);
