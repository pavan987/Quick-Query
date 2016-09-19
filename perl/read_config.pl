#!/usr/bin/perl
use strict;
use Expect;
use lib '/var/www/html/perl';
use mydb;
use commonlib;
# Invoke Main
exit main();

# Main
sub main {
  my ($exp,$inputs);
  my ($cmd,$out,$ret,$err);
  # Read user inputs
  if(!($inputs = read_inputs_from_DB())) {
     goto RETURN;
  }

  # Login
  if(!($exp = commonlib::login($inputs))) {
     goto RETURN;
  }

  # Read Faults
    if(!read_config($exp,$inputs)) {
     goto RETURN;     
    }
RETURN:
commonlib::logout($exp) if(defined $exp);
}

sub read_inputs_from_DB {
  my ($cmd,$out,$ret,$err);
  my %inputs;

  system("clear");
  if((!defined $ARGV[0]) or ($#ARGV != 2)) {
    print "\n\tUsage: $0 <ip> <username> <pwd> \n\n";
    $err=1; goto RETURN;
  }
  $inputs{host} = $ARGV[0];
  $inputs{user} = $ARGV[1];
  $inputs{pass} = $ARGV[2];

  if($inputs{host} !~ /\d+.\d+.\d+.\d+/) {
    print "Invalid IP address\n";
    $err=1; goto RETURN;
  }

  print "UCSM data received:\n";
  print "\tHOST = $inputs{host}\n";
  print "\tUSER = $inputs{user}\n";
  print "\tPASS = $inputs{pass}\n";

  RETURN:
  if($err) {
    return 0;
  } else {
    return \%inputs;
  }
}



sub read_config {
  my ($exp,$inputs) = @_;
  my ($cmd,$out,$ret,$err);
  my $fi = "yes";

  if(!defined $exp) {
    print("Input value undefined: \$exp\n");
    $err=1; goto RETURN;
  }

  if(!defined $inputs) {
    print("Input value undefined: \$inputs \n");
    $err=1; goto RETURN;
  }
  open (MYFILE, ">quickQueryLogs/$inputs->{host}.txt");

  #print("Cluster State\n");
  $cmd = "show fabric-interconnect detail | no-more";
  print MYFILE "CMD1BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD1END\n";

  $cmd = "show cluster extended-state | no-more";
  print MYFILE "CMD2BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD2END\n";

  $cmd = "show chassis detail | no-more";
  print MYFILE "CMD3BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD3END\n";

  $cmd = "show fex detail | no-more";
  print MYFILE "CMD4BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD4END\n";

  $cmd = "show server status | no-more";
  print MYFILE "CMD5BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD5END\n";

  $cmd = "show server adapter | no-more";
  print MYFILE "CMD6BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD6END\n";

  $cmd = "show service-profile status | no-more";
  print MYFILE "CMD7BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD7END\n";

  $cmd = "show chassis decommissioned | no-more";
  print MYFILE "CMD8BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\n\n";
  $cmd = "show server decommissioned | no-more";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD8END\n";

  $cmd = "show system version | no-more";
  print MYFILE "CMD9BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\n\n";
   $cmd = "show fabric-interconnect version | no-more";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD9END\n";

  $cmd = "show server version | no-more";
  print MYFILE "CMD10BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD10END\n";

  $cmd = "show server inventory | no-more";
  print MYFILE "CMD11BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD11END\n";

  $cmd = "scope eth-server ; show interface | no-more";
  print MYFILE "CMD12BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD12END\n";


  $cmd = "scope eth-uplink ; show interface | no-more";
  print MYFILE "CMD13BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD13END\n";

  $cmd = "scope org ; show mac-pool expand detail | no-more";
  print MYFILE "CMD14BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD14END\n";

  $cmd = "scope org ; show wwn-pool expand detail | no-more";
  print MYFILE "CMD15BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD15END\n";

  $cmd = "scope org ; show ip-pool expand detail | no-more";
  print MYFILE "CMD16BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD16END\n";


  $cmd = "scope org ; show iqn-pool expand detail | no-more";
  print MYFILE "CMD17BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD17END\n";


  $cmd = "scope monitoring ; scope sysdebug ; show cores detail | no-more";
  print MYFILE "CMD18BEGIN\n$cmd\n";
  ($ret,$out) = execute_remote($exp,$cmd,$fi);
  print MYFILE "$out\nCMD18END\n";

 
  close (MYFILE); 
}



sub execute_remote {
  my ($exp,$cmd,$fii) = @_;
  my ($before,$after,$match,$prompt2);
  my ($out,$err,$ret);
  my $timeout = 15;
  my $prompt = ".*# ";

 print "Executing CMD $cmd \n";
  $exp->clear_accum();
  $exp->send("$cmd\n");
  
  sleep 1;
  $exp->expect($timeout, '-re', $cmd);

  # if cmd has '|' then expect '.*\n"
  if($cmd =~ /\|/) {
    sleep 1;
    $prompt2 = ".*\n";
    $exp->expect($timeout, '-re', $prompt2);
    if(($exp->match() !~ /$prompt2/i) && ($exp->after() !~ /$prompt2/i)) {
      print("Prompt not found:'$prompt2' while executing '$cmd'\n");
      $err=1; goto RETURN;
    }
  } elsif($cmd !~ /^\s+2>&1/) {
    sleep 1;
    $prompt2 = "\n";
    $exp->expect($timeout, '-ex', "\n");
    if(($exp->match() !~ /$prompt2/i) && ($exp->after() !~ /$prompt2/i)) {
      print("Prompt not found:'$prompt2' while executing '$cmd'\n");
      $err=1; goto RETURN;
    }
  }
  # Now retrieve actual output
  sleep 1;
  $exp->expect($timeout, '-re', $prompt) ;
  $before = $exp->before();
$out = $before;
$ret = 0;
return ($ret,$out);
}
