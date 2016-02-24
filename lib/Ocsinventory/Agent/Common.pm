###############################################################################
## OCSINVENTORY-NG
## Copyleft Guillaume PROTET 2010
## Web : http://www.ocsinventory-ng.org
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Common;

use strict;
no strict 'refs';
use warnings;

##################################################################################
#  Ocsinventory::Agent::Common is use to give common methods to other modules   #
##################################################################################

sub new {
  my (undef, $params) = @_;

  my $self = {};

  $self->{logger} = $params->{logger};
  $self->{config} = $params->{config};

  $self->{xmltags} = {};

  bless $self;
}

=item addController()

Add a controller in the inventory.

=cut
sub addController {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION DRIVER NAME MANUFACTURER PCIID PCISLOT TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }
  push @{$xmltags->{CONTROLLERS}},$content;

}

=item addUsb()

Add Usb devices as keyboard, mouse in the inventory.

=cut
sub addUsb {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  #foreach my $key (qw/CAPTION DESCRIPTION INTERFACE MANUFACTURER POINTTYPE TYPE/) {
  foreach my $key (qw/DESCRIPTION INTERFACE MANUFACTURER PROTOCOL TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }
  push @{$xmltags->{INPUTS}},$content;

}
=item addModem()

Add a modem in the inventory.

=cut
sub addModem {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION NAME/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{MODEMS}}, $content;

}

# For compatibiliy
sub addModems {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addModems to addModem()");
   $self->addModem(@_);
}

=item addDrive()

Add a partition in the inventory.

=cut
sub addDrive {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CREATEDATE FREE FILESYSTEM LABEL SERIAL TOTAL TYPE VOLUMN/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{DRIVES}}, $content;

}

# For compatibiliy
sub addDrives {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addDrives to addDrive()");
   $self->addDrive(@_);
}

=item addStorages()

Add a storage system (hard drive, USB key, SAN volume, etc) in the inventory.

=cut
sub addStorages {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION DISKSIZE FIRMWARE MANUFACTURER MODEL NAME SERIALNUMBER SCSI_CHID SCSI_COID SCSI_LUN SCSI_UNID TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{STORAGES}}, $content;
}

# For compatibiliy
sub addStorage {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addStorages to addStorage()");
   $self->addStorage(@_);
}


=item addMemory()

Add a memory module in the inventory.

=cut
sub addMemory {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CAPACITY CAPTION DESCRIPTION ERRORCORRECTIONTYPE MANUFACTURER NUMSLOTS SERIALNUMBER SPEED TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{MEMORIES}}, $content;
}

# For compatibiliy
sub addMemories {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addMemories to addMemory()");
   $self->addMemory(@_);
}

=item addPort()

Add a port module in the inventory.

=cut
sub addPorts{
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CAPTION DESCRIPTION NAME TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{PORTS}}, $content;
}

# For compatibiliy
sub addPort {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addPorts to addPort()");
   $self->addPort(@_);
}

=item addSlot()

Add a slot in the inventory. 

=cut
sub addSlot {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION DESIGNATION NAME STATUS/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{SLOTS}}, $content;
}

# For compatibiliy
sub addSlots {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addSlots to addSlot()");
   $self->addSlot(@_);
}

=item addSoftware()

Register a software in the inventory.

=cut
sub addSoftware {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/COMMENTS FILESIZE FOLDER FROM INSTALLDATE NAME PUBLISHER VERSION/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{SOFTWARES}}, $content;
}

# For compatibiliy
sub addSoftwares {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addSoftwares to addSoftware()");
   $self->addSoftware(@_);
}

=item addMonitor()

Add a monitor (screen) in the inventory.

=cut
sub addMonitor {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/BASE64 CAPTION DESCRIPTION MANUFACTURER SERIAL UUENCODE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{MONITORS}}, $content;
}

# For compatibiliy
sub addMonitors {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addMonitors to addMonitor()");
   $self->addMonitor(@_);
}

=item addVideo()

Add a video card in the inventory.

=cut
sub addVideo {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CHIPSET DRVVERSION MEMORY NAME PCISLOT PCIID RESOLUTION SPEED UUID VBIOS/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{VIDEOS}}, $content;
}

# For compatibiliy
sub addVideos {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addVideos to addVideo()");
   $self->addVideo(@_);
}

=item addSound()

Add a sound card in the inventory.

=cut
sub addSound {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION MANUFACTURER NAME/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{SOUNDS}}, $content;
}

