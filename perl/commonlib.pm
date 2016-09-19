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
package commonlib;
use strict;
use Expect;
use lib "/var/www/html/perl";


sub login {
  my $inputs = shift;
  my ($cmd,$out,$ret,$err);
  my $timeout = 10;
  my $prompt = ".*# ";
  my $count = 1;
  my $retry = 3;

  my $msg = "Login to $inputs->{host}";
  print("$msg : In-Progress\n");

  if(!defined $inputs) {
    print("Input value undefined: \$inputs \n");
    $err=1; goto RETURN;
  }

  RETRY:
  # Get an Expect object
  my $exp = new Expect;
  $exp->raw_pty(0);
  $exp->log_stdout(0);

  exec_local("/usr/bin/ssh-keygen -R $inputs->{host}");

  # Spawn ssh command
  $cmd = "ssh -o StrictHostKeychecking=no $inputs->{user}\@$inputs->{host}";
  if(!$exp->spawn($cmd)) {
    print("Cannot spawn cmd '$cmd': $!\n");
    $err=1; goto RETURN;
  }
  # Wait for password prompt
  my $passwd_prompt = "[Pp]assword: ";
  if(!$exp->expect($timeout, '-re', $passwd_prompt)) {
    print("Prompt not found: $passwd_prompt (OR) host '$inputs->{host} unreachable\n");
    if($count <= $retry) {
      print("Retrying.. Attempt $count of $retry\n");
      $exp->hard_close();
      sleep 30;
      $count++;
      goto RETRY;
    } else {
      print("Retry count max reached\n");
      $err=1; goto RETURN;
    }
  }

  $exp->clear_accum();

  # enter password and wait for prompt
  $exp->send("$inputs->{pass}\n");
  
if(!$exp->expect($timeout, '-re' ,$prompt)) {
    my $file = __FILE__;
    my $line = __LINE__;
    print("Prompt '$prompt' not found: File:$file, Line:$line\n");
    $err=1; goto RETURN;
  }
  $exp->clear_accum();

  RETURN:
  if($err) {
    print("$msg : FAIL\n\n");
    return undef;
  } else {
    print("$msg : PASS\n\n");
    return $exp;
  }
}

#=============================================================================================================

sub logout {
  my $exp = shift;
  # logout
  $exp->send("logout\n");
  $exp->hard_close();
}

#================================================================================================================

sub exec_local {
  my ($cmd,$print_debug,$quit_on_err) = @_;
  my ($out,$ret,$err);
  $print_debug = 0 if(!defined $print_debug); #Don't want to print Local cmd output
  $quit_on_err = 1 if(!defined $quit_on_err);

  if(!defined $cmd) {
    print("Command not defined\n");
    $err=1; goto RETURN;
  }

    $out = `$cmd 2>&1`; chomp($out);
    $ret = $? >> 8;

    if($print_debug) {
      print("----\n");
      print("CMD=$cmd\n");
      if($out =~ /^$/) {
        print("OUT=<BLANK>\n");
      } else {
        if($out =~ /\n/) {
          $out = "\n$out";
          $out =~ s/\n/\n\t/g;
        }
        print("OUT=$out\n");
        $out =~ s/^\n//g;
      }
      print("RET=$ret\n");
      print("----\n");
    }
  

  RETURN:
  if(($ret) || ($err)) {
    $ret=1 if(!defined $ret);

      print("Failed to execute Local Command '$cmd'\n");
      print("OUTPUT=$out\n");
      print("RETURN=$ret\n");
	  return("quit",undef);
  }
  return($ret,$out);
}

#==================================================================================================================

