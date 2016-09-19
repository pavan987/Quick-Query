<?php
set_include_path(get_include_path() . PATH_SEPARATOR . 'phpseclib');
include('Net/SSH2.php');

session_start();

$ip=$_POST['ip'];
$user=$_POST['user'];
$pwd=$_POST['pwd'];
$ssh = new Net_SSH2($ip);
if (!$ssh->login('$user, $pwd)) {
    exit('Login Failed');
}

$ssh->exec("./read_config.pl $ip $user $pwd");
?>