# For compatibiliy
sub addSounds {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addSounds to addSound()");
   $self->addSound(@_);
}

=item addNetwork()

Register a network in the inventory.

=cut
sub addNetwork {
  # TODO IPSUBNET, IPMASK IPADDRESS seem to be missing.
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/BSSID DESCRIPTION DRIVER DUPLEX IPADDRESS IPDHCP IPGATEWAY IPMASK IPSUBNET MACADDR MODE PCISLOT SPEED SSID STATUS TYPE VERSION VIRTUALDEV/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{NETWORKS}}, $content;
}

# For compatibiliy
sub addNetworks {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addNetworks to addNetwork()");
   $self->addNetwork(@_);
}


=item setHardware()

Save global information regarding the machine.

The use of setHardware() to update USERID and PROCESSOR* information is
deprecated, please, use addUser() and addCPU() instead.

=cut
sub setHardware {
  my ($self, $args, $nonDeprecated) = @_; 
  my $xmltags = $self->{xmltags};

  my $logger = $self->{logger};

  foreach my $key (qw/USERID OSVERSION PROCESSORN OSCOMMENTS CHECKSUM
    PROCESSORT NAME PROCESSORS SWAP ETIME TYPE OSNAME IPADDR WORKGROUP
    DESCRIPTION MEMORY UUID DNS LASTLOGGEDUSER
    DATELASTLOGGEDUSER DEFAULTGATEWAY VMSYSTEM/) {

    if (exists $args->{$key}) {
      if ($key eq 'PROCESSORS' && !$nonDeprecated) {
          $logger->debug("PROCESSORN, PROCESSORS and PROCESSORT shouldn't be set directly anymore. Please use addCPU() method instead.");
      }
      if ($key eq 'USERID' && !$nonDeprecated) {
          $logger->debug("USERID shouldn't be set directly anymore. Please use addCPU() method instead.");
      }

      $xmltags->{'HARDWARE'}{$key}[0] = $args->{$key};
    }
  }
}


=item setBios()

Set BIOS information.

=cut
sub setBios {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/SMODEL SMANUFACTURER SSN BDATE BVERSION BMANUFACTURER MMANUFACTURER MSN MMODEL ASSETTAG TYPE/) {

    if (exists $args->{$key}) {
      $xmltags->{'BIOS'}{$key}[0] = $args->{$key};
    }
  }
}

=item addCPU()

Add a CPU in the inventory.

=cut
sub addCPU {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CORES LOGICAL_CPUS CPUARCH CPUSTATUS CURRENT_SPEED DATA_WIDTH HPT L2CACHESIZE MANUFACTURER NBSOCKET SERIALNUMBER SOCKET SPEED TYPE VOLTAGE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{CPUS}}, $content;

  # For the compatibility with HARDWARE/PROCESSOR*
  my $processorn = int @{$xmltags->{CPUS}};
  my $processors = $xmltags->{CPUS}[0]{SPEED}[0];
  my $processort = $xmltags->{CPUS}[0]{TYPE}[0];

  $self->setHardware ({
    PROCESSORN => $processorn,
    PROCESSORS => $processors,
    PROCESSORT => $processort,
  }, 1);

}

=item addUser()

Add an user in the list of logged user.

=cut
sub addUser {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $login = $args->{LOGIN};

  return unless $login;

  # Is the login, already in the XML ?
  foreach my $user (@{$xmltags->{USERS}}) {
      return if $user->{LOGIN}[0] eq $login;
  }

  push @{$xmltags->{USERS}},
  {
      LOGIN => [$login]
  };
  my $userString = $xmltags->{HARDWARE}->{USERID}[0] || "";

  $userString .= '/' if $userString;
  $userString .= $login;

  $self->setHardware ({
    USERID => $userString,
  }, 1);

}

=item addPrinter()

Add a printer in the inventory.

=cut
sub addPrinter {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/DESCRIPTION DRIVER NAME PORT/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{PRINTERS}}, $content;

}

# For compatibiliy
sub addPrinters {
   my $self = shift;
   my $logger = $self->{logger};

   $logger->debug("please rename addPrinters to addPrinter()");
   $self->addPrinter(@_);
}

=item addVirtualMachine()

Add a Virtual Machine in the inventory.

=cut
sub addVirtualMachine {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CORES MEMORY NAME UUID STATUS SUBSYSTEM VMTYPE VCPU VMID/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{VIRTUALMACHINES}}, $content;

}