sub exec_remote {
  my ($exp,$cmd,$fii,$print_debug,$quit_on_err) = @_;
  my ($before,$after,$match,$prompt2);
  my ($out,$err,$ret);
  my $timeout = 15;
  my $prompt = ".*# ";
  my $count = 1;
  my $retry = 3;

  $print_debug = 1 if(!defined $print_debug);
  $quit_on_err = 1 if(!defined $quit_on_err);


  print("----\n");
  print("Remote COMMAND == $cmd\n");

  $timeout = 2 if($cmd =~ /^\s+$/);
  $timeout = 900 if($cmd =~ /tech-support/);
  $timeout = 30 if($cmd =~ /fault/);

  if((!defined $exp) || (ref($exp) !~ /Expect/i)) {
    print("ERROR: Expect object not defined\n");
    return 1; # FAIL
  }

  # Suffix 'echo $?' to get command exit status
  if(!defined $fii) {
    $cmd = $cmd." 2>&1 ; echo \"rEturnCode=\$?\"" if($cmd !~ /&/);
  }

  # Execute cmd
  RETRY:
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
  $after =  $exp->after();
  $match =  $exp->match();
  if(($exp->match() !~ /$prompt/i) && ($exp->after() !~ /$prompt/i)) {
    print("Prompt not found:'$prompt' while executing '$cmd'\n");
    if($cmd !~ /grep POST_CMPLT/i) {
      $err=1; goto RETURN;
    }
  }

  
  # Capture the output
  if(defined $fii) {
    # We are executing on FI
    if($after =~ /svcconfig/)
    {
    if($count <= $retry) {
      print("Retrying.. Attempt $count of $retry\n");
      $exp->hard_close();
      sleep 30;
      $count++;
      goto RETRY;

    }
   } 
    if($before =~ /Invalid|Ambiguous|Incomplete|Managed object does not exist/) {
    $out = $before;
    print " Entered in to Invalid Ambiguos \n";
   } elsif($after =~ /Invalid|Ambiguous|Incomplete|Managed object does not exist/) {
    $out = $after;
    print " Entered in to Invalid Ambiguos \n";
   } else {
     $out = $before;
     $ret = 0; # Set cmd return status to PASS, if executing on FI
   }

  } else {
    # We are executing on Linux host
    $out = $before;

    # Capture the command exit status
    if(!defined $fii) {
      ($ret) = $out =~ m/rEturnCode=(\d+)/;
      print " Entered Not Defined : $ret \n";
      #$out =~ tr/\nrEturnCode=\d+//d; #Truncate \n and rEturnCode=\d+
      $out =~ s/rEturnCode=\d+//g;

      $out =~ s/^\s+$|^$//g;
      $out =~ s/\n$//g;
    }
  }
  chomp($out);

  # Extract the required output, after elimicating special chars from Expect output
  $out =~ s/\e\[?.*?[\@-~]//g; # Strip ANSI escape codes
  $out =~ s/\cM//g;            # Strip the Expect escape character
  #$out =~ tr/\n//d; # Truncate blank lines from SCALAR $out
  $out =~ s/^\s+$|^$//g;
  $out =~ s/\n$//g;

  if($print_debug) {
    
#output
    if($out =~ /^$/) {
      print("Remote OUTPUT  == <BLANK>\n");
    } else {
      if($out =~ /\n/) {
        $out = "\n$out";
        $out =~ s/\n/\n\t/g;
      }
      print("Remote OUTPUT  == $out\n");
      $out =~ s/^\n//g;
    }

    #return status
    print("Remote RETURN  == $ret\n");
    print("----\n");
  }

  RETURN:
  $exp->log_stdout(0); # Turn off command/output echo
  if($err|$ret) {
    print("Failed to execute Remote command '$cmd'\n");
    $before = $exp->before() if(!defined $before);
    $after =  $exp->after()  if(!defined $after);
    $match =  $exp->match()  if(!defined $match);
    #before
    if($before =~ /^$/) {
      print("Remote before  == <BLANK>\n");
    } else {
      $before = "\n$before" if($before =~ /\n/);
      print("Remote before  == $before\n");
    }

    #after
    if($after =~ /^$/) {
      print("Remote after   == <BLANK>\n");
    } else {
      $after = "\n$after" if($after =~ /\n/);
      print("Remote after   == $after\n");
    }

    #match
    if($match =~ /^$/) {
      print("Remote match   == <BLANK>\n");
    } else {
      $match = "\n$match" if($match =~ /\n/);
      print("Remote match   == $match\n");
    }
    
      return ("quit",undef);
    
  } else {
    return ($ret,$out);
  }
}

#======================================================================================================================


sub read_inputs_from_DB {
  my ($cmd,$out,$ret,$err);
  my %inputs;

  #system("clear");
  if((!defined $ARGV[0]) or ($#ARGV != 0)) {
    print "\n\tUsage: $0 <username> \n\n";
    $err=1; goto RETURN;
  }
  $inputs{DB_user} = $ARGV[0];
  my $msg = "Reading UCSM login credentials from Database (using DB_user '$inputs{DB_user}')";
  print("\n$msg : In-Progress\n");

  ($inputs{host},$inputs{user},$inputs{pass}) = mydb::getConfigUCSM($inputs{DB_user});

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
    print("$msg : FAIL\n\n");
    return 0;
  } else {
    print("$msg : PASS\n\n");
    return \%inputs;
  }
}

#===================================================================================================================================

sub localScp  { 
  my ($filename, $dir, $server, $username, $password, $filepath, $msg) = @_; 
  # Creating a Log file for copying
  my ($fh,$cmd);
  if (!open($fh, '>>', $filename))
  { 
  return 0;
  }
  print $fh $msg; 
  close $fh;
  print "Creation of log file done\n";
  print "Copying file to remote server $server\n";
  $cmd = "rsync -ave ssh $filename $username\@$server\:$filepath/$dir/";
  
  my $explocal = Expect->new;
  $explocal->raw_pty(1);
  if(!$explocal->spawn($cmd))
  {
  print "Expect spawn scp failed\n";
  return 0;
  }
  print "Expect Spawn Success\n";
  my $timeout = 10;
  $explocal -> expect($timeout,
              [ qr/\(yes\/no\)\? /i, sub { my $self = shift;
                                       $self->send("yes\n");
                                       exp_continue;
                                       }],
                [   qr/password: /i, #/
                    sub {
                        my $self = shift;
                        $self->send("$password\n");
                    }
                ]); 
  $timeout = 20;
  my @out = $explocal->expect($timeout, '-re', ".*# "); # or die "prompt not found";
  my $out = $out[3];
  $out =~ s/\n//g;
  $timeout = 5;
  $explocal->send("rm -f $filename");
  $explocal->expect($timeout, '-re', ".*# ");
  return $out;
}

#sub check_if_online {
 # my $ip = shift;
 # my $mac_trials = 60;

  #my $cmd = "ping $ip";
 # sleep 60;

  #if(!$max_trials) {
 # }
#}

1;
