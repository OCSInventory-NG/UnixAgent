package Ocsinventory::Agent::Backend::OS::Linux::Bluetooth::Bluetooth;

use warnings;
use strict;
use Data::Dumper;

sub check {
   my $params = shift;
   my $common = $params->{common}; 
   return 1 if ($common->can_run("hciconfig") || $common->can_run("bluetoothctl"));
}

# ── Bluetooth device type mapping ────────────────────────────────────────────
my %DEVICE_CLASSES = (
   '0x000000' => 'Miscellaneous',
   '0x000100' => 'Computer',
   '0x000200' => 'Phone',
   '0x000300' => 'Network Access Point',
   '0x000400' => 'Audio/Video',
   '0x000500' => 'Peripheral',
   '0x000600' => 'Imaging',
   '0x000700' => 'Wearable',
   '0x000800' => 'Toy',
   '0x000900' => 'Health',
   '0x001F00' => 'Uncategorized',
);
  
# ── Peripheral sub-types (CoD bits 6-7) ──────────────────────────────────────
my %PERIPHERAL_TYPES = (
   '0x0540' => 'Keyboard',
   '0x0580' => 'Pointing Device',
   '0x05C0' => 'Keyboard + Pointing Device',
   '0x0504' => 'Joystick',
   '0x0508' => 'Gamepad',
);

sub run {
   my $params = shift;
   my $common = $params->{common};
   my $logger = $params->{logger};

   $logger->debug("Bluetooth module starting");

   my @controllers = _getControllers();
   my @devices     = _getDevices();

   unless (@controllers || @devices) {
       $logger->debug("Bluetooth module: nothing found, skipping.");
       return;
   }

   # ── Push controllers ──────────────────────────────────────────────────────
   for my $ctrl (@controllers) {
       $common->addController({
           NAME         => $ctrl->{name}         // 'N/A',
           MANUFACTURER => $ctrl->{manufacturer}  // 'N/A',
           TYPE         => 'Bluetooth Controller',
           VERSION      => $ctrl->{version}       // 'N/A',
           CAPTION      => $ctrl->{caption}       // 'Bluetooth Adapter',
           DESCRIPTION  => $ctrl->{description}   // '',
           ADDRESS      => $ctrl->{address}       // '',
           FIRMWARE     => $ctrl->{firmware}      // '',
           STATUS       => $ctrl->{status}        // 'Unknown',
       });
   }

   # ── Push devices ──────────────────────────────────────────────────────────
   for my $dev (@devices) {
       $common->addBluetoothDevice({
           NAME         => $dev->{name}         // 'Unknown Device',
           ADDRESS      => $dev->{address}      // '',
           TYPE         => $dev->{type}         // 'Unknown',
           MANUFACTURER => $dev->{manufacturer} // 'Unknown',
           CLASS        => $dev->{class}        // '',
           CONNECTED    => $dev->{connected}    // 'No',
           PAIRED       => $dev->{paired}       // 'No',
           TRUSTED      => $dev->{trusted}      // 'No',
           RSSI         => $dev->{rssi}         // '',
           SERVICES     => $dev->{services}     // '',
           FIRMWARE     => $dev->{firmware}     // '',
           BLOCKED      => $dev->{blocked}      // 'No',
       });
   }

   $logger->debug( 
      sprintf( "Bluetooth: %d controller(s) %d device(s) reported.", 
         scalar @controllers, scalar @devices )
   );
}

sub _getControllers {
    my ($self) = @_;
    my @controllers;

    # ── Try hciconfig first ───────────────────────────────────────────────────
    my $output = `hciconfig -a 2>/dev/null`;
    push @controllers, _parseHciconfig($output) if $output;

    # ── Fallback: parse /sys/class/bluetooth ─────────────────────────────────
    unless (@controllers) {
        push @controllers, _parseSysBluetooth();
    }

    return @controllers;
}