=item addProcess()

Record a running process in the inventory.

=cut
sub addProcess {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CMD CPUUSAGE MEM PID STARTED TTY USER VIRTUALMEMORY/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{PROCESSES}}, $content;
}


=item addIpDiscoverEntry()

IpDiscover is used to identify network interface on the local network. This
is done on the ARP level.

This function adds a network interface in the inventory.

=cut
sub addIpDiscoverEntry {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $ipaddress = $args->{IPADDRESS};
  my $macaddr = $args->{MACADDR};
  my $name = $args->{NAME};

  if (!$xmltags->{IPDISCOVER}{H}) {
    $xmltags->{IPDISCOVER}{H} = [];
  }

  push @{$xmltags->{IPDISCOVER}{H}}, {
    # If I or M is undef, the server will ingore the host
    I => [$ipaddress?$ipaddress:""],
    M => [$macaddr?$macaddr:""],
    N => [$name?$name:"-"], # '-' is the default value reteurned by ipdiscover
  };
}


=item setAccessLog()

What is that for? :)

=cut
sub setAccessLog {
  my ($self, $args) = @_;

  foreach my $key (qw/USERID LOGDATE/) {

    if (exists $args->{$key}) {
      $self->{xmlroot}{'CONTENT'}{'ACCESSLOG'}{$key}[0] = $args->{$key};
    }
  }
}

=item flushXMlTags()

Clear the content of $common->{xmltags} (to use after adding it in XML)

=cut
sub flushXMLTags {
  my $self= shift;
  $self->{xmltags} = {};
}


### SNMP specifics subroutines ####

sub getSnmpTable {
  my ($self,$snmp_table,$baseoid,$snmp_infos) = @_;

  #$snmp_infos is a hash passed for the SNMP information we want to get
  #It has to be created like this :
  #my $hash = {
  #  INFORMATION => OID,
  #};

  my $results={};  #The final hash which will contain one key per SNMP reference

  for my $oid ( keys %$snmp_table ) {
    if ( $oid =~ /$baseoid\.\d+\.\d+\.(\S+)/ ) {
      my $reference=$1;    #Getting the last digits of the OID separated by a dot

      #Getting information if one the values from $snmp_infos hash is found for the current OID
      for my $value (keys %$snmp_infos) {
        if ($oid =~ /$snmp_infos->{$value}\.$reference/) {
        $results->{$reference}->{$value}= $snmp_table->{$oid}
        }
      }
    }
  }
  return $results;
}


sub setSnmpCommons {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  
  foreach my $key (qw/IPADDR MACADDR SNMPDEVICEID NAME DESCRIPTION CONTACT LOCATION UPTIME DOMAIN TYPE / ) {
     if (exists $args->{$key}) {
        $xmltags->{COMMON}[0]{$key}[0] = $args->{$key};
     }
  }
}

sub setSnmpPrinter {
  my ($self,$args) = @_;
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/NAME SERIALNUMBER COUNTER STATUS ERRORSTATE/ ) {
     if (exists $args->{$key}) {
        $xmltags->{PRINTERS}[0]{$key}[0] = $args->{$key};
     }
  }
}


sub setSnmpSwitchInfos {
  my ($self,$args) = @_;
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/TYPE/) {
     if (exists $args->{$key}) {
        $xmltags->{SWITCHINFOS}[0]{$key}[0] = $args->{$key};
     }
  }
}

sub setSnmpFirewalls {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/SERIALNUMBER SYSTEM/) {
     if (exists $args->{$key}) {
        $xmltags->{FIREWALLS}[0]{$key}[0] = $args->{$key};
     }
  }
}


sub setSnmpLoadBalancer {
  my ($self,$args) = @_; 
  my $xmltags=$self->{xmltags};

  foreach my $key (qw/SERIALNUMBER SYSTEM MANUFACTURER TYPE/ ) {
     if (exists $args->{$key}) {
        $xmltags->{LOADBALANCERS}[0]{$key}[0] = $args->{$key};
     }
  }
}

sub setSnmpBlade {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/SERIALNUMBER SYSTEM/) {
     if (exists $args->{$key}) {
        $xmltags->{BLADES}[0]{$key}[0] = $args->{$key};
     }
  }
}

sub setSnmpComputer {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};

  foreach my $key (qw/SYSTEM/) {
     if (exists $args->{$key}) {
        $xmltags->{COMPUTERS}[0]{$key}[0] = $args->{$key};
     }
  }
}

