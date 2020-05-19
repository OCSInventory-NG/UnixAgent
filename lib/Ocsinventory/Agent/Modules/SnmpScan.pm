###############################################################################
## OCSINVENTORY-NG
## Copyleft Guillaume PROTET 2010
## Web : http://www.ocsinventory-ng.org
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::SnmpScan;

use strict;
no strict 'refs';
use warnings;

use XML::Simple;
use Digest::MD5;

sub new {
    my $name="snmpscan";   #Set the name of your module here

    my (undef,$context) = @_;
    my $self = {};

    #Create a special logger for the module
    $self->{logger} = new Ocsinventory::Logger ({
        config => $context->{config}
    });
    $self->{logger}->{header}="[$name]";
    $self->{common} = $context->{common};
    $self->{context}=$context;

    $self->{structure}= {
        name => $name,
        start_handler => $name."_start_handler", 
        prolog_writer => undef,      
        prolog_reader => $name."_prolog_reader", 
        inventory_handler => undef,
        end_handler => $name."_end_handler",
    };

    $self->{number_scan}=0;
    $self->{snmp_oid_run}=$name."_oid_run";
    $self->{snmp_oid_xml}=$name."_oid_xml";
    $self->{func_oid}={};
    $self->{snmp_dir}=[];
    $self->{snmp_vardir} = ["$self->{context}->{installpath}/snmp/mibs/local/","$self->{context}->{installpath}/snmp/mibs/remote/"];

    my $spec_dir_snmp="Ocsinventory/Agent/Modules/Snmp/";
    $self->{spec_dir_snmp}=$spec_dir_snmp;
    $self->{spec_module_snmp}="Ocsinventory::Agent::Modules::Snmp::";

    # We are going to search where is the directory Ocsinventory/Modules/snmp
    foreach my $dir ( @INC ) {
        my $res_dir=$dir."/".$spec_dir_snmp;
        if ( -d $res_dir ) {
            push(@{$self->{snmp_dir}},$res_dir);
        }
    }

    # We create a xml for the snmp inventory that we will be sent to server
    $self->{inventory}={};

    bless $self;
}

sub snmpscan_start_handler {     
    my $self = shift;
    my $logger = $self->{logger};
    my $common = $self->{context}->{common};
    my $config = $self->{context}->{config};
    
    $logger->debug("Calling snmp_start_handler");

    # Disabling module if local mode
    if ($config->{stdout} || $config->{local}) {
        $self->{disabled} = 1;
        $logger->info("Agent is running in local mode...disabling module");
    }

    # If we cannot load prerequisite, we disable the module 
    unless ($common->can_load('Net::SNMP')) { 
        $self->{disabled} = 1;
        $logger->error("Net::SNMP perl module is missing !!");
        $logger->error("Humm my prerequisites are not OK...disabling module :( :(");
    }
}

