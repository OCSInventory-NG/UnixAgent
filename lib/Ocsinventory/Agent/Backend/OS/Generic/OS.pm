package Ocsinventory::Agent::Backend::OS::Generic::OS;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};

    if ($common->can_run("stat")) {
        return 1;
    } else {
        return 0;
    }
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};

    my $installdate;
    my $idate;
    if ($^O =~ /linux/) {
        $idate=`stat -c %W /`;
    } elsif (($^O =~ /bsd/) or ($^O =~ /Darwin/)) { 
        $idate=`stat -f %m /`;
    }

    my ($day,$month,$year)=(localtime($idate))[3,4,5];
    $installdate=sprintf "%02d-%02d-%02d",($year+1900),$month,$day;

    $common->setHardware({
        INSTALLDATE => $installdate
    });
}

1;
