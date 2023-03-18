#!/bin/bash

# Joomla Version
joomla_version=4-0-4
joomlad_dir="/tmp"
# PHP
php_packages="php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-bcmath php-mysql php-json libapache2-mod-php"

# Überprüfen Sie, ob das Skript als Root ausgeführt wird
if [ "$(whoami)" != "root" ]; then
    echo "Dieses Skript muss als Root ausgeführt werden."
    exit 1
fi

# System aktualisieren
echo -e "\e[01;32;32m System-Updates werden überprüft...\e[0m"
sleep 1
apt-get update
apt-get -y upgrade
apt-get -y autoremove
apt-get -y autoclean
sleep 1

# Erforderliche Pakete installieren
echo -e "\e[01;32;32mErforderliche Pakete werden installiert...\e[0m"
sleep 1
sudo apt-get install -y mc nano apache2 mysql-server mysql-client


# Installiere PHP und erforderliche Erweiterungen
echo "PHP wird installiert"
sudo apt-get install -y $php_packages

# Überprüfe, ob die Pakete installiert wurden
echo "Überprüfe, ob die Pakete installiert wurden"
for package in $php_packages; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "$package ist installiert"
    else
        echo "$package ist NICHT installiert"
    fi
done
# Setze die PHP-Umgebungsvariable
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
echo "export PHP_VERSION=$PHP_VERSION" >> ~/.bashrc
source ~/.bashrc

# Aktiviere die Apache-Module
PHP_MOD_NAME="php$PHP_VERSION"
sudo a2dismod $PHP_MOD_NAME
sudo a2enmod $PHP_MOD_NAME

# Überprüfe, ob PHP und die Erweiterungen installiert wurden
echo -e "\e[01;32;32mÜberprüfe, ob PHP und die Erweiterungen installiert wurden...\e[0m"
php -v
php -m

systemctl restart apache2
sleep 1

##Datenbank erstellen
echo -e "\e[01;32;32mDatenbank erstellen\e[0m"
sleep 1
echo "Datenbank erstellen"

if [ -f /root/.my.cnf ]; then
    echo "Datei existiert."
else
    echo "Bitte gib das root MySQL-Passwort ein:"
    read -s dbpass
    echo -e "[client]\nuser=root\npassword=$dbpass" > /root/.my.cnf
fi

echo "Gib den Namen der Datenbank ein:"
read dbname

echo "Erstelle neue MySQL-Datenbank..."
mysql -e "CREATE DATABASE $dbname /*!40100 DEFAULT CHARACTER SET utf8 */;"

if [ $? -ne 0 ]; then
    echo "Fehler beim Erstellen der Datenbank."
    exit 1
fi

echo "Datenbank erfolgreich erstellt!"

echo "Gib den Namen des Benutzers für die Datenbank ein:"
read username

echo "Gib das Passwort für den Datenbankbenutzer ein:"
read -s userpass

echo "Erstelle neuen Benutzer..."
mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED WITH mysql_native_password BY '$userpass';"

if [ $? -ne 0 ]; then
    echo "Fehler beim Erstellen des Benutzers."
    exit 1
fi

echo "Benutzer erfolgreich erstellt!"

echo "Gib alle Rechte für die Datenbank $dbname an den Benutzer $username."
mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "ALTER USER '$username'@'localhost' IDENTIFIED WITH mysql_native_password BY '$userpass';"

echo "Alle Schritte abgeschlossen!"

# Lade Joomla herunter
echo "Joomla Download"
if [ ! -f "$joomlad_dir/Joomla_$joomla_version-Stable-Full_Package.tar.gz" ]
then
    wget -P "$joomlad_dir" "https://downloads.joomla.org/de/cms/joomla4/$joomla_version/Joomla_$joomla_version-Stable-Full_Package.tar.gz"
fi

# Entpacke Joomla und setze die Berechtigungen
echo "Joomla entpacken und Berechtigungen setzen"
rm /var/www/html/index.html
tar -zxvf "$joomlad_dir/Joomla_$joomla_version-Stable-Full_Package.tar.gz" -C /var/www/html/
chown -R www-data:www-data /var/www/html/

echo -e "\e[01;32;32mJoomla Installation abgeschlossen\e[0m"
sleep 10


# Schreibe die Ausgabe in die root-Shell und auf der Konsole
echo "Username & Password & Datenbanknamen Bitte Aufschreiben" | sudo tee /root/install.log > /dev/null
echo "Datenbank username: $username" | sudo tee -a /root/install.log > /dev/null
echo "Datenbank Passwort: $userpass" | sudo tee -a /root/install.log > /dev/null
echo "Datenbank Name: $dbname" | sudo tee -a /root/install.log > /dev/null

echo "Username & Password & Datenbanknamen Bitte Aufschreiben"
echo "Datenbank username: $username"
echo "Datenbank Passwort: $userpass"
echo "Datenbank Name: $dbname"
sleep 10
rm "/root/joomlai4.sh"
