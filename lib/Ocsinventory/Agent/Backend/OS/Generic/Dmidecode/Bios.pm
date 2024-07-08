package Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Bios;
use strict;

sub run {
    my $params = shift;
    my $common = $params->{common};
  
    # Parsing dmidecode output
    # Using "type 0" section
    my( $SystemSerial , $SystemModel, $SystemManufacturer,
        $SystemVersion, $BiosManufacturer, $BiosVersion,
        $BiosDate, $AssetTag, $MotherboardManufacturer,
        $MotherboardModel, $MotherboardSerial, $Type );
  
    #System DMI
    $SystemManufacturer = `dmidecode -s system-manufacturer`;
    $SystemModel = `dmidecode -s system-product-name`;
    $SystemSerial = `dmidecode -s system-serial-number`;
    $SystemVersion = `dmidecode -s system-version`;
    $AssetTag = `dmidecode -s chassis-asset-tag`;
    $Type = `dmidecode -s chassis-type`;

    #Motherboard DMI
    $MotherboardManufacturer = `dmidecode -s baseboard-manufacturer`;
    $MotherboardModel = `dmidecode -s baseboard-product-name`;
    $MotherboardSerial = `dmidecode -s baseboard-serial-number`;

    #BIOS DMI
    $BiosManufacturer = `dmidecode -s bios-vendor`;
    $BiosVersion = `dmidecode -s bios-version`;
    $BiosDate = `dmidecode -s bios-release-date`;
    
    foreach my $info ( $SystemSerial , $SystemModel, $SystemManufacturer,
        $SystemVersion, $BiosManufacturer, $BiosVersion,
        $BiosDate, $AssetTag, $MotherboardManufacturer,
        $MotherboardModel, $MotherboardSerial, $Type ) {

        # Remove lines starting with #
        $info =~ s/(\s*#.*\n)+//g;
        # Remove error msg 'Invalid entry length (0). DMI table is broken! Stop.'
        $info =~ s/Invalid.*//g;
        # Remove break lines
        $info =~ s/\n//g;
        # Remove whitespaces at start/end
        $info =~ s/^\s+|\s+$//g;
    }

    #System DMI
    if ($SystemModel && $SystemManufacturer && $SystemManufacturer =~ /^LENOVO$/i && $SystemVersion =~ /^(Think|Idea|Yoga|Netfinity|Netvista|Intelli)/i) {
        my $product_name = $SystemVersion;
        $SystemVersion = $SystemModel;
        $SystemModel = $product_name;
    }

    # If serial number is empty, assign mainboard serial (e.g Intel NUC)
    if (!$SystemSerial) {
        $SystemSerial = $MotherboardSerial;
    }

    # Some bioses don't provide a serial number so I check for CPU ID (e.g: server from dedibox.fr)
    my @cpu;
    if (!$SystemSerial || $SystemSerial =~ /^0+$/) {
        @cpu = `dmidecode -t processor`;
        for (@cpu){
            if (/ID:\s*(.*)/i){
                $SystemSerial = $1;
            }
        }
    }
  
    # Writing data
    $common->setBios ({
        ASSETTAG => $AssetTag,
        SMANUFACTURER => $SystemManufacturer,
        SMODEL => $SystemModel,
        SSN => $SystemSerial,
        BMANUFACTURER => $BiosManufacturer,
        BVERSION => $BiosVersion,
        BDATE => $BiosDate,
        MMANUFACTURER => $MotherboardManufacturer,
        MMODEL => $MotherboardModel,
        MSN => $MotherboardSerial,
        TYPE => $Type,
    });
}

1;
