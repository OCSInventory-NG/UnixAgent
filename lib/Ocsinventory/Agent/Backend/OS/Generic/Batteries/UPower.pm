package Ocsinventory::Agent::Backend::OS::Generic::Batteries::UPower;

use strict;
use warnings;
use Data::Dumper;
use English qw( -no_match_vars ) ;

sub check {
    my $params = shift;
    my $common = $params->{common};

    return unless $common->can_run("upower");
}

sub run {

    my $params = shift;
    my $common = $params->{common};

    my $battery;

    # Enumarate devices 
    my @batteriesName = _getBatteriesNameFromUpower();

    # 
    return unless @batteriesName; 

    my @batteries = ();
    foreach my $battname (@batteriesName) {
	$battery = _getBatteryFromUpower($battname);
    }

    $common->addBatteries($battery);

}

sub _getBatteriesNameFromUpower {

    my @lines = `upower --enumerate`;

    my @battname;
    for my $line (@lines) {
	if ($line =~ /^(.*\/battery_\S+)$/) {
	    push @battname, $1;
	}
    }

    return @battname;
}

sub _getBatteryFromUpower {

    my ($batname) = @_;

    my @bat = `LANG=C upower -i $batname`;

    my $data = {};
    foreach my $line (@bat) {
	if ($line =~ /^\s*(\S+):\s*(\S+(?:\s+\S+)*)$/) {
	    $data->{$1}=$2;
        }
    }	


    my $battery = {
        DESCRIPTION     => $data->{'model'},
        CHEMISTRY       => $data->{'technology'},
        SERIALNUMBER    => sanitizeBatterySerial($data->{'serial'}),
    };
 
    my $cycle = $data->{'charge-cycles'};
    $battery->{CYCLES} = $cycle if $cycle;
 
    my $manufacturer = $data->{'vendor'} || $data->{'manufacturer'};
    $battery->{MANUFACTURER} = $manufacturer if $manufacturer;

    my $voltage  = $data->{'voltage'};
    $voltage =~ s/\sV+$//;
    $battery->{DESIGNVOLTAGE} = $voltage if $voltage;

    my $capacity = $data->{'energy-full-design'};
    $capacity =~ s/\sWh+$//;
    $battery->{DESIGNCAPACITY} = $capacity if $capacity;

    my $real_capacity = $data->{'energy-full'};
    $real_capacity =~ s/\sV+$//;
    $battery->{CAPACITY} = $real_capacity if defined($real_capacity) && length($real_capacity);
 
    my $status = $data->{'state'};
    $battery->{STATUS} = $status if $status;
  
    my $estimatechargeremaining = $data->{'percentage'};
    $estimatechargeremaining = $1 if ($estimatechargeremaining =~ /(.*)%+$/);
    $battery->{ESTIMATEDCHARGEREMAINING} = $estimatechargeremaining if $estimatechargeremaining;

    return $battery;

}

sub sanitizeBatterySerial {
    my ($serial) = @_;

    # Simply return a '0' serial if not defined
    return '0' unless defined($serial);

    # Simplify zeros-only serial
    return '0' if $serial =~ /^0+$/;

    my ($a,$b) = split(" ", $serial);
    return $a;

    return trimWhitespace($serial)
        unless $serial =~ /^[0-9A-F]+$/i;

    # Prepare to keep serial as decimal if we have recognized it as hexadecimal
    $serial = '0x'.$serial
        if $serial =~ /[a-f]/i || $serial =~ /^0/;

    # Convert as decimal string
    return sprintf("%d", hex2dec($serial));
}

sub trimWhitespace {
    my ($value) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\s+/ /g;
    return $value;
}

1;