sub addSnmpPrinterCartridge {
  my ($self,$args) = @_;
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/DESCRIPTION TYPE LEVEL MAXCAPACITY COLOR/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }
  push @{$xmltags->{CARTRIDGES}},$content;

}

sub addSnmpPrinterTray {
  my ($self,$args) = @_;
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/NAME DESCRIPTION LEVEL MAXCAPACITY/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{TRAYS}},$content;

}

sub addSnmpNetwork {
  my ($self,$args) = @_;
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/DESCRIPTION MACADDR DEVICEMACADDR SLOT STATUS SPEED TYPE DEVICEADDRESS DEVICENAME DEVICEPORT DEVICETYPE TYPEMIB IPADDR IPMASK IPGATEWAY IPSUBNET IPDHCP DRIVER VIRTUALDEV/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{NETWORKS}},$content;
}

sub addSnmpCard {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/DESCRIPTION REFERENCE FIRMWARE SOFTWARE REVISION SERIALNUMBER MANUFACTURER TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{CARDS}},$content;

}

sub addSnmpFan {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/DESCRIPTION REFERENCE REVISION SERIALNUMBER MANUFACTURER TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{FANS}},$content;
}

sub addSnmpPowerSupply {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/MANUFACTURER REFERENCE TYPE SERIALNUMBER DESCRIPTION REVISION/ ) {
     if (exists $args->{$key}) {
        $content->{$key}[0]=$args->{$key};
     }
  }

  push @{$xmltags->{POWERSUPPLIES}},$content;
}

sub addSnmpSwitch {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/MANUFACTURER REFERENCE TYPE SOFTVERSION FIRMVERSION SERIALNUMBER REVISION DESCRIPTION/) {
     if (exists $args->{$key}) {
        $content->{$key}[0]=$args->{$key};
     }
  }

  push @{$xmltags->{SWITCHS}},$content;
}

sub addSnmpLocalPrinter {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/NAME/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{LOCALPRINTERS}},$content;

}

sub addSnmpInput {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/DESCRIPTION TYPE/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{INPUTS}},$content;

}


sub addSnmpCPU {
  my ($self,$args) = @_; 
  my $xmltags = $self->{xmltags};
  my $content = {};

  foreach my $key (qw/MANUFACTURER TYPE SPEED/) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key};
     }
  }

  push @{$xmltags->{CPUS}},$content;

}



=item addBatteries()

Add a memory module in the inventory.

=cut
sub addBatteries {
  my ($self, $args) = @_; 
  my $xmltags = $self->{xmltags};

  my $content = {};

  foreach my $key (qw/CHEMISTRY DESIGNCAPACITY DESIGNVOLTAGE LOCATION MANUFACTURER MANUFACTUREDATE MAXERROR NAME OEMSPECIFIC SBDSVERSION SERIALNUMBER /) {
     if (exists $args->{$key}) {
        $content->{$key}[0] = $args->{$key} if $args->{$key};
     }
  }

  push @{$xmltags->{BATTERIES}}, $content;
}

#Subroutine to add 0 in 'Sun like' MAC address if needed
sub padSnmpMacAddress {
  my ($self,$mac) = @_;

  my @splitedAddr = split(':', $mac);

  for (@splitedAddr) {
    unless ($_ =~ /\w{2}/) {
       $_ = sprintf("%02s", $_);
    }
  }

  $mac=join (':', @splitedAddr);
  return $mac;
}


sub cleanXml {
  my ($self,$content) = @_;

  my $logger = $self->{logger};

  my $clean_content;

  # To avoid strange breakage I remove the unprintable characters in the XML
  foreach (split "\n", $content) {
    if (! m/\A(
    [\x09\x0A\x0D\x20-\x7E]            # ASCII
    | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
    |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
    | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
    |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
    |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
    | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
    |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
    )*\z/x) {
      s/[[:cntrl:]]//g;
      $self->{logger}->debug("non utf-8 '".$_."'");
    }

    # Is that a good idea. Intent to drop some nasty char
    # s/[A-z0-9_\-<>\/:\.,#\ \?="'\(\)]//g;
    $clean_content .= $_."\n";
  }

  return $clean_content;
}

