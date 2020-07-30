package Ocsinventory::Agent::Backend::OS::MacOS::CPU;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return(undef) unless -r '/usr/sbin/system_profiler';
    return(undef) unless $common->can_load("Mac::SysProfile");
    return 1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $processors;
    my $arch;
    my $datawidth;


    # 32 or 64 bits arch?
    my $sysctl_arch = `sysctl -n hw.cpu64bit_capable`;
    if ($sysctl_arch == 1){
       $arch = "x86_64";
       $datawidth = 64;
    } else {
       $arch = "x86";
       $datawidth = 32;
    }

    # How much processor socket ?
    my $ncpu=`sysctl -n hw.packages`;

    # For each processor socket 
    foreach my $cpu (1..$ncpu) {
        $processors->{$cpu}->{MANUFACTURER} =  `sysctl -n machdep.cpu.vendor`;
        if ($processors->{$cpu}->{MANUFACTURER} =~ /(Authentic|Genuine|)(.+)/i) {
            $processors->{$cpu}->{MANUFACTURER} = $2;
        }
        chomp($processors->{$cpu}->{MANUFACTURER} );
        $processors->{$cpu}->{TYPE} = `sysctl -n machdep.cpu.brand_string`;
        chomp($processors->{$cpu}->{TYPE} );
        $processors->{$cpu}->{SPEED} = `sysctl -n hw.cpufrequency` / 1000 / 1000;
        $processors->{$cpu}->{L2CACHESIZE} = `sysctl -n hw.l2cachesize` / 1024;
        $processors->{$cpu}->{CORES} = `sysctl -n machdep.cpu.core_count`;
        chomp($processors->{$cpu}->{CORES});
        $processors->{$cpu}->{THREADS} = `sysctl -n machdep.cpu.thread_count`;
        chomp($processors->{$cpu}->{THREADS});
        $processors->{$cpu}->{LOGICAL_CPUS} = `sysctl -n machdep.cpu.logical_per_package`;
        chomp($processors->{$cpu}->{LOGICAL_CPUS});
        $processors->{$cpu}->{CPUARCH} = $arch;
        $processors->{$cpu}->{DATA_WIDTH} = $datawidth;
        $processors->{$cpu}->{NBSOCKET} = $cpu;
        chomp($processors->{$cpu}->{NBSOCKET});
        $processors->{$cpu}->{SERIALNUMBER} = "N/A";
    }
    
    # Add new cpu infos to inventory
    foreach (keys %{$processors}){
	    $common->addCPU($processors->{$_});
    }
}
1;
