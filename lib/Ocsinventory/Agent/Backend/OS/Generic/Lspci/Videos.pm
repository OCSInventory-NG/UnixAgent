package Ocsinventory::Agent::Backend::OS::Generic::Lspci::Videos;
use strict;

my $memory;
my $chipset;
my $name;

sub run {
    my $params = shift;
    my $common = $params->{common};

   foreach(`lspci`){
       if(/graphics|vga|video|display/i && /^([0-9a-f][0-9a-f]:[0-9a-f][0-9a-f].[0-9a-f])\s([^:]+):\s*(.+?)(?:\(([^()]+)\))?$/i){
           my $slot = $1;
           $chipset = $2;
           $name = $3;
           if (defined $slot) {
               my @detail = `lspci -v -s $slot 2>/dev/null`;
               $memory = 0;
               foreach my $m (@detail) {
                   if ($m =~ /.*Memory.*\s+\(.*-bit,\sprefetchable\)\s\[size=(\d*)M\]/) {
                       $memory += $1;
                   }
               }
               # Don't record zero memory
               $memory = undef if $memory == 0;
           }
           $common->addVideo({
               'CHIPSET'    => $chipset,
               'NAME'       => $name,
               'MEMORY'     => $memory,
           });
       }
   }
}

1;
