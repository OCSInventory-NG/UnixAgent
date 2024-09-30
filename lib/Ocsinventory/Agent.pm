#!/usr/bin/perl

package Ocsinventory::Agent;

use strict;
use warnings;
use POSIX ":sys_wait_h";

# THIS IS AN UGLY WORKAROUND FOR
# http://rt.cpan.org/Ticket/Display.html?id=38067
use XML::Simple;

eval {XMLout("<a>b</a>");};
if ($@){
    no strict 'refs';
    ${*{"XML::SAX::"}{HASH}{'parsers'}} = sub {
        return [ {
            'Features' => {
                'http://xml.org/sax/features/namespaces' => '1'
            },
            'Name' => 'XML::SAX::PurePerl'
        }]
    };
}
# END OF THE UGLY FIX!

require Exporter;

use Ocsinventory::Logger;
use Ocsinventory::Agent::XML::Inventory;
use Ocsinventory::Agent::XML::Prolog;

use Ocsinventory::Agent::Network;
use Ocsinventory::Agent::Backend;
use Ocsinventory::Agent::AccountConfig;
use Ocsinventory::Agent::AccountInfo;
use Ocsinventory::Agent::Config;

use Ocsinventory::Agent::Hooks;
#use Ocsinventory::Agent::Pid;
use Ocsinventory::Agent::Common;

