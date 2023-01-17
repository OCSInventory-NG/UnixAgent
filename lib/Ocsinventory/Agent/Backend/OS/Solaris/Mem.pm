package Ocsinventory::Agent::Backend::OS::Solaris::Mem;

use strict;

sub check { 
      my $params = shift;
      my $common = $params->{common};
      $common->can_run ("swap") && $common->can_run ("prtconf") 
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    #my $unit = 1024;

    my $PhysicalMemory;
    my $SwapFileSize=0;

    # Memory informations
    foreach(`prtconf`){
      if(/^Memory\ssize:\s+(\S+)/){
      #print "total memoire: $1";
      $PhysicalMemory = $1};     
    }

    #Swap Informations 
    foreach(`swap -l`){
      if(/(\d+)(?!.*\d)/g){$SwapFileSize = $SwapFileSize + $1};
    }

    $common->setHardware({
        MEMORY =>  $PhysicalMemory,
        SWAP =>    $SwapFileSize
    });
}

1
