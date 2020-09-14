package Ocsinventory::Agent::Backend::OS::Linux::Bios;

use vars qw($runMeIfTheseChecksFailed);
$runMeIfTheseChecksFailed = ["Ocsinventory::Agent::Backend::OS::Generic::Dmidecode::Bios"];

use strict;
use warnings;

sub check {

    return -d "/sys/class/dmi/id";

}

sub run {

    my $params = shift;
    my $common = $params->{common};

    my $chassis_types = [
        "",
        "Other",
        "Unknown",
        "Desktop",
        "Low Profile Desktop",
        "Pizza Box",
        "Mini Tower",
        "Tower",
        "Portable",
        "Laptop",
        "Notebook",
        "Hand Held",
        "Docking Station",
        "All in One",
        "Sub Notebook",
        "Space-Saving",
        "Lunch Box",
        "Main Server Chassis",
        "Expansion Chassis",
        "Sub Chassis",
        "Bus Expansion Chassis",
        "Peripheral CHassis",
        "RAID Chassis",
        "Rack Mount Chassis",
        "Sealed-case PC",
        "Multi-System",
        "CompactPCI",
        "AdvancedTCA",
        "Blade",
        "Blade Enclosing",
        "Tablet",
        "Convertible",
        "Detachable",
        "IoT Gateway",
        "Embedded PC",
        "Mini PC",
        "Stick PC",
    ];

    my $bios = {};
    my $hardware = {};

    my %bios_map = qw(
         BMANUFACTURER  bios_vendor
         BDATE          bios_date
         BVERSION       bios_version
         ASSETTAG       chassis_asset_tag
         SMODEL         product_name
         SMANUFATCURER  sys_vendor
         SSN            product_serial
         MMODEL         board_name
         MMANUFACTURER  board_vendor
         MSN            board_serial
    );
    
    foreach my $key (keys(%bios_map)){
        my $value = _dmi_info($bios_map{$key});
        next unless defined($value);
        $bios->{$key}=$value;
    }

    # Set VirtualBox VM S/N to UUID if found serial is '0'
    my $uuid = _dmi_info('product_uuid');
    if ($uuid && $bios->{MMODEL} && $bios->{MMODEL} eq 'VirtualBox' && $bios->{SSN} eq "0" && $bios->{MSN} eq "0" ){
        $bios->{SSN}=$uuid;
    }

    $hardware->{UUID}=$uuid if $uuid;

    my $chassis_type = _dmi_info('chassis_type');
    if ($chassis_type && $chassis_types->[$chassis_type]) {
        $bios->{TYPE} = $chassis_types->[$chassis_type];
    }

    $common->setBios($bios);
    $common->setHardware($hardware);

}

1;

sub _dmi_info {
    my ($info) = @_;
    my $class = '/sys/class/dmi/id/'.$info;
    return if -d $class;
    return unless -e $class;
    open (my $fh, $class) or warn;
    my $classinfo=<$fh>;
    close ($fh);
    chomp($classinfo);
    return $classinfo;
}

