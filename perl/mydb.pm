#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  my-database.pl
#
#        USAGE:  ./my-database.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavan Kumar Gondhi (UCSM QA), pgondhi@cisco.com
#      COMPANY:  Cisco Systems
#      VERSION:  1.0
#      CREATED:  01/03/2014 03:43:03 PM
#     REVISION:  ---
#===============================================================================
package mydb;
use strict;
use warnings;
use lib "/var/www/heml/perl";
use DBI;
use mymail;

my $driver = "mysql"; 
my $database = "ucsm_health";
my $dsn = "DBI:$driver:database=$database";
my $userid = "root";
my $password = "Nbv54321";
my $sth;
my $dbh;
my $ret;

#=======================================   Functions Required for Faults --------------------------------------------------
sub getConfigFault {
my ($Severity, $mail );
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Severity, mail
                        FROM config_faults 
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   ($Severity, $mail ) = @row;
}
$sth->finish();
$dbh->disconnect;
return ($Severity, $mail );
}

sub startFault {
my $ip=$_[0];
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("DELETE from temp_faults where IP = ?");
if($sth->execute($ip))
{
print "Number of rows deleted in temp". $sth->rows;
$ret=1;
}
else
{
$ret=$DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
return $ret;
}


sub insertFault {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("INSERT INTO temp_faults
                       (IP,Severity,Code,times,Id,Description)
					   values  (?,?,?,?,?,?)");
if($sth->execute($_[0],$_[1],$_[2],$_[3],$_[4],$_[5]))
{
print "Number of rows inserted in temp". $sth->rows;
$ret= 1;
}
else
{
$ret= $DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
return $ret;
}

sub endFault {
my $ip=$_[0];
my $email=$_[1];
my $mail=$_[2];
my $message;
my $subject;
#Find the Difference between current faults and Faults already present and Send mail if new faults
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select * from temp_faults where IP=? and Id NOT IN (select Id from faults where IP=?)");
$sth2->execute($ip,$ip) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Records need to be updated $rowcount \n";

# store the Differences in to Array
if ($rowcount!=0)
{
my @rows;
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();


#Send the New faults to Email
if($mail eq "Y")
{
$message="Hi,<br><br>UCSM Health Monitor found New Faults in your testbed <b>'$ip'</b><br> ";
$message .= "Acknowlege the Faults under Monitor Section of  <a href='http://ucs-health/''>Health Monitor Tool</a>, Once it is noticed<br><br>";
$message .= "List of Faults<br>==========<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>Severity<th>Code<th>TimeStamp<th>ID<th>Description</th></tr>";
for my $array_ref (@rows)
{
my ($IP,$Severity,$Code,$times,$Id,$Description)=@$array_ref;
$message .= "<tr><td>$Severity</td><td>$Code</td><td>$times</td><td>$Id</td><td>$Description</td></tr>";
}
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- New Faults found in your testbed";
mymail::mail($email,$subject,$message);
}

#Insert the New faults in to database
$sth = $dbh->prepare("insert into faults select * from temp_faults as s where IP=? and  not exists(select * from faults as d where (s.IP=d.IP and s.Id=d.Id))");
if($sth->execute($ip))
{
$rowcount = $sth->rows;
print "Number of Records that are updated $rowcount \n";
$ret= 1;
}
else
{
$ret= $DBI::errstr;
}
return $ret;
}



#Delete the Faults which are not present currently
my $sth1 = $dbh->prepare("DELETE FROM faults WHERE IP=? AND Id NOT IN (SELECT Id FROM temp_faults WHERE IP=?)");
if($sth1->execute($ip,$ip))
{
$rowcount = $sth1->rows;
print "Number of Records that are Deleted $rowcount \n";
return 1;
}
else
{
return $DBI::errstr;
}

}




#=========================================================== Functions Required for Cores ==============================================================

sub getConfigCore {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Techsupport,Backtrace, mail,Copyc,Copyt,Server,Filepath,Username,Password
                        FROM config_cores
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   my ($Techsupport,$backtrace,$mail,$Copyc,$Copyt,$Server,$Filepath,$Username,$Password ) = @row;
   return ($Techsupport,$backtrace,$mail,$Copyc,$Copyt,$Server,$Filepath,$Username,$Password );
}
$sth->finish();
$dbh->disconnect;
}

sub getNewCore {
my $ip=$_[0];
my @rows;
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth=$dbh->prepare("select IP,NAME from temp_cores where IP=? and Name NOT IN (select Name from cores where IP=?)");
$sth->execute($ip,$ip) or die $DBI::errstr;
my $rowcount = $sth->rows;

if($rowcount!=0)
{
while (my @row = $sth->fetchrow_array()) {
my $Name = $row[1];
push(@rows,$Name);
}
}
$sth->finish();
$dbh->disconnect;
return @rows;
}


sub insertBT {
my $ip = $_[0];
my $corename = $_[1];
my $bt = $_[2];
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("update cores set backtrace=? where IP=? and Name=?");
if($sth->execute($bt,$ip,$corename))
{
$ret= $sth->rows;
}
else
{
$ret= 0;
}
$sth->finish();
$dbh->disconnect;
return $ret;
}


sub startCore {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("DELETE from temp_cores where IP = ?");
if($sth->execute($_[0]))
{
$ret= 1;
}
else
{
$ret= $DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
return $ret;
}

sub insertCore {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("INSERT INTO temp_cores
                       (IP,Name,Fabric,times,backtrace,copy,version)
                       values  (?,?,?,?,?,?,?)");
if($sth->execute($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6]))
{
$ret=1;
}
else
{
$ret=$DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
return $ret;
}


sub endCore {
my $ip=$_[0];
my $email=$_[1];
my $mail=$_[2];
my $message;
my $subject;
#Find the Difference between current faults and Faults already present and Send mail if new faults
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select * from temp_cores where IP=? and Name NOT IN (select Name from cores where IP=?)");
$sth2->execute($ip,$ip) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Records need to be updated $rowcount \n";

# store the Differences in to Array
if ($rowcount!=0)
{
my @rows;
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();

if($mail eq "Y") 
{
#Send the New faults to Email
$message="Hi,<br><br>UCSM Health Monitor found New Cores in your testbed <b>'$ip'</b><br> ";
$message .= "Login to  <a href='http://ucs-health/''>Health Monitor Tool</a> for more details (Backtrace/Copy) <br><br>";
$message .= "List of Cores<br>==========<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>Name<th>Fabric<th>TimeStamp</th></tr>";
for my $array_ref (@rows)
{
my ($IP,$Name,$Fabric,$times)=@$array_ref;
$message .= "<tr><td>$Name</td><td>$Fabric</td><td>$times</td></tr>";
}
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- New Cores found in your testbed";
mymail::mail($email,$subject,$message);
}

#Insert the New faults in to database
$sth = $dbh->prepare("insert into cores select * from temp_cores as s where ip=? and  not exists(select * from cores as d where (s.IP=d.IP and s.Name=d.Name))");
if($sth->execute($ip))
{
$rowcount = $sth->rows;
print "Number of Records that are updated $rowcount \n";
$ret= 1;
}
else
{
$ret= $DBI::errstr;
}
}
$sth->finish();
#id->disconnect;
return $ret;

}



#-------------================================= Functions Required for Syslogs ================================================================

sub getConfigSyslog {

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Level
                        FROM config_syslogs
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   my ($Level) = @row;
   return $Level;
}
$sth->finish();
$dbh->disconnect;

}


sub getSyslog {

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT FIAIP,FIBIP,FIAhostname,FIBhostname,mail
                        FROM config_syslogs
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   my ($FIAIP,$FIBIP,$FIAhostname,$FIBhostname,$mail) = @row;
   return ($FIAIP,$FIBIP,$FIAhostname,$FIBhostname,$mail);
}
$sth->finish();
$dbh->disconnect;

}



sub readSyslog {
my $FIAIP=$_[0];
my $FIBIP=$_[1];
my $FIAH=$_[2];
my $FIBH=$_[3];
my $email=$_[4];
my $mail=$_[5];
my $message;
my $subject;
$dsn = "DBI:$driver:database=Syslog";
#Find the Difference between current Syslogs and Syslogs already present and Send mail if new syslogs
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select ID,FromHost,Priority,Message,DeviceReportedTime,Acknowledge from SystemEvents where FromHost IN (?,?,?,?) and ID NOT IN (select ID from Syslogs where FromHost IN (?,?,?,?) )");
$sth2->execute($FIAIP,$FIBIP,$FIAH,$FIBH,$FIAIP,$FIBIP,$FIAH,$FIBH) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Records need to be updated $rowcount \n";
if ($rowcount!=0)
{
my @rows;
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();

if($mail eq "Y"){
#Send the New Syslogs to Email
$message="Hi,<br><br>UCSM Health Monitor found New Syslogs coming from Hosts <b>'$FIAIP $FIBIP'</b><br> ";
$message .= "Acknowlege/Delete the Syslogs under Monitor Section of  <a href='http://ucs-health/''>Health Monitor Tool</a>, once it is noticed<br><br>";
$message .= "List of Syslogs<br>==========<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>FromHost<th>Level<th>Message<th>DeviceReportedTime</th></tr>";
for my $array_ref (@rows)
{
my ($ID,$FromHost,$Level,$Message,$DeviceReportedTime,$Acknowledge)=@$array_ref;
$message .= "<tr><td>$FromHost</td><td>$Level</td><td>$Message</td><td>$DeviceReportedTime</td></tr>";
}
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- New Syslogs found in your testbed";
mymail::mail($email,$subject,$message);
}

#Insert the New Syslogs in to database
$sth = $dbh->prepare("insert into Syslogs select ID,FromHost,Priority,Message,DeviceReportedTime,Acknowledge from SystemEvents as s where FromHost IN (?,?,?,?) and not exists(select * from Syslogs as d where s.ID=d.ID)");
if($sth->execute($FIAIP,$FIBIP,$FIAH,$FIBH))
{
$rowcount = $sth->rows;
print "Number of Records that are updated $rowcount \n";
}
else
{
return $DBI::errstr;
}
}

#Delete the Syslogs which are not present currently
my $sth1 = $dbh->prepare("DELETE FROM Syslogs WHERE FromHost IN (?,?,?,?) AND ID NOT IN (SELECT ID FROM SystemEvents where FromHost IN (?,?,?,?))");
if($sth1->execute($FIAIP,$FIBIP,$FIAH,$FIBH,$FIAIP,$FIBIP,$FIAH,$FIBH))
{
$rowcount = $sth1->rows;
print "Number of Records that are Deleted $rowcount \n";
}
else
 {
 print $DBI::errstr;
 return $DBI::errstr;
 }
 $sth1->finish();
return 1;
}


#=============================================== Pmon ============================================================================================


sub getConfigPmon {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Techsupport, mail
                        FROM config_pmon 
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   my ($Techsupport, $mail ) = @row;
   return ($Techsupport, $mail );
}
$sth->finish();
$dbh->disconnect;
}

sub startPmon {
my $ip=$_[0];
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("DELETE from temp_pmon where IP = ?");
if($sth->execute($ip))
{
print "Number of rows deleted in temp". $sth->rows;
return 1;
}
else
{
return $DBI::errstr;
}
}


sub insertPmon {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("INSERT INTO temp_pmon
                       (IP,Proccess,State,Retry,Exitcode,Signal,Core)
					   values  (?,?,?,?,?,?,?)");
if($sth->execute($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6]))
{
print "Number of rows inserted in temp". $sth->rows;
return 1;
}
else
{
return $DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
}

sub insertpmon {
my ($IP,$Fabric,$Proccess,$State,$Retry,$Exitcode,$Signal,$Core)=($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7]);
my $email=$_[8];
my $mail=$_[9];
my $message;
my $subject;
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("select * from pmon where IP=? and Proccess = ? and Fabric=?");
$sth->execute($IP,$Proccess,$Fabric) or die $DBI::errstr;
my $rowcount = $sth->rows;
print "Number of Records present already $rowcount \n";

$sth = $dbh->prepare("INSERT INTO pmon
                       (IP,Fabric,Proccess,State,Retry,Exitcode,Signal,Core)
					   values  (?,?,?,?,?,?,?,?)");
if( ($sth->execute($IP,$Fabric,$Proccess,$State,$Retry,$Exitcode,$Signal,$Core)) && ($rowcount!=0) )
{
$sth = $dbh->prepare("delete from pmon where IP = ? and Fabric =? and Proccess=? ");
$sth->execute($IP,$Fabric,$Proccess);
$sth = $dbh->prepare("INSERT INTO pmon
                       (IP,Fabric,Proccess,State,Retry,Exitcode,Signal,Core)
                       values  (?,?,?,?,?,?,?,?)");
$sth->execute($IP,$Fabric,$Proccess,$State,$Retry,$Exitcode,$Signal,$Core);

if (($Core eq "no") and !($Retry eq "0"))
{
insertEvent($IP,"Proccess","FI$Fabric :$Proccess","  Proccess is $State with retry($Retry), Exitcode($Exitcode), Signal($Signal) but no Core");

#Send the New faults to Email
if($mail eq "Y")
{
$message="Hi,<br><br>UCSM Health Monitor found Proccess failure with no core generated <b>'$IP'</b><br> ";
$message .= "Acknowlege the log under Monitor Section of  <a href='http://ucs-health/''>Health Monitor Tool</a>, Once it is noticed<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>Fabric<th>Proccess<th>State<th>Retry<th>Exitcode<th>Signal</th><th>Core</th></tr>";
$message .= "<tr><td>$Fabric</td><td>$Proccess</td><td>$State</td><td>$Retry</td><td>$Exitcode</td><td>$Signal</td><td>$Core</td></tr>";
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- Found Proccess Failure in your testbed";
mymail::mail($email,$subject,$message);
}
return 1;
}
}

$sth->finish();
$dbh->disconnect;
return 0;
}


sub endPmon {
my $ip=$_[0];
my $email=$_[1];
my $mail=$_[2];
my ($message,$subject);
#Find the Difference between current faults and Faults already present and Send mail if new faults
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select * from temp_pmon where IP=? and ROW(IP,Proccess,State,Retry,Exitcode,Signal,Core) NOT IN (select * from pmon where IP=?)");
$sth2->execute($ip,$ip) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Records need to be updated $rowcount \n";

# store the Differences in to Array
if ($rowcount!=0)
{
my @rows;
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();


#Send the New faults to Email
if($mail eq "Y")
{
$message="Hi,<br><br>UCSM Health Monitor found Proccess Failure with no core generated <b>'$ip'</b><br> ";
$message .= "Acknowlege the log under Monitor Section of  <a href='http://ucs-health/''>Health Monitor Tool</a>, Once it is noticed<br><br>";
$message .= "List of Proccess failed with no cores<br>==========<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>Proccess<th>State<th>Retry<th>Exitcode<th>Signal</th><th>Core</th></tr>";
for my $array_ref (@rows)
{
my ($IP,$Proccess,$State,$Retry,$Exitcode,$Signal,$Core)=@$array_ref;
$message .= "<tr><td>$Proccess</td><td>$State</td><td>$Retry</td><td>$Exitcode</td><td>$Signal</td><td>$Core</td></tr>";
}
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- Found Proccess Failure in your testbed";
mymail::mail($email,$subject,$message);
}

#Insert the New faults in to database
$sth = $dbh->prepare("insert into pmon select * from temp_pmon as s where IP=? and  not exists(select * from pmon as d where (s.IP=d.IP and s.Proccess=d.Proccess and s.State=d.State and s.Retry=d.Retry and s.Signal=d.Signal and s.Exitcode=d.Exitcode and s.Core=d.Core) )");
if($sth->execute($ip))
{
$rowcount = $sth->rows;
print "Number of Records that are updated $rowcount \n";
}

}



#Delete the Faults which are not present currently
my $sth1 = $dbh->prepare("DELETE FROM pmon WHERE IP=? AND ROW(IP,Proccess,State,Retry,Exitcode,Signal,Core) NOT IN (SELECT * FROM temp_pmon WHERE IP=?)");
if($sth1->execute($ip,$ip))
{
$rowcount = $sth1->rows;
print "Number of Records that are Deleted $rowcount \n";
return 1;
}
else
{
return $DBI::errstr;
}
$sth->finish();
$dbh->disconnect;


}
#=============================================== Cluster Monitoring ========================================================

sub insertcluster {

my ($IP,$Astate,$Bstate, $Arole,$Brole,$Amgmtserv,$Bmgmtserv,$eth1,$eth2,$HA,$heartbeat,$Email,$mail) = ($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7],$_[8],$_[9],$_[10],$_[11],$_[12]);
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("select * from cluster where IP=? ");
$sth->execute($IP) or die $DBI::errstr;
my $rowcount = $sth->rows;
print "Number of Records present already $rowcount \n";

$sth = $dbh->prepare("INSERT INTO cluster 
					   (IP,Astate,Bstate,Arole,Brole,Amgmt,Bmgmt,eth1,eth2,HA,heartbeat)
					   values  (?,?,?,?,?,?,?,?,?,?,?)");
if( $rowcount==0 )
{
$sth->execute($IP,$Astate,$Bstate, $Arole,$Brole,$Amgmtserv,$Bmgmtserv,$eth1,$eth2,$HA,$heartbeat);
$rowcount = $sth->rows;
print "number of rows updated $rowcount \n";

if(!($HA eq "READY"))
{
insertEvent($IP,"Cluster","HA", "  is $HA");
}

if(!($heartbeat eq "PRIMARY_OK"))
{
insertEvent($IP,"Cluster","Heart beat", "  is $$heartbeat");
}

if(!(($eth1 eq "UP") and ($eth2 eq "UP")))
{
insertEvent($IP,"Cluster","Peer Connectivity", "  is NOT_OK Eth1 ($eth1) , Eth2 ($eth2)");
}

if(!(($Amgmtserv eq "UP") and ($Bmgmtserv eq "UP")))
{
insertEvent($IP,"Cluster","Management Services", "  is NOT_OK ( FIA Mgmt-Srv: $Amgmtserv ) , ( FIB Mgmt-Srv: $Bmgmtserv )");
}

if(!(($Astate eq "UP") and ($Bstate eq "UP") and ($Arole =~ /{PRIMARY,SUBORDINATE}/) and ($Brole =~ /{PRIMARY,SUBORDINATE}/) ))
{
insertEvent($IP,"Cluster","FI Status", "  is NOT_OK ( A: $Astate, $Arole) - ( B: $Bstate, $Brole)");
}

return 1
}
}
#================================================= Common Functions ================================================================================

sub getUsers {

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Email FROM users");
$sth->execute() or die $DBI::errstr;
my @users;
while (my @row = $sth->fetchrow_array()) {
   my ($Email) = @row;
   push(@users, $Email);
}
$sth->finish();
return @users;
}


sub getConfigUCSM {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT IP,Username,Password
                        FROM hosts
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
if (my @row = $sth->fetchrow_array()) {
   my ($IP, $Username,$Password ) = @row;
   return ($IP,$Username, $Password );
}
$sth->finish();
$dbh->disconnect;
}

sub insertLog{
my $email=$_[0];
my $proccess=$_[1];
my $heading=$_[2];
my $message=$_[3];

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("insert into logs (Email, Proccess,Heading, Message) values (?,?,?,?)");
if($sth->execute($email,$proccess,$heading,$message))
{
return $sth->rows;
}
else
{
return 0;
}
$sth->finish();
$dbh->disconnect;
}


sub insertEvent{
my $IP=$_[0];
my $proccess=$_[1];
my $heading=$_[2];
my $message=$_[3];

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("insert into events (IP, Proccess,Heading, Message) values (?,?,?,?)");
if($sth->execute($IP,$proccess,$heading,$message))
{
return $sth->rows;
}
else
{
return 0;
}
$sth->finish();
$dbh->disconnect;
}

#===================================================================================================

sub deleteall {
 my $table = $_[0];
 my $email = $_[1];
 my $subject = $_[2];
 my $message = $_[3];
#$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
#$sth = $dbh->prepare("delete from $table where Email = ?");
#if($sth->execute($email))
#{
mymail::mail($email,$subject,$message);
#}

}


#=======================================   Functions Required for FSM   --------------------------------------------------
sub getConfigFsm {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("SELECT Retry, mail
                        FROM config_fsm 
                        WHERE Email='$_[0]'");
$sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()) {
   my ($Retry, $mail ) = @row;
   return ($Retry, $mail );
}
$sth->finish();
$dbh->disconnect;
}

sub startFsm {
my $ip=$_[0];
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("DELETE from temp_fsm where IP = ?");
if($sth->execute($ip))
{
print "Number of rows deleted in temp". $sth->rows;
return 1;
}
else
{
return $DBI::errstr;
}
}


sub insertFsm {
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$sth = $dbh->prepare("INSERT INTO temp_fsm
                       (IP,Class,Dn,Status,Progress,ErrorCode,ErrorDesc,ErrorResult)
					   values  (?,?,?,?,?,?,?,?)");
if($sth->execute($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7]))
{
print "Number of rows inserted in temp". $sth->rows;
return 1;
}
else
{
return $DBI::errstr;
}
$sth->finish();
$dbh->disconnect;
}

sub endFsm {
my $ip=$_[0];
my $email=$_[1];
my $mail=$_[2];
my $message;
my $subject;
#Find the Difference between current faults and Faults already present and Send mail if new faults
$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select * from temp_fsm where IP=? and Dn NOT IN (select Dn from fsm where IP=?)");
$sth2->execute($ip,$ip) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Records need to be updated $rowcount \n";

# store the Differences in to Array
if ($rowcount!=0)
{
my @rows;
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();


#Send the New fsm to Email
if($mail eq "Y")
{
$message="Hi,<br><br>UCSM Health Monitor found New Fsm Failures in your testbed <b>'$ip'</b><br> ";
$message .= "Check the Live status of FSM under MonitorB Section of  <a href='http://ucs-health/''>Health Monitor Tool</a><br><br>";
$message .= "List of FSM Failures<br>==========<br><br>";
$message .= "<table border=1>";
$message .= "<tr><th>Class<th>Dn<th>Status<th>Progress<th>ErrorCode<th>ErrorDesc<th>ErrorResult</th></tr>";
for my $array_ref (@rows)
{
my ($IP,$Class,$Dn,$Status,$Progress,$ErrorCode,$ErrorDesc,$ErrorResult)=@$array_ref;
$message .= "<tr><td>$Class</td><td>$Dn</td><td>$Status</td><td>$Progress</td><td>$ErrorCode</td><td>$ErrorDesc<td>$ErrorResult</td></tr>";
}
$message .= "</table>";
$message .= "<br><br>Thanks,<br>Admin";
$subject = "UCSM Health Monitor: Alert- New FSM Failures found in your testbed";
mymail::mail($email,$subject,$message);
}

#Insert the New Fsm in to database
$sth = $dbh->prepare("insert into fsm select * from temp_fsm as s where IP=? and  not exists(select * from fsm as d where (s.IP=d.IP and s.Dn=d.Dn))");
if($sth->execute($ip))
{
$rowcount = $sth->rows;
print "Number of Records that are updated $rowcount \n";
return 1;
}
else
{
return $DBI::errstr;
}
}

}

sub selectFsm {

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("select Dn,Class from fsm where IP=? ");
$sth2->execute($_[0]) or die $DBI::errstr;
my $rowcount = $sth2->rows;
print "Number of Rows present in fsm table $rowcount \n";
my @rows;
if ($rowcount!=0)
{
while (my @row = $sth2->fetchrow_array()) {
   push(@rows,\@row);
}
$sth2->finish();
}
return @rows;

}

sub deleteFsm {

$dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth2=$dbh->prepare("delete from fsm where IP=? and Dn = ? ");
$sth2->execute($_[0],$_[1]) or die $DBI::errstr;
$sth2->finish();
}



1;