sub snmpscan_prolog_reader {
    my ($self, $prolog) = @_;
    my $logger = $self->{logger};
    my $network = $self->{context}->{network};
    my $snmp_vardir = $self->{snmp_vardir};

    my $option;

    $logger->debug("Calling snmp_prolog_reader");
    
    $prolog = XML::Simple::XMLin( $prolog, ForceArray => ['OPTION', 'PARAM']);

    for $option (@{$prolog->{OPTION}}){
        if ($option->{NAME} =~/snmp/i){
            $self->{doscans} = 1 ;
            for ( @{ $option->{PARAM} } ) {
                if ($_->{'TYPE'} eq 'DEVICE'){
                    # Adding the IP in the devices array
                    push @{$self->{netdevices}},{
                        IPADDR => $_->{IPADDR},
                        MACADDR => $_->{MACADDR},
                    };
                }
                if ($_->{'TYPE'} eq 'COMMUNITY'){
                    # Adding the community in the communities array
                    push @{$self->{communities}},{
                        VERSION=>$_->{VERSION},
                        NAME=>$_->{NAME},
                        USERNAME=>$_->{USERNAME},
                        AUTHPROTO=>$_->{AUTHPROTO},
                        AUTHPASSWD=>$_->{AUTHPASSWD},
                        PRIVPROTO=>$_->{PRIVPROTO},
                        PRIVPASSWD=>$_->{PRIVPASSWD}
                    };
                }
                if ($_->{'TYPE'} eq 'NETWORK'){
                    push @{$self->{nets_to_scan}},$_->{SUBNET};
                }

                if ($_->{'TYPE'} eq 'SNMP_TYPE'){
                    push @{$self->{snmp_type_condition}{$_->{TABLE_TYPE_NAME}}},{
                        CONDITION_OID => $_->{CONDITION_OID},
                        CONDITION_VALUE => $_->{CONDITION_VALUE}
                    };

                    push @{$self->{snmp_type_infos}},{
                        TABLE_TYPE_NAME => $_->{TABLE_TYPE_NAME},
                        LABEL_NAME => $_->{LABEL_NAME},
                        OID => $_->{OID}
                    };
                }
        
                # Creating the directory for xml if they don't yet exist
                mkdir($self->{context}->{installpath}."/snmp") unless -d $self->{context}->{installpath}."/snmp";
                mkdir($self->{context}->{installpath}."/snmp/mibs") unless -d $self->{context}->{installpath}."/snmp/mibs";
                foreach my $dir ( @{$snmp_vardir}) {
                    mkdir($dir) unless -d $dir;
                }
            }
        }
    }
}

sub snmpscan_end_handler {
    my $self = shift;
    my $logger = $self->{logger};
    my $common = $self->{context}->{common};
    my $network = $self->{context}->{network};

    $logger->debug("Calling snmp_end_handler");

    # If no order form server
    return unless $self->{doscans};

    # Flushing xmltags if it has not been done
    $common->flushXMLTags();

    # We get the config
    my $config = $self->{context}->{config};
    
    my $communities=$self->{communities};
    if ( ! defined ($communities ) ) {
        $logger->debug("We have no Community from server, we use default public community");
        $communities=[{VERSION=>"2c",NAME=>"public"}];
    }

    my ($name,$comm,$error,$system_oid);

    # Initalising the XML properties 
    my $snmp_inventory = $self->{inventory};
    $snmp_inventory->{xmlroot}->{QUERY} = ['SNMP'];
    $snmp_inventory->{xmlroot}->{DEVICEID} = [$self->{context}->{config}->{deviceid}];

    # Scanning network
    $logger->debug("Snmp: Scanning network");

    my $nets_to_scan=$self->{nets_to_scan};
    foreach my $net_to_scan ( @$nets_to_scan ){
        $self->snmp_ip_scan($net_to_scan);
    }
    $logger->debug("Snmp: Ending Scanning network");

    # Begin scanning ip tables 
    my $ip=$self->{netdevices};

    foreach my $device ( @$ip ) {
        my $session = undef;
        my $full_oid = undef;
        my $devicedata = $common->{xmltags};     #To fill the xml informations for this device
        my $snmp_table = undef;

        $logger->debug("Scanning $device->{IPADDR} device");    
        # Search for the good snmp community in the table community
        LIST_SNMP: foreach $comm ( @$communities ) {

            # Test if we use SNMP v3
            if ( $comm->{VERSION} eq "3"  ) {
                ($session, $error) = Net::SNMP->session(
                    -retries     => 2 ,
                    -timeout     => 3,
                    -version     => 'snmpv'.$comm->{VERSION},
                    -hostname    => $device->{IPADDR},
                    -translate   => [-nosuchinstance => 0, -nosuchobject => 0],
                    -username      => $comm->{USERNAME},
                    -authpassword  => $comm->{AUTHPASSWD},
                    -authprotocol  => $comm->{AUTHPROTO},
                    -privpassword  => $comm->{PRIVPASSWD},
                    -privprotocol  => $comm->{PRIVPROTO},
                );

                # For a use in constructor module (Cisco)
                $self->{username}=$comm->{USERNAME};
                $self->{authpassword}=$comm->{AUTHPASSWD};
                $self->{authprotocol}=$comm->{AUTHPROTO};
                $self->{privpassword}=$comm->{PRIVPASSWD};
                $self->{privprotocol}= $comm->{PRIVPROTO};

            } else {
                # We have an older version v2c ou v1
                ($session, $error) = Net::SNMP->session(
                    -retries     => 1 ,
                    -timeout     => 3,
                    -version     => 'snmpv'.$comm->{VERSION},
                    -hostname    => $device->{IPADDR},
                    -community   => $comm->{NAME},
                    -translate   => [-nosuchinstance => 0, -nosuchobject => 0],
                );
            };
            unless (defined($session)) {
                $logger->error("Snmp ERROR: $error");
            } else {
                $self->{snmp_session}=$session;

                # For a use in constructor module (Cisco)
                $self->{snmp_community}=$comm->{NAME}; 
                $self->{snmp_version}=$comm->{VERSION};

                my $snmp_key = $self->{snmp_type_condition};
                LIST_TYPE: foreach my $snmp_oid (keys(%$snmp_key)) {
                    $logger->error("SNMP DEBUG");
                    $logger->error($snmp_oid);
                    $full_oid = $session->get_request( -varbindlist => [$self->{snmp_type_condition}->{$snmp_oid}->{CONDITION_OID}]);
                    $snmp_table = $snmp_oid;
                    $logger->error("Snmp TABLE: $snmp_table");
                    last LIST_TYPE if ( defined $full_oid && $full_oid->{$self->{snmp_type_condition}->{$snmp_oid}->{CONDITION_OID}} eq $self->{snmp_type_condition}->{$snmp_oid}->{CONDITION_VALUE});
                }
                
                last LIST_SNMP if ( defined $full_oid);
                $session->close;
                $self->{snmp_session}=undef;
            }
        }

        if (defined $full_oid && defined $snmp_table) {
            $full_oid = $full_oid->{$self->{snmp_type_condition}->{$snmp_table}->{CONDITION_OID}};

            $session->max_msg_size(8192);
            # We have found the good Community, we can scan this equipment
            my %snmpContent = ();

            # We indicate that we scan a new equipment
            $self->{number_scan}++;

        }
    }
}