sub _parseHciconfig {
    my ($output) = @_;
    my @controllers;
    my $current;

    for my $line ( split /\n/, $output ) {
        # New adapter block: "hci0:   Type: Primary  Bus: USB"
        if ( $line =~ /^(hci\d+):\s+Type:\s+(\S+)\s+Bus:\s+(\S+)/ ) {
            push @controllers, $current if $current;
            $current = {
                name        => $1,
                description => "Bluetooth $2 adapter on $3 bus",
                caption     => "Bluetooth Adapter ($1)",
            };
        }
        next unless $current;

        if ( $line =~ /BD Address:\s+([0-9A-Fa-f:]{17})/ ) {
            $current->{address} = uc($1);
        }
        if ( $line =~ /Manufacturer:\s+(.+?)\s+\((\d+)\)/ ) {
            $current->{manufacturer} = $1;
        }
        if ( $line =~ /HCI Version:\s+(.+?)\s+/ ) {
            $current->{version} = $1;
        }
        if ( $line =~ /Firmware:\s+(.+)/ ) {
            $current->{firmware} = $1;
        }
        if ( $line =~ /\bUP\b/ ) {
            $current->{status} = 'UP';
        }
        elsif ( $line =~ /\bDOWN\b/ ) {
            $current->{status} = 'DOWN';
        }
    }
    push @controllers, $current if $current;
    return @controllers;
}

sub _parseSysBluetooth {
    my ($self) = @_;
    my @controllers;
    my $sysPath = '/sys/class/bluetooth';

    return () unless -d $sysPath;

    opendir( my $dh, $sysPath ) or return ();
    my @ifaces = grep { !/^\./ } readdir($dh);
    closedir($dh);

    for my $iface (@ifaces) {
        my $base = "$sysPath/$iface";
        my $addr = _readSysFile("$base/address") // '';
        my $name = _readSysFile("$base/name")    // $iface;
        push @controllers, {
            name        => $iface,
            address     => uc($addr),
            caption     => $name,
            description => "Bluetooth adapter ($iface)",
            status      => -e "$base/powered" ? 'UP' : 'Unknown',
        };
    }
    return @controllers;
}

sub _getDevices {
    my ($self) = @_;
    my @devices;

    # ── Primary: bluetoothctl ─────────────────────────────────────────────────
    my $devList = `echo -e "devices\nquit" | bluetoothctl 2>/dev/null`;
    my @macs = ( $devList =~ /Device\s+([0-9A-Fa-f:]{17})/g );

    for my $mac (@macs) {
        my $info = `echo -e 'info $mac\nquit' | bluetoothctl 2>/dev/null`;
        my $dev = _parseBluetoothctlInfo($info);
        $dev->{address} = uc($mac) unless $dev->{address};
        push @devices, $dev;
    }

    # ── Fallback: hcitool scan ────────────────────────────────────────────────
    unless (@devices) {
       my $scan = `timeout hcitool scan 2>/dev/null`;
       for my $line ( split /\n/, $scan ) {
           if ( $line =~ /^\s+([0-9A-Fa-f:]{17})\s+(.+)/ ) {
                push @devices, { address => uc($1), name => $2 };
           }
       }
    }
    # ── Enrich from /var/lib/bluetooth ───────────────────────────────────────
    _enrichFromVarLib( \@devices );

    return @devices;
}

