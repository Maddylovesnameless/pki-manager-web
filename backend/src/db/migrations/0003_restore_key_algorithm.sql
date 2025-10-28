-- Restore key_algorithm column to certificate_authorities table
ALTER TABLE `certificate_authorities` ADD `key_algorithm` text;
