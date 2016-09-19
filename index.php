<?php session_start();
if(isset($_SESSION['Cookie']))
{
	header("Location: quickQuery.php");
}
else
{


?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head> 
<title>Quick Query</title>
<style>

body {
	background-color: #013B61;
	background-position: center top;
	background-repeat: no-repeat;
	background-image: url(images/ucs_bg4.jpg);
	color:white;
	font: 100%/1.4 Arial, Helvetica, sans-serif;
	margin: 0;
	padding: 0;
}

.container {
	width: 960px;
	margin: 0 auto; /* the auto value on the sides, coupled with the width, centers the layout */
	min-width: 960px;
	min-height: 768px;
	background-color: #223f67;
	background-position: center top;
	background-repeat: no-repeat;
	background-image: url(images/ucs_bg4.jpg);

}

.content {

	padding: 10px 0;
}

.content h4 {
	border:1px solid #013B61;
	background: #013B61;
	border-radius:5px;
	padding:10px;
    font-style: normal;
    font-weight: normal;
    font-size: 15px;
    color: white;
    margin-left: 180px;
	margin-top: 115px;
	margin-right:285px;
    
}

td.input{
padding:15px 50px 15px 0px;

}

td.dashboard{
padding: 15px 230px 0px 25px;
}

td.logo
{
padding: 20px 0px 0px 50px;

}

#myTable{
border:3px solid green;
}

</style>

</head>
<body>
<div class="container">
  <div class="content">
<h4> Easy Query Interface for Cisco Unified Computing System </h4>
<form name="input" action="login.php" method="post">
<table id="myTable">

<tr>
<td valign="top" class="logo"> <img src="images/cisco_logo.png" /></td>
<td valign="top" class="dashboard"><h2>UCS Quick Query</h2></td>

<td class="input"><table>
<tr>
<td></td>
<td style="color:red"><?php echo $Message ?></td>
</tr>
<tr>
<td align="right">Cluster IP:</td>
<td><input type="text" name="ucsmip"></td>
</tr>
<tr>
<td align="right">Username:</td>
<td><input type="text" name="username"></td>
</tr>
<tr>
<td align="right">Password:</td>
<td><input type="password" name="password"></td>
</tr>
<tr>
<td></td>
<td><input type="submit" value="OK" style="width: 100px;" ></td>
</tr>
</table></td>

</tr>




</table>
</form>


</body>
</html>
<?php
}
?>
