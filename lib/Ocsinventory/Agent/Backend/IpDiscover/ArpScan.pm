package Ocsinventory::Agent::Backend::IpDiscover::ArpScan;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};
    my $prologresp = $params->{prologresp};
    my $logger = $params->{logger};
    $common->can_run("arp-scan");

    my $scan_type = $prologresp->getOptionsInfoByName("IPDISCOVER");
    # scan type check 
    if ($scan_type->[0] && exists($scan_type->[0]->{SCAN_TYPE_IPDISCOVER}) && $scan_type->[0]->{SCAN_TYPE_IPDISCOVER} eq "ARPSCAN") {
        $logger->debug("Will be using ARPSCAN for IpDiscover scan based on SCAN_TYPE_IPDISCOVER config option");
        return 1;
    }

    0;
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $prologresp = $params->{prologresp};
    my $logger = $params->{logger};

    # Get network interface and network to be scanned
    my $options = $prologresp->getOptionsInfoByName("IPDISCOVER");
    my $arp_bandwidth = $options->[0]->{SCAN_ARP_BANDWIDTH};
    

    my $network;
    if ($options->[0] && exists($options->[0]->{content})) {
        $network = $options->[0]->{content};
    } else {
        return;
    }

    unless ($network =~ /^\d+\.\d+\.\d+\.\d+$/) {
        return;
    }

    # Scanning the network and parsing the results
    $logger->debug("Scanning the $network network using arp-scan");
    # # lets check the routing table to see what the default gateway is
    my $default_gateway = `ip route | grep default | awk '{print \$5}'`;
    # # get the first line of the output if multiple lines are returned
    $default_gateway = (split /\n/, $default_gateway)[0];
    chomp($default_gateway);
    # bandwith is in packets per second but server gives us kbps
    $arp_bandwidth = $arp_bandwidth * 1024;
    my $cmd = "arp-scan --interface=$default_gateway --localnet --bandwidth=$arp_bandwidth";
    my $res = `$cmd`;

    # arp scan is successful, now handle the output : we check for the starting line and then for ip addresses
    if ($res =~ /Starting arp-scan/) {
        my @lines = split /\n/, $res;
        foreach my $line (@lines) {
            if ($line =~ /([0-9]{1,3}\.){3}[0-9]{1,3}/) {
                my $ip = $&;
                my $mac = (split /\s+/, $line)[1];
                my $hostname = (split /\s+/, $line)[2];
                $logger->debug("Found $ip");
                # Feeding the Inventory XML
                $common->addIpDiscoverEntry({
                    IPADDRESS => $ip,
                    MACADDR => lc($mac),
                    NAME => $hostname,
                });
            }
        }
    } else {
        $logger->debug("arp-scan failed");
    }

}

1;