#Subroutine to read XML structure (returned by XML::Simple::XMLin) and encode content in utf8.
sub readXml {
  my ($self, $xml, $forcearray) = @_;

  my $logger = $self->{logger};
  my $content = XML::Simple::XMLin($xml, ForceArray => [@{$forcearray}]);

  foreach my $key (keys %$content) {
    if (grep(/^$key$/, @{$forcearray})) {  #Forced array in XML parsing
      $self->parseXmlArray($content->{$key},$forcearray);
    }
    else {  #Not a forced array in XML parsing
       if (ref ($content->{$key}) =~ /^HASH$/ && !keys %{$content->{$key}}) {  # If empty hash from XMLin()
         $content->{$key} = '';
       } else { utf8::encode($content->{$key}) }; 
    }
  }
  return $content;
}

#Subroutine to parse array in XML structure (returned by XML::Simple::XMLin) and encode it in utf8
sub parseXmlArray {
  my ($self,$array,$forcearray) = @_;

  foreach my $hash (@{$array}) {
    foreach my $key (keys %$hash) {
      if ( grep (/^$key$/,@$forcearray)) {  #Forced array in XML parsing
        $self->parseXmlArray($hash->{$key},$forcearray);    
      } else {  #Not a forced array in XML parsing
          if (ref ($hash->{$key}) =~ /^HASH$/ && !keys %{$hash->{$key}}) {  # If empty hash from XMLin()
            $hash->{$key} = ''; 
          } else { utf8::encode($hash->{$key}) };
      }
    }
  }
}


#Subroutine to convert versions to numbers (with icutting or right padding if needed)
# We create it because Perl 5.8 does not include version comparison modules or functions
sub convertVersion {
  my ($self,$version,$length) = @_;

  $version =~ s/\.//g;  #We convert to number
  my $ver_length = length ($version);

  if ($ver_length > $length) {  # We cut the number
    $version = substr $version, 0, $length;
  } elsif ($ver_length < $length) { #We add 0 to the right
   $version = substr($version . (0 x $length), 0, $length);

  }
  return $version;
}

#We create this subroutine because MacOSX system_profiler XML output does not give all
##the neeeded data (for videos and sounds for example)
sub get_sysprofile_devices_names {
  my ($self,$type) = @_;

  return(undef) unless -r '/usr/sbin/system_profiler';

  my $output=`system_profiler $type`;
  my $name;
  my $names=[];

  #Code inspired from Mac::Sysprofile 0.03 from Daniel Muey
  for(split /\n/, $output) {
    next if m/^\s*$/ || m/^\w/;
    if(m/^\s{4}\w/) {
      $name = $_;
      $name =~ s/^\s+//;
      $name =~ s/:.*$//;
      push(@$names,$name);
    }
  } 

  return $names;
}


### Generic shared subroutines #####

sub can_run {
  my $self = shift;
  my $binary = shift;

  my $logger = $self->{logger};

  my $calling_namespace = caller(0);
  chomp(my $binpath=`which $binary 2>/dev/null`);
  return unless -x $binpath;
  $self->{logger}->debug(" - $binary found");
  1;
}

sub can_load {
  my $self = shift;
  my $module = shift;

  my $logger = $self->{logger};

  my $calling_namespace = caller(0);
  eval "package $calling_namespace; use $module;";
  return if $@;
  $self->{logger}->debug(" - $module loaded");
  1;
}


sub can_read {
  my $self = shift;
  my $file = shift;

  my $logger = $self->{logger};

  return unless -r $file;
  $self->{logger}->debug(" - $file can be read");
  1;
}

sub runcmd {
  my $self = shift;
  my $cmd = shift;

  my $logger = $self->{logger};

  return unless $cmd;

  # $self->{logger}->debug(" - run $cmd");
  return `$cmd`;
}


#### Old subroutines from the former Common.pm used by Download.pm #######

sub get_path{
   my $self = shift;
   my $binary = shift;
   my $path;

   my @bin_directories  = qw {   /usr/local/sbin/ /sbin/ /usr/sbin/ /bin/ /usr/bin/
            /usr/local/bin/ /etc/ocsinventory-client/};

   print "\n=> retrieving $binary...\n" if $::debug;
   for(@bin_directories){
      $path = $_.$binary,last if -x $_.$binary;
   }

   #For debbuging purposes
   if($path){
      print "=> $binary is at $path\n\n" if $::debug;
   }else{
      print "$binary not found (Maybe it is not installed ?) - Some functionnalities may lack !!\n\n";
   }

   return $path;
}


sub already_in_array {
   my $self = shift;
   my $lookfor = shift;
   my @array   = @_;
   foreach (@array){
      if($lookfor eq $_){
         return 1 ;
      }
   }
   return 0;
}


1;
