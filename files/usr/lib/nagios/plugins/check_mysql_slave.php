#!/usr/bin/php -q
<?php

define('OK', 0);
define('WARNING', 1);
define('CRITICAL', 2);
define('UNKNOWN', 3);

$options = getopt('H::P::u::p::');
$mysql_host = isset($options['H']) ? $options['H'] : "127.0.0.1";
$mysql_port = isset($options['P']) ? $options['P'] : 3306;
$mysql_username = isset($options['u']) ? $options['u'] : "root";
$mysql_password = isset($options['p']) ? $options['p'] : "root";

$sql = "show slave status";
if (false === $link = mysqli_connect($mysql_host . ':' . $mysql_port, $mysql_username, $mysql_password)) {
    echo "Could not connect to database.\n";
    echo mysqli_error($link);
    die(CRITICAL);
}

if (false === $result = mysqli_query($link, $sql)) {
    echo "Unable to query database\n";
    echo mysqli_error($link);
    die(CRITICAL);
}

if (!mysqli_num_rows($result)) {
    echo "SHOW SLAVE STATUS returned no rows.\n";
    echo mysqli_error($link);
    die(CRITICAL);
}

$data = mysqli_fetch_assoc($result);

$seconds = $data['Seconds_Behind_Master'];

if ($data['Slave_SQL_Running'] != 'Yes' || $data['Slave_IO_Running'] != 'Yes') {
    echo "Slave replication stopped, IO or SQL Error. Here is the output of SHOW SLAVE STATUS\n\n";
    print_r($data);
    die(CRITICAL);
}

if ($seconds > 300) {
    echo "Slave is more than five minutes behind master.\n";
    die(CRITICAL);
}
if ($seconds > 60) {
    echo "Slave is more than one minute behind master. Damn lag!\n";
    die(WARNING);
}
echo 'Slave up to date|' . $seconds;
die(OK);