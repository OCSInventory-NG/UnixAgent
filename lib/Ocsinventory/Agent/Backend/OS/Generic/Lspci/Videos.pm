package Ocsinventory::Agent::Backend::OS::Generic::Lspci::Videos;
use strict;
use warnings;

my $memory;
my $resolution;
my $chipset;
my $name;
my $reso;

#sub check {
#    return unless $common->can_run("xrandr");
#    return 1;
#}

sub run {
    my $params = shift;
    my $common = $params->{common};

    foreach(`lspci`){
        if(/graphics|vga|video|display/i && /^\S+\s([^:]+):\s*(.+?)(?:\(([^()]+)\))?$/i){
            $common->addVideo({
               'CHIPSET'  => $1,
               'NAME'     => $2,
            });
        }
    }
}

1;
