package Ocsinventory::Agent::Backend::OS::AIX::UUID;
use strict;
use warnings;


sub check {
    my $params = shift;
    my $common = $params->{common};
    return(undef) unless -r '/usr/sbin/lsattr';
    return 1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $uuid = `/usr/sbin/lsattr -El sys0 -a os_uuid | awk '{print \$2}'`;
    chomp $uuid;

    $common->setHardware({
        UUID => $uuid,
    });
}

1;