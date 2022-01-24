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
no strict 'subs';
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
                        PRIVPASSWD=>$_->{PRIVPASSWD},
                        LEVEL=>$_->{LEVEL}
                    };
                }
                if ($_->{'TYPE'} eq 'NETWORK'){
                    push @{$self->{nets_to_scan}},$_->{SUBNET};
                }

                if ($_->{'TYPE'} eq 'SNMP_TYPE'){
                    if($_->{TABLE_TYPE_NAME} ne 'snmp_default') {
                        push @{$self->{snmp_type_condition}},{
                            TABLE_TYPE_NAME => $_->{TABLE_TYPE_NAME},
                            CONDITION_OID => $_->{CONDITION_OID},
                            CONDITION_VALUE => $_->{CONDITION_VALUE}
                        };
                    } else {
                        push @{$self->{snmp_type_condition_default}},{
                            TABLE_TYPE_NAME => $_->{TABLE_TYPE_NAME},
                            CONDITION_OID => $_->{CONDITION_OID}
                        };
                    }

                    push @{$self->{snmp_type_infos}},{
                        TABLE_TYPE_NAME => $_->{TABLE_TYPE_NAME},
                        LABEL_NAME => $_->{LABEL_NAME},
                        OID => $_->{OID}
                    };
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
    # Load setting from the config file
    my $configagent = new Ocsinventory::Agent::Config;
    $configagent->loadUserParams();
    
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
        my $oid_condition = undef;
        my $devicedata = $common->{xmltags};     #To fill the xml informations for this device
        my $snmp_table = undef;
        my $snmp_condition_oid = undef;
        my $snmp_condition_value = undef;
        my $regex = undef;

        $logger->debug("Scanning $device->{IPADDR} device");
        # Search for the good snmp community in the table community
        LIST_SNMP: foreach $comm ( @$communities ) {
            # Test if we use SNMP v3
            if ( $comm->{VERSION} eq "3" ) {
                if($comm->{LEVEL} eq '' || $comm->{LEVEL} eq 'noAuthNoPriv') {
                    ($session, $error) = Net::SNMP->session(
                        -retries       => $configagent->{config}{snmpretry}, # SNMP retry in config file
                        -timeout       => $configagent->{config}{snmptimeout}, # SNMP Timeout in config file 
                        -version       => 'snmpv'.$comm->{VERSION},
                        -hostname      => $device->{IPADDR},
                        -translate     => [-nosuchinstance => 0, -nosuchobject => 0, -octetstring => 0],
                        -username      => $comm->{USERNAME}
                    );
                }

                if($comm->{LEVEL} eq 'authNoPriv') {
                    if($comm->{AUTHPROTO} eq '') {
                        $comm->{AUTHPROTO} = "md5";
                    }
                    ($session, $error) = Net::SNMP->session(
                        -retries       => $configagent->{config}{snmpretry}, # SNMP retry in config file
                        -timeout       => $configagent->{config}{snmptimeout}, # SNMP Timeout in config file 
                        -version       => 'snmpv'.$comm->{VERSION},
                        -hostname      => $device->{IPADDR},
                        -translate     => [-nosuchinstance => 0, -nosuchobject => 0, -octetstring => 0],
                        -username      => $comm->{USERNAME},
                        -authprotocol  => $comm->{AUTHPROTO},
                        -authpassword  => $comm->{AUTHPASSWD}
                    );
                }

                if($comm->{LEVEL} eq 'authPriv') {
                    if($comm->{AUTHPROTO} eq '') {
                        $comm->{AUTHPROTO} = "md5";
                    }
                    if($comm->{PRIVPROTO} eq '') {
                        $comm->{PRIVPROTO} = "des";
                    }
                    ($session, $error) = Net::SNMP->session(
                        -retries       => $configagent->{config}{snmpretry}, # SNMP retry in config file
                        -timeout       => $configagent->{config}{snmptimeout}, # SNMP Timeout in config file 
                        -version       => 'snmpv'.$comm->{VERSION},
                        -hostname      => $device->{IPADDR},
                        -translate     => [-nosuchinstance => 0, -nosuchobject => 0, -octetstring => 0],
                        -username      => $comm->{USERNAME},
                        -authprotocol  => $comm->{AUTHPROTO},
                        -authpassword  => $comm->{AUTHPASSWD},
                        -privpassword  => $comm->{PRIVPASSWD},
                        -privprotocol  => $comm->{PRIVPROTO}
                    );
                }

                # For a use in constructor module (Cisco)
                $self->{username}=$comm->{USERNAME};
                $self->{authpassword}=$comm->{AUTHPASSWD};
                $self->{authprotocol}=$comm->{AUTHPROTO};
                $self->{privpassword}=$comm->{PRIVPASSWD};
                $self->{privprotocol}= $comm->{PRIVPROTO};

            } else {
                # We have an older version v2c ou v1
                ($session, $error) = Net::SNMP->session(
                    -retries     => $configagent->{config}{snmpretry}, # SNMP retry in config file
                    -timeout     => $configagent->{config}{snmptimeout}, # SNMP Timeout in config file 
                    -version     => 'snmpv'.$comm->{VERSION},
                    -hostname    => $device->{IPADDR},
                    -community   => $comm->{NAME},
                    -translate   => [-nosuchinstance => 0, -nosuchobject => 0, -octetstring => 0],
                );
            };
            unless (defined($session)) {
                $logger->error("Snmp INFO: $error");
            } else {
                $self->{snmp_session}=$session;

                # For a use in constructor module (Cisco)
                $self->{snmp_community}=$comm->{NAME}; 
                $self->{snmp_version}=$comm->{VERSION};

                my $snmp_key = $self->{snmp_type_condition};
                my $snmp_key_default = $self->{snmp_type_condition_default};

                LIST_TYPE: foreach my $snmp_value (@$snmp_key) {
                    $oid_condition = $session->get_request(-varbindlist => [$snmp_value->{CONDITION_OID}]);
                    $snmp_table = $snmp_value->{TABLE_TYPE_NAME};
                    $snmp_condition_oid = $snmp_value->{CONDITION_OID};
                    $snmp_condition_value = $snmp_value->{CONDITION_VALUE};
                    $regex = $self->regex($snmp_condition_value);

                    last LIST_TYPE if (defined $oid_condition && ($oid_condition->{$snmp_value->{CONDITION_OID}} eq $snmp_value->{CONDITION_VALUE} || $oid_condition->{$snmp_value->{CONDITION_OID}} =~ /$regex/));
                }

                last LIST_SNMP if (defined $oid_condition && ($oid_condition->{$snmp_condition_oid} eq $snmp_condition_value || $oid_condition->{$snmp_condition_oid} =~ /$regex/));

                LIST_TYPE: foreach my $snmp_value_default (@$snmp_key_default) {
                    $oid_condition = $session->get_request(-varbindlist => [$snmp_value_default->{CONDITION_OID}]);
                    $snmp_table = $snmp_value_default->{TABLE_TYPE_NAME};
                    $snmp_condition_oid = $snmp_value_default->{CONDITION_OID};

                    last LIST_TYPE if (defined $oid_condition);
                }

                last LIST_SNMP if (defined $oid_condition && $snmp_table eq 'snmp_default');

                $session->close;
                $self->{snmp_session}=undef;
            }
        }

        if (defined $oid_condition) {
            my $xmltags = $common->{xmltags};
            
            $session->max_msg_size(8192);
            # We have found the good Community, we can scan this equipment
            # We indicate that we scan a new equipment
            $self->{number_scan}++;
            
            my $data;

            my $snmp_infos = $self->{snmp_type_infos};

            foreach my $datas (@$snmp_infos) {
                my $data_value = undef;
                if($datas->{TABLE_TYPE_NAME} eq $snmp_table) {
                    $data = $session->get_request(-varbindlist => [$datas->{OID}]);
                    $data_value = $data->{$datas->{OID}};
                    if(defined $data_value && $data_value =~ m/([\x{0}-\x{9}]|[\x{B}-\x{C}]|[\x{E}-\x{1F}]|[\x{7F}-\x{FF}])/) {
                        $data_value = unpack "H*", $data_value;
                        $data_value = substr $data_value, 2;
                        my @split = unpack '(A2)*', $data_value;
                        $data_value = uc(join ':', @split);
                    }
                    if(!defined $data_value || $data_value eq '') {
                        my @table;
                        $data = $session->get_table(-baseoid => $datas->{OID});
                        foreach my $key (keys %{$data}) {
                            if(defined $data->{$key} && $data->{$key} =~ m/([\x{0}-\x{9}]|[\x{B}-\x{C}]|[\x{E}-\x{1F}]|[\x{7F}-\x{FF}])/) {
                                $data->{$key} = unpack "H*", $data->{$key};
                                $data->{$key} = substr $data->{$key}, 2;
                                my @split = unpack '(A2)*', $data->{$key};
                                $data->{$key} = uc(join ':', @split);
                            }
                            push @table, $data->{$key};
                        }
                        $data_value = join ' - ', @table;
                    }
                    $xmltags->{$datas->{LABEL_NAME}}[0] = $data_value;
                } 
            }

            push @{$snmp_inventory->{xmlroot}->{CONTENT}->{$snmp_table}},$xmltags;

            # We have finished with this equipment
            if (defined $session) {
                $session->close;
            }
            $self->{snmp_session}=undef;
            # We clear the xml data for this device 
            $common->flushXMLTags(); 
        }
    }

    $logger->info("No more SNMP device to scan"); 

    # Formatting the XML and sendig it to the server
    my $content = XMLout( $snmp_inventory->{xmlroot},  RootName => 'REQUEST' , XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>', SuppressEmpty => undef );

    #Cleaning XML to delete unprintable characters
    my $clean_content = $common->cleanXml($content);

    $network->sendXML({message => $clean_content});
    $logger->debug("End snmp_end_handler :)");
}

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

            $nmaparser->parsescan("nmap","-sn",$net_to_scan);
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

sub search_netdevice {
    my ($self,$ip)= @_ ;

    for (@{$self->{netdevices}}) {
        if ($ip =~ /^$_->{IPADDR}$/) {
            return 1;
        }
    }
}

sub regex {
    my ($self,$regex) = @_;

    if(($regex !~ m/\*/)){
      $regex = "\^".$regex."\$";
    }
    if((substr( $regex, -1) eq '*') && (substr( $regex, 0, 1) eq '*')){
      $regex = $regex =~ s/\*//gr;
    }
    if((substr( $regex, 0, 1 ) eq '*') && (substr( $regex, -1) ne '*')){
      $regex = $regex =~ s/\*//gr;
      $regex = $regex."\$";
    }
    if((substr( $regex, -1) eq '*') && (substr( $regex, 0, 1) ne '*')){
      $regex = $regex =~ s/\*//gr;
      $regex = "\^".$regex;
    }

    return $regex;
}

1;
