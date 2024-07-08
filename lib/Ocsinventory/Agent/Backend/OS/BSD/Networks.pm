package Ocsinventory::Agent::Backend::OS::BSD::Networks;

use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("ifconfig") && $common->can_load("Net::IP qw(:PROC)")
}


sub _ipdhcp {
    my $if = shift;
  
    my $path;
    my $ipdhcp;
    my $leasepath;
  
    foreach ( # XXX BSD paths
      "/var/db/dhclient.leases.%s",
      "/var/db/dhclient.leases",
      # Linux path for some kFreeBSD based GNU system
      "/var/lib/dhcp3/dhclient.%s.leases",
      "/var/lib/dhcp3/dhclient.%s.leases",
      "/var/lib/dhcp/dhclient.leases") {
  
        $leasepath = sprintf($_,$if);
        last if (-e $leasepath);
    }
    return undef unless -e $leasepath;
  
    if (open DHCP, $leasepath) {
        my $lease;
        my $dhcp;
        my $expire;
        # find the last lease for the interface with its expire date
        while(<DHCP>){
            $lease = 1 if(/lease\s*{/i);
            $lease = 0 if(/^\s*}\s*$/);
            if ($lease) { #inside a lease section
                if (/interface\s+"(.+?)"\s*/){
                    $dhcp = ($1 =~ /^$if$/);
                }
                #Server IP
                if (/option\s+dhcp-server-identifier\s+(\d{1,3}(?:\.\d{1,3}){3})\s*;/x) {
                    $ipdhcp = $1;
                }
                if (/^\s*expire\s*\d\s*(\d*)\/(\d*)\/(\d*)\s*(\d*):(\d*):(\d*)/x) {
                    $expire=sprintf "%04d%02d%02d%02d%02d%02d",$1,$2,$3,$4,$5,$6;
                }
            }
        }
        close DHCP or warn;
        chomp (my $currenttime = `date +"%Y%m%d%H%M%S"`);
        undef $ipdhcp unless $currenttime <= $expire;
    } else {
        warn "Can't open $leasepath\n";
    }
    return $ipdhcp;
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $description;
    my $duplex;
    my $ipaddress;
    my $ipmask;
    my $ipsubnet;
    my $ipaddress6;
    my $ipmask6;
    my $ipsubnet6;
    my $macaddr;
    my $mtu;
    my $speed;
    my $status;
    my $type;
  
    
    my @ifconfig = `ifconfig -a`; # -a option required on *BSD

    # first make the list available interfaces
    # too bad there's no -l option on OpenBSD
    my @list;
    foreach (@ifconfig){
        # skip loopback, pseudo-devices and point-to-point interfaces
        next if /^(lo|fwe|vmnet|sit|pflog|pfsync|enc|strip|plip|sl|ppp)\d+/;
        if (/^(\S+):/) { push @list , $1; } # new interface name      
    }
  
    # for each interface get it's parameters
    foreach $description (@list) {
        $ipaddress = $ipmask = $macaddr = $status =  $type = $mtu = $speed = $ipaddress6 = $ipmask6 = $ipsubnet6 = undef;
        # search interface infos
        @ifconfig = `ifconfig $description`;
        foreach (@ifconfig){
            $ipaddress = $1 if /inet (\S+)/i;
            if (/inet6 ([\w:]+)\S* prefixlen (\d+)/) {
                $ipaddress6=$1;
                $ipmask6=getIPNetmaskV6($2);
                $ipsubnet6=getSubnetAddressIPv6($ipaddress6,$ipmask6);
            }
            $ipmask = $1 if /netmask\s+(\S+)/i;
            $macaddr = $2 if /(address:|ether|lladdr)\s+(\S+)/i;
            $status = 1 if /<UP/i;
            $type = $1 if /media:\s+(\S+)/i;
            $speed = $1 if /media:\s+\S+\s\S+\s\((\d+)/i;  # Ethernet autoselect (1000baseT <full-duplex>)
            $mtu = $1 if /mtu (\d+)/i;
        }

        # In BSD, netmask is given in hex form
        my $binmask = sprintf("%b", oct($ipmask));
        $ipmask = ip_bintoip($binmask,4);
  
        if ($description & $ipaddress ) {
            $common->addNetwork({
                DESCRIPTION => $description,
                IPADDRESS => $ipaddress,
                IPDHCP => _ipdhcp($description),
                IPGATEWAY => getRoute($ipaddress),
                IPMASK => $ipmask,
                IPSUBNET => getSubnetAddressIPv4($ipaddress,$ipmask),
                MACADDR => $macaddr,
                MTU => $mtu,
                SPEED => getSpeed($speed),
                STATUS => $status?"Up":"Down",
                TYPE => $type,
            });
            # Set default gateway in hardware info
            $common->setHardware({
                DEFAULTGATEWAY => getRoute($ipaddress6)
            });
        } else {
            $common->addNetwork({
                DESCRIPTION => $description,
                IPADDRESS => $ipaddress6,
                IPDHCP => _ipdhcp($description),
                IPGATEWAY => getRoute($ipaddress6),
                IPMASK => getIPNetmaskV6($ipaddress6),
                IPSUBNET => getSubnetAddressIPv6($ipaddress6,$ipmask6),
                MACADDR => $macaddr,
                MTU => $mtu,
                SPEED => getSpeed($speed),
                STATUS => $status?"Up":"Down",
                TYPE => $type,
            });
            # Set default gateway in hardware info
            $common->setHardware({
                DEFAULTGATEWAY => getRoute($ipaddress6)
            });
        }
    }
}

sub getSpeed{
    my ($speed)=@_;

    return unless $speed;

    if ($speed gt 100 ){
        $speed = ($speed/1000)." Gbps";
    } else {
        $speed = $speed." Mbps";
    }

    return $speed;

}

sub getSubnetAddressIPv4 {
    my ($address,$mask)=@_;

    return undef unless $address && $mask;

    my $binaddress=ip_iptobin($address, 4);
    my $binmask=ip_iptobin($mask, 4);
    my $binsubnet=$binaddress & $binmask;

    return ip_bintoip($binsubnet, 4);
}

sub getSubnetAddressIPv6 {
    my ($address,$mask)=@_;

    return undef unless $address && $mask;

    my $binaddress = ip_iptobin(ip_expand_address($address, 6),6);
    my $binmask    = ip_iptobin(ip_expand_address($mask, 6),6);
    my $binsubnet  = $binaddress & $binmask;

    return ip_compress_address(ip_bintoip($binsubnet, 6),6);
}

sub getIPNetmaskV6 {
    my ($prefix) = @_;

    return undef unless $prefix;
    return ip_compress_address(ip_bintoip(ip_get_mask($prefix, 6), 6),6);
}

sub getRoute {
    # Looking for the gateway
    # 'route show' doesn't work on FreeBSD so we use netstat
    # XXX IPV4 only
    my ($prefix) = @_;
    my $route;

    return undef unless $prefix;

    if (ip_is_ipv4($prefix)) {
        for (`netstat -rn -f inet`){
            $route = $1 if /^default\s+(\S+)/i;
        }
    } elsif (ip_is_ipv6($prefix)) {
        for (`netstat -rn -f inet6`){
            $route = $1 if /^default\s+(\S+)/i;
        }
    }
    return $route;
}

1;
__END__

=head1 NAME

OCSInventory::Agent::Backend::OS::BSD::Networks - Network-related information

=head1 DESCRIPTION

This module retrieves network information.

=head1 FUNCTIONS

=head2 getSpeed

Returns the speed of the card.

=head2 getRoute

Returns the gateway

=head2 getIPNetmaskV4

Returns the IP v4 network mask 

=head2 getIPNetmaskV6

Returns the IP v6 network mask 

=head2 getSubnetAddressIPv4 

Returns the subnet of ip v4 network

=head2 getSubnetAddressIPv6 

Returns the subnet of ip v6 network