sub _parseBluetoothctlInfo {
    my ($output) = @_;
    my %dev;

    for my $line ( split /\n/, $output ) {
        $dev{name}        = $1 if $line =~ /Name:\s+(.+)/;
        $dev{address}     = uc($1) if $line =~ /Address:\s+([0-9A-Fa-f:]{17})/;
        $dev{manufacturer}= $1 if $line =~ /Vendor:\s+(.+)/;
        $dev{class}       = $1 if $line =~ /Class:\s+(0x[0-9A-Fa-f]+)/;
        $dev{rssi}        = $1 if $line =~ /RSSI:\s+(-?\d+)/;
        $dev{firmware}    = $1 if $line =~ /Version:\s+(.+)/;
        $dev{connected}   = $1 =~ /yes/i ? 'Yes' : 'No'
                                if $line =~ /Connected:\s+(\S+)/;
        $dev{paired}      = $1 =~ /yes/i ? 'Yes' : 'No'
                                if $line =~ /Paired:\s+(\S+)/;
        $dev{trusted}     = $1 =~ /yes/i ? 'Yes' : 'No'
                                if $line =~ /Trusted:\s+(\S+)/;
        $dev{blocked}     = $1 =~ /yes/i ? 'Yes' : 'No'
                                if $line =~ /Blocked:\s+(\S+)/;

        # Collect UUIDs / services
        if ( $line =~ /UUID:\s+(.+?)\s+\(/ ) {
            $dev{services} //= '';
            $dev{services} .= "$1; ";
        }
    }

    # Resolve device type from class
    if ( $dev{class} ) {
        $dev{type} = _resolveDeviceClass( $dev{class} );
    }

    return \%dev;
}

sub _enrichFromVarLib {
    my ($devices) = @_;
    my $basePath = '/var/lib/bluetooth';
    return unless -d $basePath;

    # Build a lookup of already-found MACs
    my %known = map { $_->{address} => $_ } @$devices;

    opendir( my $adh, $basePath ) or return;
    my @adapters = grep { !/^\./ } readdir($adh);
    closedir($adh);

    for my $adapter (@adapters) {
        my $adapterPath = "$basePath/$adapter";
        next unless -d $adapterPath;

        opendir( my $ddh, $adapterPath ) or next;
        my @devDirs = grep { /^[0-9A-Fa-f:]{17}$/ } readdir($ddh);
        closedir($ddh);

        for my $mac (@devDirs) {
            my $infoFile = "$adapterPath/$mac/info";
            next unless -f $infoFile;

            open( my $fh, '<', $infoFile ) or next;
            my %info;
            while (<$fh>) {
                chomp;
                $info{Name}    = $1 if /^Name=(.+)/;
                $info{Class}   = $1 if /^Class=(.+)/;
                $info{Trusted} = $1 if /^Trusted=(.+)/;
                $info{Paired}  = 1  if /\[LinkKey\]/;
            }
            close($fh);

            my $normMac = uc($mac);
            $normMac =~ s/-/:/g;

            if ( $known{$normMac} ) {
                # Enrich existing entry
                $known{$normMac}{name}    //= $info{Name};
                $known{$normMac}{class}   //= $info{Class};
                $known{$normMac}{trusted} //= $info{Trusted} ? 'Yes' : 'No';
                $known{$normMac}{paired}  //= $info{Paired}  ? 'Yes' : 'No';
            }
            else {
                # New device discovered via filesystem
                push @$devices, {
                    address => $normMac,
                    name    => $info{Name}   // 'Unknown',
                    class   => $info{Class}  // '',
                    trusted => $info{Trusted} ? 'Yes' : 'No',
                    paired  => $info{Paired}  ? 'Yes' : 'No',
                    type    => _resolveDeviceClass( $info{Class} // '' ),
                };
            }
        }
    }
}

sub _resolveDeviceClass {
    my ($classHex) = @_;
    return 'Unknown' unless $classHex && $classHex =~ /^0x/i;

    my $val = hex($classHex);
    my $major = $val & 0x001F00;
    my $majorHex = sprintf( '0x%06X', $major );

    return $DEVICE_CLASSES{$majorHex} // 'Unknown';
}

sub _readSysFile {
    my ($path) = @_;
    return undef unless -r $path;
    open( my $fh, '<', $path ) or return undef;
    my $val = <$fh>;
    close($fh);
    chomp $val if defined $val;
    return $val;
}

1;
