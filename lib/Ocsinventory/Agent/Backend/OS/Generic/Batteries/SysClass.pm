package Ocsinventory::Agent::Backend::OS::Generic::Batteries::SysClass;

use strict;
use warnings;

use vars qw($runAfter);
$runAfter = ["Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Batteries"];

sub run {
    my $params = shift;
    my $common = $params->{common}; 

    

}

1;