#sub setSnmpInfos {
#    my (%args) = @_;
#    my $common = $self->{context}->{common};
#    my $xmltags = $common->{xmltags};

#    foreach my $key (qw/NAME SERIALNUMBER COUNTER STATUS ERRORSTATE/ ) {
#        if (exists $args->{$key}) {
#            $xmltags->{PRINTERS}[0]{$key}[0] = $args->{$key};
#        }
#    }
#}

sub snmp_ip_scan {
    my ($self,$net_to_scan) = @_;
    my $logger=$self->{logger};
    my $common=$self->{common};

    if ($common->can_load('Net::Netmask') ) {
        my $block=Net::Netmask->new($net_to_scan);
        my $size=$block->size()-2;
        my $index=1;

        if ( $common->can_run('nmap') && $common->can_load('Nmap::Parser')  ) {
            $logger->debug("Scannig $net_to_scan with nmap");
            my $nmaparser = Nmap::Parser->new;

            $nmaparser->parsescan("nmap","-sP",$net_to_scan);
            for my $host ($nmaparser->all_hosts("up")) {
               my $res=$host->addr;
               $logger->debug("Found $res");
               push( @{$self->{netdevices}},{ IPADDR=>$res }) unless $self->search_netdevice($res);
            }
        } elsif ($common->can_load('Net::Ping'))  {
            $logger->debug("Scanning $net_to_scan with ping");
            my $ping=Net::Ping->new("icmp",1);

            while ($index <= $size) {
                my $res=$block->nth($index);
                if ($ping->ping($res)) {
                    $logger->debug("Found $res");
                    push( @{$self->{netdevices}},{ IPADDR=>$res }) unless $self->search_netdevice($res);
                }
                $index++;
            }
            $ping->close();
        } else {
            $logger->debug("No scan possible");
        }
    } else {
        $logger->debug("Net::Netmask not present: no scan possible");
    }
}

1;