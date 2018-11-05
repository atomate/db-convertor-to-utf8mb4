#!/bin/bash

GREEN='\033[0;32m'
LBLUE='\033[0;34m'
NC='\033[0m'

printf "\n\n${GREEN}### Converting MySQL character set ###\n\n"

printf "${NC}Enter the name of the database: "
read -r DB

# Get the MySQL username
printf "${NC}Enter mysql username: "
read -r USERNAME

# Get the MySQL password
printf "${NC}Enter mysql password for user %s:" "$USERNAME"
read -rs PASSWORD


printf "\n\n${LBLUE}### Start... ###${NC}\n\n"


printf "${NC}Update mysql settings${NC}\n"

# disable mysql strict mode.
mysql "$DB" -u"$USERNAME" -p"$PASSWORD" -e "SET GLOBAL sql_mode = '';"

# enable newest file format and large prefix
mysql "$DB" -u"$USERNAME" -p"$PASSWORD" -e "
	SET GLOBAL innodb_file_format = 'BARRACUDA'; 
	SET GLOBAL innodb_file_format_max = 'BARRACUDA'; 
	SET GLOBAL innodb_file_per_table = 'ON'; 
	SET GLOBAL innodb_large_prefix = 'ON';
	"

printf "${NC}Set format row dynamic${NC}\n"

# set format row dynamic to increase maximum column size
(
    mysql "$DB" -u"$USERNAME" -p"$PASSWORD" -e "SHOW TABLES" --batch --skip-column-names \
    | xargs -I{} echo 'ALTER TABLE `'{}'` ROW_FORMAT=DYNAMIC;'
) \
| mysql "$DB" -u"$USERNAME" -p"$PASSWORD"


printf "${NC}Converting db${NC}\n"

# convert db
(
    echo 'ALTER DATABASE `'"$DB"'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    mysql "$DB" -u"$USERNAME" -p"$PASSWORD" -e "SHOW TABLES" --batch --skip-column-names \
    | xargs -I{} echo 'ALTER TABLE `'{}'` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
) \
| mysql "$DB" -u"$USERNAME" -p"$PASSWORD"

# enable mysql strict mode
mysql "$DB" -u"$USERNAME" -p"$PASSWORD" -e "SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';"


printf "\n\n${GREEN}### $DB database done ###${NC}\n\n"
exit
