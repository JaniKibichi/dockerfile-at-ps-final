#!/bin/bash

echo "=> Creating database playSMS in MySQL"
/create_db.sh playsms

/usr/bin/mysqld_safe >/dev/null 2>&1 &

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

cd /app

INSTALLCONF="./install.conf"

. $INSTALLCONF




# ========================================
# DO NOT CHANGE ANYTHING BELOW THIS LINE #
# UNLESS YOU KNOW WHAT YOU'RE DOING      #
# ========================================





clear
echo
echo "playSMS Install Script for Ubuntu"
echo
echo "=================================================================="
echo "WARNING:"
echo "- This install script WILL NOT upgrade currently installed playSMS"
echo "- This install script WILL REMOVE your current playSMS database"
echo "- Please backup before proceeding"
echo "=================================================================="
echo

USERID=$(id -u)
if [ "$USERID" != "0" ]; then
	echo "ERROR: You need to run this script as root"
	echo
	exit 1
fi

echo "INSTALL DATA:"
echo

echo "MySQL username      = $DBUSER"
echo "MySQL password      = $DBPASS"
echo "MySQL database      = $DBNAME"
echo "MySQL host          = $DBHOST"
echo "MySQL port          = $DBPORT"
echo
echo "Web server user     = $WEBSERVERUSER"
echo "Web server group    = $WEBSERVERGROUP"
echo
echo "playSMS source path = $PATHSRC"
echo
echo "playSMS web path    = $PATHWEB"
echo "playSMS lib path    = $PATHLIB"
echo "playSMS bin path    = $PATHBIN"
echo "playSMS log path    = $PATHLOG"
echo

echo
echo "=================================================================="
echo
echo "Installation is in progress"
echo
echo "Do not press [Control+C] until this script ends"
echo
echo "=================================================================="
echo

sleep 3

echo "Getting composer from https://getcomposer.com"
echo
echo "Please wait while the install script downloading composer"
echo

php -r "readfile('https://getcomposer.org/installer');" | php >/dev/null 2>&1

if [ -e "./composer.phar" ]; then
	#rm -f /usr/local/bin/composer /usr/local/bin/composer.phar >/dev/null 2>&1
	rm -f ./composer >/dev/null 2>&1
	ln -s ./composer.phar ./composer >/dev/null 2>&1
	#mv composer composer.phar /usr/local/bin/ >/dev/null 2>&1
	#chmod +x /usr/local/bin/composer /usr/local/bin/composer.phar >/dev/null 2>&1
	chmod +x ./composer.phar >/dev/null 2>&1

	echo "Composer is ready in this folder"
	echo
	echo "Please wait while composer getting and updating required packages"
	echo

	if [ -x "./composer.phar" ]; then
		./composer.phar update
	else
		echo "ERROR: unable to get composer from https://getcomposer.com"
		echo
		exit 1
	fi

	echo
	echo "Composer has been installed and packages has been updated"
	echo
else
	echo "ERROR: unable to get composer from https://getcomposer.com"
	echo
	exit 1
fi

sleep 3

echo -n "Start"
set -e
echo -n .
mkdir -p $PATHWEB $PATHLIB $PATHLOG
echo -n .
cp -rR web/* $PATHWEB
set +e
#echo -n .
#mysqladmin -u $DBUSER -p$DBPASS -h $DBHOST -P $DBPORT create $DBNAME >/dev/null 2>&1
#set -e
echo -n .
#mysql -u $DBUSER -p$DBPASS -h $DBHOST -P $DBPORT $DBNAME < db/playsms.sql
mysql -uroot playsms < db/playsms.sql
echo -n .
cp $PATHWEB/config-dist.php $PATHWEB/config.php
echo -n .
sed -i "s/#DBHOST#/$DBHOST/g" $PATHWEB/config.php
echo -n .
sed -i "s/#DBPORT#/$DBPORT/g" $PATHWEB/config.php
echo -n .
sed -i "s/#DBNAME#/$DBNAME/g" $PATHWEB/config.php
echo -n .
sed -i "s/#DBUSER#/$DBUSER/g" $PATHWEB/config.php
echo -n .
sed -i "s/#DBPASS#/$DBPASS/g" $PATHWEB/config.php
echo -n .
sed -i "s|#PATHLOG#|$PATHLOG|g" $PATHWEB/config.php
echo -n .
chown -R $WEBSERVERUSER.$WEBSERVERGROUP $PATHWEB $PATHLIB $PATHLOG
echo -n .
mkdir -p /etc $PATHBIN
echo -n .
touch /etc/playsmsd.conf
echo -n .
echo "PLAYSMS_PATH=\"$PATHWEB\"" > /etc/playsmsd.conf
echo "PLAYSMS_LIB=\"$PATHLIB\"" >> /etc/playsmsd.conf
echo "PLAYSMS_BIN=\"$PATHBIN\"" >> /etc/playsmsd.conf
echo "PLAYSMS_LOG=\"$PATHLOG\"" >> /etc/playsmsd.conf
echo "DAEMON_SLEEP=\"1\"" >> /etc/playsmsd.conf
echo "ERROR_REPORTING=\"E_ALL ^ (E_NOTICE | E_WARNING)\"" >> /etc/playsmsd.conf
echo -n .
cp -rR daemon/linux/bin/playsmsd.php $PATHBIN/playsmsd
chmod +x $PATHBIN/playsmsd
echo -n .
echo "end"
echo
$PATHBIN/playsmsd check
sleep 3
echo
$PATHBIN/playsmsd start
sleep 3
echo
$PATHBIN/playsmsd status
sleep 3
echo

echo
echo "playSMS has been installed on your system"
echo

cp install.conf install.conf.backup >/dev/null 2>&1

echo
echo "Attention"
echo
echo "When message \"unable to start playsmsd\" occurred above, please check:"
echo
echo "1. Possibly theres an issue with composer updates, try to run: \"composer update\""
echo "2. Manually run playsmsd, eg: \"playsmsd start\", and then \"playsmsd status\""
echo

mysqladmin -uroot shutdown

echo "=> Creating MySQL admin user"
/create_mysql_admin_user.sh

exit 0
