package Ocsinventory::Agent::Backend::OS::Generic::Lspci::Videos;
use strict;

my $memory;
my $resolution;
my $chipset;
my @resolution;
my ($ret,$handle,$i,$count,$clock,$driver_version, $nvml_version, $memtotal, $serial, $bios_version, $uuid, $name);
my $reso;

#sub check {
#    return unless $common->can_run("xrandr");
#    return 1;
#}

sub run {
    my $params = shift;
    my $common = $params->{common};

    if ($common->can_run("xrandr")) {
        if ($common->can_run("nvidia-smi")) {
            if ($common->can_load("nvidia::ml qw(:all)")){
                nvmlInit();
                # Retrieve driver version
                ($ret, $driver_version) = nvmlSystemGetDriverVersion();
                die nvmlErrorString($ret) unless $ret == $nividia::ml::bindings::NVML_SUCCESS;

                # Retrieve NVML version
                ($ret, $nvml_version) = nvmlSystemGetNVMLVersion();
                die nvmlErrorString($ret) unless $ret == $nividia::ml::bindings::NVML_SUCCESS;

                # How many nvidia cards are present?
                ($ret, $count) = nvmlDeviceGetCount();
                die nvmlErrorString($ret) unless $ret == $nividia::ml::bindings::NVML_SUCCESS;

                for ($i=0; $i<$count; $i++) {
                    ($ret, $handle) = nvmlDeviceGetHandleByIndex($i);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;

                    ($ret, $name) = nvmlDeviceGetName($handle);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;

                    ($ret, $memtotal) = nvmlDeviceGetMemoryInfo($handle);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;
                    $memtotal = ($memtotal->{"total"} / 1024 / 1024);

                    ($ret, $serial) = nvmlDeviceGetSerial($handle);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;

                    ($ret, $bios_version) = nvmlDeviceVBiosVersion($handle);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;

                    ($ret, $uuid) = nvmlDeviceGetUUID($handle);
                    next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;
                }
                nvmlShutdown();
                my @resol= `xrandr --verbose | grep *current`; 
                foreach my $r (@resol){
                    if ($r =~ /((\d{3,4})x(\d{3,4}))/){
                        push(@resolution,$1);
                    }
                }    
                foreach my $res (@resolution){
                    $reso = $res;
                }
                $common->addVideo({
                    NAME => $name,
                    MEMORY => $memtotal,
                    DRVVERSION => $driver_version,
                    NVMLVERSION => $nvml_version,
                    SPEED => $clock,
                    SERIAL => $serial,
                    VBIOS => $bios_version,
                    UUID => $uuid,
                    RESOLUTION => $reso,
                });
            } else {

                my $smi_memory_header = `nvidia-smi --query-gpu=memory.total --format=csv | grep memory.total`;
                if ($smi_memory_header ne '') {
                    my $smi_memory_unit;
                    if ($smi_memory_header =~ m/^memory\.total \[(.*)\]$/) {
                        $smi_memory_unit = $1;
                    }

                    foreach my $smicard (`nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits`){
                        my @smicard_arr=split(/,/, $smicard);
                        $name = $smicard_arr[0];
                        if ($smi_memory_unit eq 'MiB') {
                            $memory=$smicard_arr[1];
                            $memory =~ s/^\s+//;
                        }
                        $driver_version=$smicard_arr[2];
                        $driver_version =~ s/^\s+//;
                        chomp  $driver_version;
                        $common->addVideo({
                            NAME => $name,
                            MEMORY => $memory,
                            DRVVERSION => $driver_version,
                        });
                    }
                 } else {
                    foreach(`lspci`){
                        if(/graphics|vga|video/i && /^([0-9a-f][0-9a-f]:[0-9a-f][0-9a-f].[0-9a-f])\s([^:]+):\s*(.+?)(?:\(([^()]+)\))?$/i){
                            my $slot = $1;
                            $chipset = $2;
                            $name = $3;
                            $common->addVideo({
                                'CHIPSET'    => $chipset,
                                'NAME'       => $name,
                            });
                        }
                    }

               }


            }
        } else {
            foreach(`lspci`){
                if(/graphics|vga|video/i && /^([0-9a-f][0-9a-f]:[0-9a-f][0-9a-f].[0-9a-f])\s([^:]+):\s*(.+?)(?:\(([^()]+)\))?$/i){
                    my $slot = $1;
                    $chipset = $2;
                    $name = $3;
                    if (defined $slot) {
                        my @detail = `lspci -v -s $slot`;
                        $memory = 0;
                        foreach my $m (@detail) {
                            if ($m =~ /.*Memory.*\s+\(.*-bit,\sprefetchable\)\s\[size=(\d*)M\]/) {
                                $memory += $1;
                            }
                        }
                        # Don't record zero memory
                        $memory = undef if $memory == 0;
                    }
                    my @resol= `xrandr --verbose | grep *current`; 
                    foreach my $r (@resol){
                        if ($r =~ /((\d{3,4})x(\d{3,4}))/){
                            $resolution = $1;
                        }
                    }
                    $common->addVideo({
                        'CHIPSET'    => $chipset,
                        'NAME'       => $name,
                        'MEMORY'     => $memory,
                        'RESOLUTION' => $resolution,
                    });
                }
            }
        }
    }
    else {
        foreach(`lspci`){
            if(/graphics|vga|video/i && /^\S+\s([^:]+):\s*(.+?)(?:\(([^()]+)\))?$/i){
                $common->addVideo({
                'CHIPSET'  => $1,
                'NAME'     => $2,
                });
            }
        }
    }
}

1;
