package Ocsinventory::Agent::Backend::OS::Linux::Archs::ARM::CPU;

use strict;
use warnings;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("lscpu");
    $common->can_run("vcgencmd");
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my @cpuinfos=`LANG=C lscpu 2>/dev/null`;
    my $cpu;
    my $nbcpus;
    my $freq;

    foreach my $info (@cpuinfos){
        chomp $info;
        $cpu->{CPUARCH}=$1 if ($info =~ /Architecture:\s*(.*)/i);
        $cpu->{NBCPUS}=$1 if ($info =~ /^CPU\(s\):\s*(\d+)/i);
        $cpu->{THREADS}=$1 if ($info =~ /Thread\(s\)\sper\score:\s*(\d+)/i);
        $cpu->{CORES}=$1 if ($info =~ /Core\(s\)\sper\ssocket:\s*(\d+)/i);
        $cpu->{NBSOCKET}=$1 if ($info =~ /Socket\(s\):\s*(\d+)/i);
        $cpu->{TYPE}=$1 if ($info =~ /Model\sname:\s*(.*)/i);
        $cpu->{MANUFACTURER}=$1 if ($info =~ /Vendor ID:\s*(.+)/i);
        $cpu->{SPEED}=$1 if ($info =~ /CPU max MHZ:\s*(.*)/i);
        if ($cpu->{CPUARCH} && $cpu->{CPUARCH} =~ /(armv[1-7])/){
            $cpu->{DATA_WIDTH}='32';
        } else  {
            $cpu->{DATA_WIDTH}='64';
        } 
    }
    # Frequency 
    $cpu->{CURRENT_SPEED}=`vcgencmd get_config arm_freq | cut -d"=" -f 2`;

    # Total Threads = number of cores x number of threads per core
    $cpu->{THREADS}=$cpu->{CORES}*$cpu->{THREADS};

    # Set LOGICAL_CPUS with THREADS value
    $cpu->{LOGICAL_CPUS}=$cpu->{THREADS};

    for (my $i=0;$i<$cpu->{NBSOCKET};$i++) {
        $common->addCPU($cpu);
    }

}

1;
