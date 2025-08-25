#!/usr/bin/env bash

# Parameters
# slurm_user*
# slurm_user_db_passwd*

set -e

slurm_user=${slurm_user:-'slurm'}
slurm_user_db_passwd=${slurm_user_db_passwd:?'Environment variable "slurm_user_db_passwd" must be set.'}

sudo mariadb --protocol=socket <<SQL
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Restrict root accounts to localhost / loopback only (keep ones you want)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');

-- Drop test databases if present
DROP DATABASE IF EXISTS test;

-- Remove privileges referencing test DB patterns
DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\_%';

-- Create Slurm user
CREATE USER IF NOT EXISTS '$slurm_user'@'localhost' IDENTIFIED BY '${slurm_user_db_passwd}';
GRANT ALL ON *.* TO '$slurm_user'@'localhost';

FLUSH PRIVILEGES;
SQL
