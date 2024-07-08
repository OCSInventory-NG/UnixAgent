package Ocsinventory::Agent::Backend::OS::Linux::Archs::ARM::Bios;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_read("/proc/cpuinfo");
    $common->can_run("vcgencmd");
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $current;
    my @infos;

    # processor         : 0
    # model name        : ARMv6-compatible processor rev 7 (v6l)
    # BogoMIPS          : 697.95
    # Features          : half thumb fastmult vfp edsp java tls
    # CPU implementer   : 0x41
    # CPU architecture  : 7
    # CPU variant       : 0x0
    # CPU part          : 0xb76
    # CPU revision      : 7
    #
    # Hardware          : BCM2835
    # Revision          : 0002
    # Serial            : 0000000081355bf5
    # Model             : Raspberry Pi Model B Rev 1
    open INFO, "</proc/cpuinfo" or warn;
    foreach(<INFO>) {
        $current->{SSN} = $1 if /Serial\s+:\s+(\S.*)/;
        $current->{BVERSION} =  $1 if /Revision\s+:\s+(.*)/;
        $current->{TYPE} = $1 if /Model\s+:\s+(.*)/;
        push @infos, $current;
    }
    close(INFO);

    # vcgencmd version
    my $bd=`vcgencmd version | head -1`;
    $bd =~ s/^(#.*\n)//g;
    $bd =~ s/Invalid.*$//g;
    chomp($bd);

    # Writing data
    foreach my $info (@infos) {
        $info->{ASSETTAG}='N/A';
        $info->{SMANUFACTURER}='Raspberry';
        $info->{SMODEL}='Raspberry';
        $info->{BMANUFACTURER}='N/A';
        $info->{BDATE}=$bd;
        $info->{MMANUFACTURER}='N/A';
        $common->setBios($info);
    }
}

1;
