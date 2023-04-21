package Ocsinventory::Agent::Modules::SnmpScan::LocalSnmpScan;

#####################
# LocalSnmpScan module
# This module performs a SNMP scan if the agent is running on local mode
# SNMP configuration must prealably be stored into /etc/ocsinventory-agent/snmp/
#####################

use strict;
no strict 'refs';
no strict 'subs';
use warnings;

use XML::Simple;
use Digest::MD5;
use Data::Dumper;

use Ocsinventory::Agent::Modules::SnmpScan ();
our @ISA = qw(Ocsinventory::Agent::Modules::SnmpScan);


sub new {
    my $name="localsnmpscan";   #Set the name of your module here

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
        prolog_reader => undef, 
        inventory_handler => $name."_inventory_handler",
        end_handler => $name."_end_handler",
    };

    # We create a xml for the snmp inventory that we will be sent to server
    $self->{inventory}={};

    bless $self;
}

sub localsnmpscan_start_handler {     
    my $self = shift;
    my $logger = $self->{logger};
    my $common = $self->{context}->{common};
    my $config = $self->{context}->{config};
    
    $logger->debug("Calling localsnmp_start_handler");

    # If local mode is enabled and local snmp is enabled
    if ($config->{local} && $config->{localsnmp}) {
        $logger->info("Agent is configured to run in local mode and local snmp is enabled, checking local snmp prerequisites");
    } else {
        $logger->info("Agent is not configured to run in local mode or local snmp is not enabled, disabling module");
        $self->{disabled} = 1;
        return;
    }

    # If we cannot load prerequisite, we disable the module 
    unless ($common->can_load('Net::SNMP')) { 
        $self->{disabled} = 1;
        $logger->error("Net::SNMP perl module is missing !!");
        $logger->error("Humm my prerequisites are not OK...disabling module :( :(");
    }


    # check for mandatory snmp configuration files in /etc/ocsinventory/ocsinventory-agent/snmp/ or equivalent
    # xml files : communities / types / subnets / scans conf
    # if one of these files is missing, we disable the module
    # iterate through the list of etcdir to check if one of them contains the mandatory files
    my $found = 0;
    foreach my $etcdir (@{$config->{etcdir}}) {
        if (-e $etcdir."/snmp/localsnmp_types_conf.xml" && -e $etcdir."/snmp/subnets.txt" && -e $etcdir."/snmp/localsnmp_communities_conf.xml" && -e $etcdir."/snmp/localsnmp_scans_conf.xml") {
            $found = 1;
            last;
        }
    }

    if (!$found) {
        $self->{disabled} = 1;
        $logger->error("communities.xml, subnets.xml or types.xml file is missing !!");
        $logger->error("Humm my prerequisites are not OK...disabling module :( :(");
    }

}


sub localsnmpscan_inventory_handler {
    my $self = shift;
    my $logger = $self->{logger};
    my $common = $self->{context}->{common};
    my $config = $self->{context}->{config};

    $logger->debug("Calling localsnmp_inventory_handler");


    # iterate through the list of etcdir to check if one of them contains the mandatory files
    my $etc;
    foreach my $etcdir (@{$config->{etcdir}}) {
        if (-e $etcdir."/snmp/localsnmp_communities_conf.xml" && -e $etcdir."/snmp/subnets.txt" && -e $etcdir."/snmp/localsnmp_types_conf.xml") {
            $etc = $etcdir;
            last;
        }
    }

    my $subnets = $self->readSubnetsConf($etc);
    $self->{nets_to_scan} = $subnets;

    my $communities = $self->readCommunitiesConf($etc);
    $self->{communities} = $communities;

    my $types = $self->readTypesConf($etc);
    $self->{types} = $types;

    my $configurations = $self->readScanConf($etc);
    $self->{configurations} = $configurations;

    # print 
    print Dumper($self->{nets_to_scan});
    print Dumper($self->{communities});
    print Dumper($self->{types});
    print Dumper($self->{configurations});
    

}