sub run {

    # Load setting from the config file
    my $config = new Ocsinventory::Agent::Config;


    #$params->{$_} = $config->{$_} foreach (keys %$config);

    $ENV{LC_ALL} = 'C'; # Turn off localised output for commands
    $ENV{LANG} = 'C'; # Turn off localised output for commands


    #####################################
    ################ MAIN ###############
    #####################################


    ############################
    #### CLI parameters ########
    ############################
    $config->loadUserParams();

    # I close STDERR to avoid error message during the module execution
    # at the beginning I was doing shell redirection:
    #  my @ret = `cmd 2> /dev/null`;
    # but this syntax is not supported on (at least) FreeBSD and Solaris
    # c.f: http://www.perlmonks.org/?node_id=571072
    #my $tmp;
    #open ($tmp, ">&STDERR");
    #$params->{"savedstderr"} = $tmp;
    #if($params->{debug}) {
    #  $params->{verbose} = 1;
    #} else {
    #  close(STDERR);
    #}

    if ($config->{config}{logfile}) {
        $config->{config}{logger} = 'File';
    }

    my $logger = new Ocsinventory::Logger ({
        config => $config->{config}
    });

    my $common = new Ocsinventory::Agent::Common({
        logger => $logger,
        config => $config->{config},
    }); 

    # $< == $REAL_USER_ID
    if ( $< ne '0' ) {
        $logger->info("You should run this program as super-user.");
    }

    if (not $config->{config}{scanhomedirs}) {
        $logger->debug("--scan-homedirs missing. Don't scan user directories");
    }

    if ($config->{config}{nosoftware}) {
        $config->{config}{nosoftware} = 1
    }

    # desactivate local mode even if it is set in config file or command line 
    if (defined($config->{config}{nolocal})) {
        undef $config->{config}{'local'};
    }

    # TODO put that in Ocsinventory::Agent::Config
    if (!$config->{config}{'stdout'} && !$config->{config}{'local'} && $config->{config}{server} !~ /^http(|s):\/\//) {
        $logger->debug("the --server passed doesn't have a protocol, assume http as default");
        $config->{config}{server} = "http://".$config->{config}{server}.'/ocsinventory';
    }


######################## Objects initilisation ###############################################################

# The agent can contact different servers. Each server accountconfig is
# stored in a specific file:
    if (!recMkdir ($config->{config}{basevardir})) {
        if (! -d $ENV{HOME}."/.ocsinventory/var") {
            $logger->info("Failed to create ".$config->{config}{basevardir}." directory: $!. ".
            "I'm going to use the home directory instead (~/.ocsinventory/var).");
        }

        $config->{config}{basevardir} = $ENV{HOME}."/.ocsinventory/var";
        if (!recMkdir ($config->{config}{basevardir})) {
            $logger->error("Failed to create ".$config->{config}{basedir}." directory: $!".
            "The HOSTID will not be written on the harddrive. You may have duplicated ".
            "entry of this computer in your OCS database");
        }
        $logger->debug("var files are stored in ".$config->{config}{basevardir});
    }

    if (defined($config->{config}{server}) && $config->{config}{server}) {
        my $dir = $config->{config}{server};
        $dir =~ s/\//_/g;
        $config->{config}{vardir} = $config->{config}{basevardir}."/".$dir;
        if (defined ($config->{config}{local}) && $config->{config}{local}) {
            $logger->debug ("--server ignored since you also use --local");
            $config->{config}{server} = undef;
        }
    } elsif (defined($config->{config}{local}) && $config->{config}{local}) {
        $config->{config}{vardir} = $config->{config}{basevardir}."/__LOCAL__";
    } else {
        $logger->error("You must set either --server or --local");
    }


    if (!recMkdir ($config->{config}{vardir})) {
        $logger->error("Failed to create ".$config->{config}{vardir}." directory: $!");
    }

    if (-d $config->{config}{vardir}) {
        $config->{config}{accountconfig} = $config->{config}{vardir}."/ocsinv.conf";
        $config->{config}{accountinfofile} = $config->{config}{vardir}."/ocsinv.adm";
        $config->{config}{last_statefile} = $config->{config}{vardir}."/last_state";
        $config->{config}{next_timefile} = $config->{config}{vardir}."/next_timefile";
    }

    # Setting SSL CA file path if not set in configuration
    unless ($config->{config}{ca}) {
        # use server specific cacert.pem if it exists
        $config->{config}{ca} = $config->{config}{vardir}.'/cacert.pem';

        # if no server specific cacert.pem, look for a bundle in our config dir
        unless (-e $config->{config}{vardir}.'/cacert.pem') {
            foreach (@{$config->{config}{etcdir}}) {
                if (-e $_.'/ocsinventory-agent-cacert.pem') {
                    $config->{config}{ca} = $_.'/ocsinventory-agent-cacert.pem';
                    last;
                }
            }
        }
    }

################################################################################################################


##########################  load CFG files ######################################################################

    my $accountconfig = new Ocsinventory::Agent::AccountConfig({
        logger => $logger,
        config => $config->{config},
    });

    my $srv = $accountconfig->get('OCSFSERVER');
    $config->{config}{server} = $srv if $srv;
    $config->{config}{deviceid}   = $accountconfig->get('DEVICEID');

    # Should I create a new deviceID?
    chomp(my $hostname = `uname -n| cut -d . -f 1`);
    if ((!$config->{config}{deviceid}) || $config->{config}{deviceid} !~ /\Q$hostname\E-(?:\d{4})(?:-\d{2}){5}/) {
        my ($YEAR, $MONTH , $DAY, $HOUR, $MIN, $SEC) = (localtime(time))[5,4,3,2,1,0];

        $config->{config}{old_deviceid} = $config->{config}{deviceid};
        $config->{config}{deviceid} =sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d", $hostname, ($YEAR+1900), ($MONTH+1), $DAY, $HOUR, $MIN, $SEC;
        $accountconfig->set('DEVICEID',$config->{config}{deviceid});
    }

    my $accountinfo = new Ocsinventory::Agent::AccountInfo({
        logger => $logger,
        # TODOparams => $params,
        config => $config->{config},
        common => $common,
    });

    # --lazy
    if ($config->{config}{lazy}) {
        my $nexttime = (stat($config->{config}{next_timefile}))[9];

        if ($nexttime && $nexttime > time) {
            $logger->info("[Lazy] Must wait until ".localtime($nexttime)." exiting...");
            exit 0;
        }
    }

    if ($config->{config}{daemon}) {
        $logger->debug("Time to call Proc::Daemon");
        eval { require Proc::Daemon; };
        if ($@) {
            print "Can't load Proc::Daemon. Is the module installed?";
            exit 1;
        }
        Proc::Daemon::Init();
        $logger->debug("Daemon started");
        if (isAgentAlreadyRunning({
            logger => $logger,
        })) {
            $logger->debug("An agent is already runnnig, exiting...");
            exit 1;
        }
    }
    $logger->debug("OCS Agent initialised");

################# Now we can create a context hash #########################################################

    my $context = {
        installpath => $config->{config}->{vardir},
        servername => $config->{config}->{server},
        authuser => $config->{config}->{user},
        authpwd => $config->{config}->{password},
        authrealm => $config->{config}->{realm},
        deviceid => $config->{config}->{deviceid},
        version => $config->{VERSION},
        config => $config->{config},
        accountconfig => $accountconfig,
        accountinfo => $accountinfo,
        logger => $logger,
        common => $common,
        # OCS_AGENT_CMDL => "TOTO", # TODO cmd line parameter changed with the unified agent
    };

################################# HERE WE GO !!! ###################################################
    while (1) {

        my $exitcode = 0;
        my $wait;
        my $child;

        if ($config->{config}{daemon} || $config->{config}{wait}) {
            my $serverdelay;
            if(($config->{config}{wait} eq 'server') || ($config->{config}{wait}!~/^\d+$/)){
                $serverdelay = $accountconfig->get('PROLOG_FREQ')*3600;
            } else {
                $serverdelay = $config->{config}{wait};
            }
            if(!$serverdelay) {
                $serverdelay = $config->{config}{delaytime};
            }
            my $percent;
            # If planned between 1 and 4 hours, get 20%
            if($serverdelay <= 14400) {
                $percent = $serverdelay*0.20;
            # Else get 10%
            } else {
                $percent = $serverdelay*0.10;
            }
            my $randomWait = int rand($percent);
            $wait = $serverdelay-$randomWait;
            $logger->info("Going to sleep for $wait second(s)");
            sleep ($wait);
        }

        # Create an hook object to use handlers of modules. 
        my $hooks = new Ocsinventory::Agent::Hooks($context);

        # Using start_handler hook
        $hooks->run({name => 'start_handler'});

        #################### Local Mode #######################
        if ($config->{config}{stdout} || $config->{config}{local}) {

            # TODO, avoid to create Backend at two different places
            my $backend = new Ocsinventory::Agent::Backend ({
                context => $context,
            });

            my $inventory = new Ocsinventory::Agent::XML::Inventory ({
            # TODO, check if the accoun{info,config} are needed in localmode
                backend => $backend,
                context => $context,
            });

            # Launching inventory
            $inventory->initialise();

            # Using inventory_writer hook 
            $hooks->run({name => 'inventory_handler'}, $inventory);

            if ($config->{config}{stdout}) {
                $inventory->printXML();
            } elsif ($config->{config}{local}) {
                $inventory->writeXML();
            }
        } else { 
            ############ I've to contact the server ########################"
            my $network = new Ocsinventory::Agent::Network ({
                accountconfig => $accountconfig,
                accountinfo => $accountinfo,
                logger => $logger,
                config => $config->{config},
                common => $common,
            });

            # Adding the network object in $context
            $context->{network}= $network;

            my $sendInventory = 1;
            my $httpresp;
            my $prologresp;

            if (!$config->{config}{force}) {
                 my $prolog = new Ocsinventory::Agent::XML::Prolog({
                     context => $context,
                 });

                 # Using prolog_writer hook
                 $hooks->run({name => 'prolog_writer'}, $prolog);

                 # Formatting the XML 
                 my $prologXML = $prolog->getContent(); 

                 $httpresp = $network->sendXML({message => $prologXML});
                 $prologresp = $network->getXMLResp($httpresp,'Prolog');

                 if ($prologresp) {
                     # Using prolog_reader hook
                     $hooks->run({name => 'prolog_reader'}, $prologresp->getRawXML());

                     if (!$prologresp->isInventoryAsked()) {
                          $sendInventory = 0;
                     }

                 } else { # Failed to reach the server
                     if ($config->{config}{lazy}) {
                     # To avoid flooding a heavy loaded server
                         my $previousPrologFreq;
                         if (!($previousPrologFreq = $accountconfig->get('PROLOG_FREQ'))){
                             $previousPrologFreq = $config->{config}{delaytime};
                             $logger->info("No previous PROLOG_FREQ found - using fallback delay(".$config->{config}{delaytime}." seconds)");
                         } else {
                             $logger->info("Previous PROLOG_FREQ found ($previousPrologFreq)");
                             $previousPrologFreq = $previousPrologFreq*3600;
                         }
                         my $time = time + $previousPrologFreq;
                         utime $time,$time,$config->{config}{next_timefile};
                     }
                     exit 1 unless $config->{config}{daemon};
                     $sendInventory = 0;
                 }
             }
             if (!$sendInventory) {
                 $logger->info("Don't send the inventory");
             } else { # Send the inventory!
                 my $backend = new Ocsinventory::Agent::Backend ({
                     prologresp => $prologresp,
                     context => $context,
                 });
                 my $inventory = new Ocsinventory::Agent::XML::Inventory ({
                     # TODO, check if the accoun{info,config} are needed in localmode
                     backend => $backend,
                     context => $context,
                 });

                 # Launching inventory
                 $inventory->initialise();

                 # Using inventory_writer hook 
                 $hooks->run({name => 'inventory_handler'}, $inventory);

                 # Formatting the XML 
                 my $inventoryXML = $inventory->getContent(); 

                 # Sending Inventory
                 $httpresp = $network->sendXML({message => $inventoryXML}); 
                 if (my $invresp = $network->getXMLResp($httpresp,'Inventory')) {
                     $inventory->saveLastState();
                 } else {
                     exit (1) unless $config->{config}{daemon};
                 }
             }
         }

         # Using end_handler_hook 
         $hooks->run({name => 'end_handler'});

         # Avoid zombie process
         if ($^O ne 'darwin'){
             do {
                 $child = waitpid(-1, WNOHANG);
             } while $child > 0;
         } else {
             waitpid(-1, 0);
         }

         exit (0) unless $config->{config}{daemon};

    }
}

##########################################
############Functions#####################
##########################################


sub recMkdir {
    my $dir = shift;

    my @t = split /\//, $dir;
    shift @t;
    return unless @t;

    my $t;
    foreach (@t) {
        $t .= '/'.$_;
        if ((!-d $t) && (!mkdir $t)) {
            return;
        }
    }
    1;
}

sub isAgentAlreadyRunning {
    my $params = shift;
    my $logger = $params->{logger};
    # TODO add a workaround if Proc::PID::File is not installed
    eval { require Proc::PID::File; };
    if(!$@) {
        $logger->debug('Proc::PID::File available, checking for pid file');
        if (Proc::PID::File->running()) {
            $logger->debug('parent process already exists');
            return 1;
        }
    }
    return 0;
}
1;
