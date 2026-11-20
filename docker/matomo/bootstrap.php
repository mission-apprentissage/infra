<?php
// Charge par index.php et console avant core/bootstrap.php.
// config.ini.php, common.config.ini.php, config.php, tmp/ et misc/user/ sont
// lus et ecrits sous ce chemin, et non dans le code (lecture seule).
// global.ini.php reste lu depuis /var/www/matomo/config.
define('PIWIK_USER_PATH', '/var/lib/matomo');