sub localsnmpscan_end_handler {
    # can i call the snmpscan end handler method from snmpscan module ?
    my $self = shift;
    my $logger = $self->{logger};
    my $common = $self->{context}->{common};

    $logger->debug("Calling localsnmp_end_handler");
    $self->{doscans} = 1;
    Ocsinventory::Agent::Modules::SnmpScan::snmpscan_end_handler($self);
}

# Override the snmpscan handleXml method to write the xml to the path passed by --local, along with the xml of the agent
sub handleXml() {
    my ($self, $clean_content) = @_;
    print Dumper("handleXml SUBMODULE");
    # write XML in provided path
    my $file = $self->{context}->{config}->{local}."/snmp.xml";
    # Open the file in write mode and write the content to it
    open(my $fh, '>', $file) or die "Could not open file '$file' $!";
    close $fh;
}

sub readCommunitiesConf {
    my ($self, $etc) = @_;

    my $xml = XML::Simple->new();
    my $data = $xml->XMLin($etc . "/snmp/localsnmp_communities_conf.xml");

    $data->{COMMUNITY} = [$data->{COMMUNITY}] unless ref($data->{COMMUNITY}) eq 'ARRAY';
        foreach my $community (@{$data->{COMMUNITY}}) {
            push @{$self->{communities}},{
                VERSION=> $community->{VERSION},
                NAME=>$community->{NAME},
                USERNAME=>$community->{USERNAME},
                AUTHPROTO=>$community->{AUTHPROTO},
                AUTHPASSWD=>$community->{AUTHPASSWD},
                PRIVPROTO=>$community->{PRIVPROTO},
                PRIVPASSWD=>$community->{PRIVPASSWD},
                LEVEL=>$community->{LEVEL}
            };

        }

    return $data->{COMMUNITY};
}

sub readTypesConf {
    my ($self, $etc) = @_;

    my $xml = XML::Simple->new();
    my $data = $xml->XMLin($etc . "/snmp/localsnmp_types_conf.xml");

    $data->{TYPE} = [$data->{TYPE}] unless ref($data->{TYPE}) eq 'ARRAY';

    foreach my $type (@{$data->{TYPE}}) {
        if($type->{TABLE_TYPE_NAME} ne 'snmp_default') {
            push @{$self->{snmp_type_condition}},{
                TABLE_TYPE_NAME => $type->{TABLE_TYPE_NAME},
                CONDITION_OID => $type->{CONDITION_OID},
                CONDITION_VALUE => $type->{CONDITION_VALUE}
            };
        } else {
            push @{$self->{snmp_type_condition_default}},{
                TABLE_TYPE_NAME => $type->{TABLE_TYPE_NAME},
                CONDITION_OID => $type->{CONDITION_OID}
            };
        }

        
        push @{$self->{snmp_type_infos}},{
            TABLE_TYPE_NAME => $type->{TABLE_TYPE_NAME},
            LABEL_NAME => $type->{LABEL_NAME},
            OID => $type->{OID}
        };
    }

    return $data->{TYPE};
}

sub readSubnetsConf {
    my ($self, $etc) = @_;

    my $xml = XML::Simple->new();
    my $data = $xml->XMLin($etc . "/snmp/localsnmp_subnets_conf.xml");

    $data->{SUBNET} = [$data->{SUBNET}] unless ref($data->{SUBNET}) eq 'ARRAY';
    foreach my $subnet (@{$data->{SUBNET}}) {
        push @{$self->{nets_to_scan}}, $subnet->{TVALUE};
    }

    return $self->{nets_to_scan};
}


sub readScanConf {
    my ($self, $etc) = @_;

    my $xml = XML::Simple->new();
    my $data = $xml->XMLin($etc . "/snmp/localsnmp_scans_conf.xml");

    $data->{CONF} = [$data->{CONF}] unless ref($data->{CONF}) eq 'ARRAY';

    foreach my $conf (@{$data->{CONF}}) {
        if ($conf->{NAME} eq 'SCAN_TYPE_SNMP') {
            $self->{scan_type_snmp} = $conf->{TVALUE};
        }
        if ($conf->{NAME} eq 'SCAN_ARP_BANDWIDTH') {
            $self->{scan_arp_bandwidth} = $conf->{IVALUE};
        }

    }

    return $data->{CONF};
}

1;