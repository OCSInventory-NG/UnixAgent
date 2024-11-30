package Ocsinventory::Agent::Backend::IpDiscover::IpDiscover;

use strict;
use warnings;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    my $prologresp = $params->{prologresp};
    my $logger = $params->{logger};
    $common->can_run ("ipdiscover");

    # checking scan type
    my $scan_type = $prologresp->getOptionsInfoByName("IPDISCOVER");

    # scan type check 
    # if no scan_type is specified, the default is ICMP
    if (!$scan_type->[0] || !exists($scan_type->[0]->{SCAN_TYPE_IPDISCOVER})) {
        $logger->debug("Will be using ICMP for IpDiscover scan based on default config option");
        return 1;
    }

    if ($scan_type->[0] && exists($scan_type->[0]->{SCAN_TYPE_IPDISCOVER}) && $scan_type->[0]->{SCAN_TYPE_IPDISCOVER} eq "ICMP") {
        $logger->debug("Will be using ICMP for IpDiscover scan based on SCAN_TYPE_IPDISCOVER config option");
        return 1;
    }

    0;
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $prologresp = $params->{prologresp};
    my $logger = $params->{logger};
    
    # Let's find network interfaces and call ipdiscover on it
    my $options = $prologresp->getOptionsInfoByName("IPDISCOVER");
    my $ipdisc_lat;
    my $network;
    
    if ($options->[0] && exists($options->[0]->{IPDISC_LAT}) && $options->[0]->{IPDISC_LAT}) {
        $ipdisc_lat = $options->[0]->{IPDISC_LAT};
    }

    if ($options->[0] && exists($options->[0]->{content})) {
        $network = $options->[0]->{content};
    } else {
        return;
    }
    $logger->debug("Scanning the $network network");
  
    my $legacymode;
    if ($common->can_run("ipdiscover")) {
        if ( `ipdiscover` =~ /binary ver. (\d+)/ ){
            if (!($1>3)) {
                $legacymode = 1;
                $logger->debug("ipdiscover ver.$1: legacymode");
            }
        }
    } 

    my $ifname;
    if ($common->can_run("ip")) {
        foreach (`ip route`) {
            if (/^default via (\d+\d.\d+\.\d+\.\d+) dev (\S+).*/) {
                if ($network = $1 ){
                    $ifname = $2;
                    last;
                } 
            }
        }
    } elsif ($common->can_run("route")){
        foreach (`route -n`) {
            if (/^(\d+\.\d+\.\d+\.\d+).*?\s(\S+)$/) {
                if ($network eq $1) {
                    $ifname = $2;
                    last;
                } elsif (!$ifname && $1 eq "0.0.0.0") {
                    $ifname = $2;
                }
            }
        }
    }
  
    if ($common->can_run("ipdiscover")){
        if ($ifname) {
            my $cmd = "ipdiscover $ifname ";
            $cmd .= $ipdisc_lat if ($ipdisc_lat && !$legacymode);
    
            foreach (`$cmd`) {
                if (/<H><I>([\d\.]*)<\/I><M>([\w\:]*)<\/M><N>(\S*)<\/N><\/H>/) {
                    $common->addIpDiscoverEntry({
                        IPADDRESS => $1,
                        MACADDR => $2,
                        NAME => $3
                    });
                }
            }
        }
    }
}

1;
