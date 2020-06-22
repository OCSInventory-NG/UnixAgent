package Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Psu;

use strict;
use warnings;

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $infos=$common->getDmidecodeInfos();
    my $psu;

    foreach my $info (@{$infos->{39}}) {
        next if $info->{'Type'} && $info->{'Type'} eq 'Battery';
        
        $psu->{NAME}=$1 if ($info =~ /Name:\s*(.*)/i);
        $psu->{LOCATION}=$1 if ($info =~ /Location:\s*(.*)/i);
        $psu->{STATUS}=$1 if ($info =~ /Status:\s*(.*)/i);
        $psu->{SERIALNUMBER}=$1 if ($info =~ /Serial Number:\s*(.*)/i);
        $psu->{PLUGGED}=$1 if ($info =~ /Plugged:\s*(.*)/i);
        $psu->{HOTREPLACEABLE}=$1 if ($info =~ /Hot Replaceable:\s*(.*)/i);
        $psu->{POWERMAX}=$1 if ($info =~ /Max Power Capacity:\s*(.*)/i);
        $psu->{MANUFACTURER}=$1 if ($info =~ /Manufacturer:\s*(.*)/i);
        $psu->{PARTNUMBER}=$1 if ($info =~ /Model Part Number:\s*(.*)/i);

        next unless ($psu);
        next unless ($psu->{'NAME'} || $psu->{'SERIALNUMBER'} || $psu->{'PARTNUMBER'});

        $common->addPSU($psu);
    }

}

1;
