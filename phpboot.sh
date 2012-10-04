#!/bin/bash

set -e


# Setup local PHP project with Slim Framework.
#
# Usage:
#
#   phpboot new <project-name>
function phpboot-new {

if [ -z $1 ]; then
  echo "Usage $0 new <project-name>"
  exit
fi

project=$1

# Create project dir

echo "  + Creating dir $project"
mkdir ${project}
cd ${project}

# Create and install Composer deps

echo "  + Creating and installing Composer dependencies"
cat > composer.json <<EOF
{
  "require": {
    "slim/slim": "2.*"
  }
}
EOF
composer.phar install

# Create public/ dir

echo "  + Creating public/"
mkdir public

# Create .htaccess

echo "  + Writing .htaccess"
cat > public/.htaccess <<EOF
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [QSA,L]
EOF

# Create initial index.php

echo "  + Writing index.php"
cat > public/index.php <<\EOF
<?php

require __DIR__ . '/../vendor/autoload.php';

$app = new \Slim\Slim();

$app->get('/', function() {
  phpinfo();
});

$app->run();
EOF

# Configure Apache virtual host

echo "  + Configuring Apache vhost ${project}.dev"
sudo ln -s $(pwd)/public /var/www/${project}
sudo bash -c "cat > /etc/apache2/sites-enabled/${project} <<EOF
<VirtualHost *:80>
  ServerName "${project}.dev"
  DocumentRoot "/var/www/${project}"
  <Directory "/var/www/${project}">
  </Directory>
  # TODO: Add ErrorLog and CustomLog config
</VirtualHost>
EOF"
# Restart
sudo service apache2 restart

# Add ${project}.dev domain to hosts

echo "  + Adding ${project}.dev to /etc/hosts"
sudo bash -c "cat >> /etc/hosts <<EOF
127.0.0.1 ${project}.dev
EOF"

echo "  + Done."
}


# Delete local PHP project created with phpboot-new.
#
# Usage:
#
#   phpboot del <project-name>
function phpboot-del {

if [ -z $1 ]; then
  echo "Usage $0 del <project-name>"
  exit
fi

project=$1

echo "  THIS WILL DELETE PROJECT FILES AND VHOSTS."
echo -n "  Damn sure? [yes|no] > "
read proceed

if [ "$proceed" != "yes" ]; then
  echo "  Cancelled."
  exit
fi

echo "  + Deleting dir ${project}"
rm -r $project

echo "  + Deleting vhost ${project}.dev"
sudo rm /var/www/$project
sudo rm /etc/apache2/sites-enabled/$project

echo "  + Deleting ${project}.dev from /etc/hosts"
sudo sed -i "/${project}\.dev/ d" /etc/hosts

echo "  + Done."
}


# Main

if [ -z "$1" ] || ([ "$1" != "new" ] && [ "$1" != "del" ]); then
  echo "Usage $0 new|del <project-name>"
  exit
fi

command=$1
project=$2
phpboot-$command $project
