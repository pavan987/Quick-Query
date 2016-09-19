<?php 
	      session_start();
        $ip=$_REQUEST["ucsmip"];
        $user=$_REQUEST["username"];
        $pwd=$_REQUEST["password"];
        $_SESSION['ip']=$ip;
        $_SESSION['username']=$user;
        $_SESSION['password']=$pwd;

	
	header('Location: quickQuery.php');

?>

