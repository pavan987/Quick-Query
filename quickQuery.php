<?php
session_start();
if(!(isset($_SESSION['ip']) && isset($_SESSION['username']) && isset($_SESSION['password'])))
{
 header('Location: index.php');
}

$ip=$_SESSION['ip'];
$user=$_SESSION['username'];
$pwd=$_SESSION['password'];

echo "<input type='hidden' id='ip' value='$ip' />";
echo "<input type='hidden' id='username' value='$user' />";
echo "<input type='hidden' id='password' value='$pwd' />";

?>

<style>
html {
margin:0;
padding:0;
}

#wrap {
width:100%;
margin:0 auto;
}

#main {
float:left;
width:70%;
overflow: auto;
}
#sidebar {
float:right;
width:28%;
padding-left:2%;
}
</style>

<div id="wrap">

<div id="main">
<input type="button" id="getData" value=" Fetch Config " /><span id="status" style="visibility: hidden" > Retrieving the Realtime  Config . . .Please wait (Approx-1min) </span>
<br/><br/>
<span id="result"></span>
<form method="post" action="quickQuery.php">
Keyword: <input type="text" name="search" />
<input type="submit" />
</form>

<?php
if(isset($_POST['search']) )
{
$ip=$_SESSION['ip'];
$value=$_POST["search"];
switch ($value) {
case "fi": $val="1"; break;
case "cluster": $val="2"; break;
case "chassis": $val="3"; break;
case "fex": $val="4"; break;
case "server": $val="5"; break;
case "adapter": $val="6"; break;
case "sp": $val="7"; break;
case "decomm": $val="8"; break;
case "firmware": $val="9"; break;
case "server firmware": $val="10"; break;
case "inventory": $val="11"; break;
case "server ports": $val="12"; break;
case "uplink ports": $val="13"; break;
case "mac": $val="14"; break;
case "wwn": $val="15"; break;
case "ip": $val="16"; break;
case "iqn": $val="17"; break;
case "core": $val="18"; break;
}
$cmd= "awk '/CMD".$val."BEGIN/{flag=1;next}/CMD".$val."END/{flag=0}flag' perl/quickQueryLogs/$ip.txt | tail -n +2";
echo "<pre>";
echo passthru($cmd);
echo "</pre>";
}
?>
</div>

<div id="sidebar">
<div> <a href="logout.php">Logout</a></div>
<h2> Keyword Help </h2>
<ol>
<li>fi - Fabric Interconnect info</li>
<li>cluster - Cluster state</li>
<li>chassis - Chassis status</li>
<li>fex - Fex status</li>
<li>server - Server status</li>
<li>adapter - Server adapter info </li>
<li>sp - Service Profile Assoc and status </li>
<li>decomm - Decommissioned Chassis/Fex/Server info </li>
<li>firmware - UCSM and FI Firmware info </li>
<li>server firmware - All Servers Firmware info </li>
<li>inventory - Server Inventory </li>
<li>server ports - Configured server ports on FI A/B </li>
<li>uplink ports - Configured uplink ports on FI A/B</li>
<li>mac - Mac Pools </li>
<li>wwn - WWN Pools </li>
<li>ip - IP Pools </li>
<li>iqn - IQN Pools </li>
<li>core - List of Cores </li>
</ol>
</div>


<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"> </script>
<script>
$("#getData").click(function() {
var ip=$("#ip").val();
var user=$("#username").val();
var pwd=$("#password").val();
$("#status").css('visibility', 'visible');
$("#result").load("quick-action.php",{ip:ip,user:user,pwd:pwd}, function() {
$("#status").css('visibility', 'hidden');
});
});
</script>


