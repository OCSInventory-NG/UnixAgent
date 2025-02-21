package Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::UUID;

use strict;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    return $common->can_run('dmidecode') 
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $uuid;

    $uuid = `dmidecode | grep UUID`;
    chomp($uuid);
    $uuid =~ s/UUID//;
    $uuid =~ s/://;
    $uuid =~ s/^\s+|\s+$//g;

    $common->setHardware({
        UUID => $uuid,
    });
}

1;
