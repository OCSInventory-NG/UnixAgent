package Ocsinventory::Agent::Backend::OS::Generic::Batteries::Upower;

use strict;
use warnings;
use Data::Dumper;
use English qw( -no_match_vars ) ;
use vars qw($runAfter);
$runAfter = [ "Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Batteries" ];

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

    print Dumper($battery);

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

    my @bat = `upower -i $batname`;

    my $data = {};
    foreach my $line (@bat) {
	if ($line =~ /^\s*(\S+):\s*(\S+(?:\s+\S+)*)$/) {
	    $data->{$1}=$2;
        }
    }	

    my $battery = {
        NAME            => $data->{'model'},
        CHEMISTRY       => $data->{'technology'},
        SERIAL          => $data->{'serial'},
    };

    my $manufacturer = $data->{'vendor'} || $data->{'manufacturer'};
    #$battery->{MANUFACTURER} = getCanonicalManufacturer($manufacturer) if $manufacturer;

    my $voltage  = $data->{'voltage'};
    $battery->{VOLTAGE} = $voltage if $voltage;

    my $capacity = $data->{'energy-full-design'};
    $battery->{CAPACITY} = $capacity if $capacity;

    my $real_capacity = $data->{'energy-full'};
    $battery->{REAL_CAPACITY} = $real_capacity if defined($real_capacity) && length($real_capacity);

    return $battery;

}

1;
