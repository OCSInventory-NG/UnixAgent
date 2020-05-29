package Ocsinventory::Agent::Backend::OS::Linux::Videos;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run ("nvidia-smi");
    return unless $common->can_run ("nvidia-settings");
}

sub run {

    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};

    my $nvidia;
    my @nvidia_infos=`nvidia-smi -q`;
    my @nvidia_settings=`nvidia-settings -q all`;
    my @prime=`nvidia-settings --query=PrimeOutputsData`;
    
    foreach my $info (@nvidia_infos) {
        $nvidia->{SERIALNUMBER}=$1 if ($info =~ /Serial Number\s+: (.*)/i);
        $nvidia->{DRVVERSION}=$1 if ($info =~ /Driver Version\s+: ([0-9]+\.[0-9]+)/i);
        $nvidia->{NBGPU}=$1 if ($info =~ /Attached GPUs\s+: ([0-9])/i);
        $nvidia->{VBIOS}=$1 if ($info =~ /VBIOS Version\s+: (.*)/i);
        $nvidia->{NAME}=$1 if ($info =~ /Product Name\s+:(.*)/i);
        $nvidia->{UUID}=$1 if ($info =~ /GPU UUID\s+:(.*)/i);
        $nvidia->{PCISLOT}=$1 if ($info =~ /Bus Id\s+:(.*)/i);
    }

    # Resolution 
    foreach my $inf (@prime) {
        next if ($inf =~ /^\s*$/);
        my $width=$1 if ($inf =~ /width=(\d{1,4})/);
        my $height=$1 if ($inf =~ /height=(\d{1,4})/);
        $nvidia->{RESOLUTION}=$width."x".$height;
    }

    $nvidia->{MEMORY}=`nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits`;
    $nvidia->{MEMORY} =~ s/\s+$//g;
    $nvidia->{NAME} =~ s/^\s//g;
    $nvidia->{UUID} =~ s/^\s//g;
    $nvidia->{PCISLOT} =~ s/^\s0{8}://g;
    foreach my $settings (@nvidia_settings) {
        $nvidia->{DATA_WIDTH}=$1 if ($settings =~ /Attribute \'GPUMemoryInterface\'\s\(.*\):\s(\d{2})./i);
        $nvidia->{CUDACORES}=$1 if ($settings =~ /Attribute \'CUDACores\'\s\(.*\):\s(\d{2})./i);
    }

    for (my $i=0; $i<$nvidia->{NBGPU};$i++) {
        $common->addVideo($nvidia);
    }
}

1;
