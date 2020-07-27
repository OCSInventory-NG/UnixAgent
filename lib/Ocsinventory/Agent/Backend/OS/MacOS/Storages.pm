package Ocsinventory::Agent::Backend::OS::MacOS::Storages;

use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return $common->can_load('Mac::SysProfile');
    return $common->can_run('system_profiler');
}

sub getManufacturer {

    my $model = shift;
    $model =~ s/APPLE HDD //;
    if ($model =~ /(maxtor|western|sony|compaq|hewlett packard|ibm|seagate|toshiba|fujitsu|lg|samsung|nec|transcend|matshita|pioneer|hitachi)/i) {
        return ucfirst(lc($1));
    } elsif ($model =~ /^APPLE SSD/) {
        return "Apple";
    } elsif ($model =~ /^HP/) {
        return "Hewlett Packard";
    } elsif ($model =~ /^WDC/) {
        return "Western Digital";
    } elsif ($model =~ /^ST/) {
        return "Seagate";
    } elsif ($model =~ /^HDi|^HT/ or $model =~ /^IC/ or $model =~ /^HU/) {
       return "Hitachi";
    }
}

sub run {

    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};
  
    my $devices = {};

    my $profile = Mac::SysProfile->new();
  
    # Get SATA Drives
    my $sata = $profile->gettype('SPSerialATADataType');

    if ( ref($sata) eq 'ARRAY') {
    
      foreach my $storage ( @$sata ) {
        next unless ( ref($storage) eq 'HASH' );
  
        my $type;
        if ( $storage->{'_name'} =~ /DVD/i || $storage->{'_name'} =~ /CD/i ) {
          $type = 'CD-ROM Drive';
        } elsif ($storage->{'_name'} =~ /SSD/i || $storage->{'spsata_medium_type'} =~ /Solid State/i) {
          $type = 'Disk SSD drive';
        }else {
          $type = 'Disk drive';
        }
  
        my $size = $storage->{'size'};
        if ($size =~ /GB/) {
          $size =~ s/ GB//;
          $size *= 1024;
        }
        if ($size =~ /TB/) {
          $size =~ s/ TB//;
          $size *= 1048576;
        }
  
        my $manufacturer = getManufacturer($storage->{'_name'});
  
        my $model = $storage->{'device_model'};
        $model =~ s/\s*$manufacturer\s*//i;

        my $description = "Status: $storage->{'smart_status'}";
        if ($storage->{'spsata_trim_support'} =~ /Yes/ ) { $description .= " - Trim: $storage->{'spsata_trim_support'}";}
  
        $devices->{$storage->{'_name'}} = {
          NAME => $storage->{'bsd_name'},
          SERIALNUMBER => $storage->{'device_serial'},
          DISKSIZE => $size,
          FIRMWARE => $storage->{'device_revision'},
          MANUFACTURER => $manufacturer,
          DESCRIPTION => $description,
          TYPE => $type,
          MODEL => $model
        };
      }
    } 
  
    # Get PATA Drives
    my $scsi = $profile->gettype('SPParallelSCSIDataType');
    
    if ( ref($scsi) eq 'ARRAY') {
      foreach my $storage ( @$scsi ) {
        next unless ( ref($storage) eq 'HASH' );
        
        my $type;
        if ( $storage->{'_name'} =~ /DVD/i || $storage->{'_name'} =~ /CD/i ) {
         $type = 'CD-ROM Drive';
        }
        else {
          $type = 'Disk drive';
        }
        
        my $size = $storage->{'size'};
        if ($size =~ /GB/) {
          $size =~ s/ GB//;
          $size *= 1024;
        }
        if ($size =~ /TB/) {
          $size =~ s/ TB//;
          $size *= 1048576;
        }
  
        my $manufacturer = getManufacturer($storage->{'_name'});
        
        my $model = $storage->{'device_model'};
        $model =~ s/\s*$manufacturer\s*//i;
        
        my $description = "Status: $storage->{'smart_status'}";
        if ($storage->{'spsata_trim_support'} =~ /Yes/ ) { $description .= " - Trim: $storage->{'spsata_trim_support'}";}
  
        $devices->{$storage->{'_name'}} = {
          NAME => $storage->{'_name'},
          SERIAL => $storage->{'device_serial'},
          DISKSIZE => $size,
          FIRMWARE => $storage->{'device_revision'},
          MANUFACTURER => $manufacturer,
          DESCRIPTION => $description,
          MODEL => $model
        };
      
      }
    }

    # Get PATA drives
    my $pata = $profile->gettype('SPParallelATADataType');
  
    if ( ref($pata) eq 'ARRAY') {
        foreach my $storage ( @$pata ) {
             next unless ( ref($storage) eq 'HASH' );
           
             my $type;
             if ( $storage->{'_name'} =~ /DVD/i || $storage->{'_name'} =~ /CD/i ) {
                 $type = 'CD-ROM Drive';
             } else {
                 $type = 'Disk drive';
             }
           
             my $manufacturer = getManufacturer($storage->{'_name'});
           
             my $model = $storage->{'device_model'};
           
             my $size = $storage->{'size'};
             if ($size =~ /GB/) {
                 $size =~ s/ GB//;
                 $size *= 1024;
             }
             if ($size =~ /TB/) {
                 $size =~ s/ TB//;
                 $size *= 1048576;
             }
     
             my $description = "";
           
             $devices->{$storage->{'_name'}} = {
                 NAME => $storage->{'bsd_name'},
                 SERIALNUMBER=> $storage->{'device_serial'},
                 DISKSIZE => $size,
                 FIRMWARE => $storage->{'device_revision'},
                 MANUFACTURER => $manufacturer,
                 DESCRIPTION => $description,
                 TYPE => $type,
                 MODEL => $model
             };
        }
    }

    # Get NVMe Drives
    my $nve = $profile->gettype('SPNVMeDataType');

    if ( ref($nve) eq 'ARRAY') {
        foreach my $storage ( @$nve ) {
            next unless ( ref($storage) eq 'HASH' );

            my $type = 'Disk NVMe Drive';

            my $size = $storage->{'size'};
            if ($size =~ /GB/) {
                $size =~ s/ GB//;
                $size *= 1024;
            }
            if ($size =~ /TB/) {
                $size =~ s/ TB//;
                $size *= 1048576;
            }

            my $manufacturer = getManufacturer($storage->{'_name'});

            my $model = $storage->{'device_model'};
            $model =~ s/\s*$manufacturer\s*//i;

            my $description = "";

            $devices->{$storage->{'_name'}} = {
                NAME => $storage->{'bsd_name'},
                SERIALNUMBER=> $storage->{'device_serial'},
                DISKSIZE => $size,
                FIRMWARE => $storage->{'device_revision'},
                MANUFACTURER => $manufacturer,
                DESCRIPTION => $description,
                TYPE => $type,
                MODEL => $model
            };
        }
    }
  
    foreach my $device ( keys %$devices ) {
        $common->addStorages($devices->{$device});
    }
}

1;
