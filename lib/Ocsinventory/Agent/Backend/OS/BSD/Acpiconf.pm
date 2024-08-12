package Ocsinventory::Agent::Backend::OS::BSD::Acpiconf;

use strict;
use warnings;
use Data::Dumper;
use English qw( -no_match_vars ) ;

sub check {
    my $params = shift;
    my $common = $params->{common};

    return unless $common->can_run("acpiconf");
}

sub run {

    my $params = shift;
    my $common = $params->{common};

    my $battery;
    my $index=0;

    my @bat = `acpiconf -i $index`;

    my $data = {};
    foreach my $line (@bat) {
	if ($line =~ /^\s(.*):\s*(\S+(?:\s+\S+)*)$/) {
	    $data->{$1}=$2;
        }
    }	

    $battery = {
        NAME            => $data->{'Model number'},
        CHEMISTRY       => $data->{'Type'},
        SERIAL          => $data->{'Serial number'},
    };

    if ($battery->{CHEMISTRY} eq "LION") { 
        $battery->{CHEMISTRY} = "Lithium-Ion";
    }

    my $voltage  = $data->{'Design voltage'};
    $battery->{VOLTAGE} = $voltage if $voltage;

    my $capacity = $data->{'Design capacity'};
    $battery->{CAPACITY} = $capacity if $capacity;

    my $real_capacity = $data->{'Last full capacity'};
    $battery->{REAL_CAPACITY} = $real_capacity if defined($real_capacity) && length($real_capacity);

    $common->addBatteries($battery);

}

1;
