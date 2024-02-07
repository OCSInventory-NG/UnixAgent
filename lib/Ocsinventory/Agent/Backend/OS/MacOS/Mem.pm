package Ocsinventory::Agent::Backend::OS::MacOS::Mem;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};

    return(undef) unless -r '/usr/sbin/system_profiler'; # check perms
    return (undef) unless $common->can_load("Mac::SysProfile");
    return 1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $PhysicalMemory;

    # create the profile object and return undef unless we get something back
    my $profile = Mac::SysProfile->new();
    my $data = $profile->gettype('SPMemoryDataType');
    return(undef) unless(ref($data) eq 'ARRAY');

    # Workaround for MacOSX 10.5.7
    #if ($h->{'Memory Slots'}) {
    #  $h = $h->{'Memory Slots'};
    #}

    my $size;
    my $speed;
    my $type;
    my $description;
    my $serialnumber;
    my $status;
    my $numslots;


    foreach my $memory (@$data){
        # macos 14
        if ($memory->{'SPMemoryDataType'}) {
            $size = $memory->{'SPMemoryDataType'};
            if ($size =~ /GB$/) {
                $size =~ s/GB$//;
                $size *= 1024;
            } elsif ($size =~ /MB$/) {
                $size =~ s/MB$//;
            }

            $speed = $memory->{'dimm_speed'};
            $type = $memory->{'dimm_type'};
            $description = $memory->{'dimm_manufacturer'};
            $serialnumber = $memory->{'dimm_serial_number'};
            $status = $memory->{'dimm_status'};
        } else {
            next unless $memory->{'_name'} =~ /^BANK|SODIMM|DIMM/;
        }

        # if special handling did not work, we try the old way
        if (!defined($size)) {
            # tare out the slot number
            $numslots = $memory->{'_name'};
            # memory in 10.5
            if($numslots =~ /^BANK (\d)\/DIMM\d/){
                $numslots = $1;
            }
            # 10.4
            if($numslots =~ /^SODIMM(\d)\/.*$/){
                $numslots = $1;
            }
            # 10.4 PPC
            if($numslots =~ /^DIMM(\d)\/.*$/){
                $numslots = $1;
            }

            # 10.7
            if ($numslots =~ /^DIMM (\d)/) {
                $numslots = $1;
            }

            $size = $memory->{'dimm_size'};

            $description = $memory->{'dimm_part_number'};

            if ($description !~ /empty/ && $description =~ s/^0x//) {
                # dimm_part_number is an hex string, convert it to ascii
                $description =~ s/^0x//;
            # Trim filling "00" from part number, which causes invalid XML down the line.
            $description =~ s/00//g;
                $description = pack "H*", $description;
                $description =~ s/\s+$//;
                # New macs might have some specific characters, perform a regex to fix it
                $description =~ s/(?!-)[[:punct:]]//g;
            }

            # if system_profiler lables the size in gigs, we need to trim it down to megs so it's displayed properly
            if($size =~ /GB$/){
                    $size =~ s/GB$//;
                    $size *= 1024;
            }

            $speed = $memory->{'dimm_speed'};
            $type = $memory->{'dimm_type'};
            $serialnumber = $memory->{'dimm_serial_number'};
            $status = 'Status: '.$memory->{'dimm_status'};
        }

        $common->addMemory({
            'CAPACITY'      => $size,
            'SPEED'         => $speed,
            'TYPE'          => $type,
            'SERIALNUMBER'  => $serialnumber,
            'DESCRIPTION'   => $description,
            'NUMSLOTS'      => $numslots,
            'CAPTION'       => $status,
        });
    }

    # Send total memory size to inventory object
    my $sysctl_memsize=`sysctl -n hw.memsize`;
    $common->setHardware({
        MEMORY =>  $sysctl_memsize / 1024 / 1024,
    });
}

1;