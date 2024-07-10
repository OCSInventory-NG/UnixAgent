package Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Batteries;
use strict;

sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $batt;

    my $infos=$common->getDmidecodeInfos();
    foreach my $info (@{$infos->{22}}) {
        $batt->{MANUFACTURER}   = $info->{'Manufacturer'};
        $batt->{CHEMISTRY}      = $info->{'SBDS Chemistry'};
        $batt->{DESIGNCAPACITY} = $info->{'Design Capacity'};
        $batt->{DESIGNVOLTAGE}  = $info->{'Design Voltage'};
        $batt->{SERIAL}         = $info->{'SBDS Serial Number'} || $info->{'Serial'};
        $batt->{DATE}           = $info->{'SBDS Manufacture Date'};
    }

    if ($batt->{CHEMISTRY} eq "LION") {
        $batt->{CHEMISTRY} = "lithium-ion";
    }

    $common->addBatteries($batt);
}

1;
