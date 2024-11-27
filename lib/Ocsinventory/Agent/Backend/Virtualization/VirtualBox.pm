package Ocsinventory::Agent::Backend::Virtualization::VirtualBox;

use strict;

use XML::Simple;
use File::Glob ':glob';
use utf8;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    return $common->can_run('VirtualBox') and $common->can_run('VBoxManage') 
}

sub run {

    # VBoxManage can crash if some VM infos contains accented characters
    my $locale = "C";
    open(my $localeFile, '<', "/etc/default/locale") or print("Could not open /etc/default/locale: $!");
    while (my $line = <$localeFile>){
        if ($line =~ m/^LANG=(.*)/) {
            $locale = $1;
            last;
        }
    }
    close($localeFile);
    $ENV{LANG}=$locale;
    $ENV{LC_ALL}=$locale;

    my $params = shift;
    my $common = $params->{common};
    my $scanhomedirs = $params->{accountinfo}{config}{scanhomedirs};
  
    my $cmd_list_vms = "VBoxManage -nologo list vms";

    my ( $version ) = ( `VBoxManage --version` =~ m/^(\d\.\d).*$/ ) ;
    # Detect VirtualBox version 2.2 or higher
    if ( $version > 2.1 ) {
        $cmd_list_vms = "VBoxManage -nologo list --long vms";
    }
    
    my $in = 0;
    my $uuid;
    my $mem;
    my $status;
    my $name;
    my $cpus;

    # Inventory process is running by cron/system service so there is no SUDO_USER
    # We use local users who are in "vboxusers" local group
    my $vboxusers_line = `getent group vboxusers`;
    chomp($vboxusers_line);
    my @vboxusers = split(/,/, (split(/:/, $vboxusers_line))[-1]);
    foreach my $vboxuser (@vboxusers) {

        # Read only the information on the first paragraph of each vm
        foreach my $line (`sudo -u $vboxuser $cmd_list_vms`){
            chomp ($line);
            # Although some lines starts with "Name:", it is not VM name
            if ($in == 0 and $line =~ m/^Name:\s+([^:,]*)$/) {
                $name = $1;
                # Some VM names can contains accented characters
                utf8::decode($name);
                $in = 1; 
            } elsif ($in == 1 ) {
                if ($line =~ m/^UUID:\s+(.*)/) {
                    $uuid = $1;
                } elsif ($line =~ m/^Memory size:\s+(.*)/ ) {
                    $mem = $1;
                } elsif ($line =~ m/^Number of CPUs:\s+(.*)/) {
                    $cpus = $1;
                } elsif ($line =~ m/^State:\s+(.*)\(.*/) {
                    $status = ( $1 =~ m/off/ ? "off" : $1 );
                # Empty line does not mean it is end of current VM infos. Real VM infos last line starts with "Configured memory ballon:"    
                } elsif ($line =~ m/^Configured memory balloon:\s+.*/) {
                    $in = 0 ;
                    # If no UUID found, it is not a virtualmachine
                    next if $uuid =~ /^N\\A$/ ;
                    $common->addVirtualMachine ({
                        NAME      => $name,
                        VCPU      => $cpus,
                        UUID      => $uuid,
                        MEMORY    => $mem,
                        STATUS    => $status,
                        SUBSYSTEM => "Oracle xVM VirtualBox",
                        VMTYPE    => "VirtualBox",
                    });

                    # Useless but need it for security (new version, ...)
                    $name = $status = $mem = $uuid = 'N\A';
                }
            }
        }
        
        # Anormal situation ! save the current vm information ...
        if ($in == 1) {
            $common->addVirtualMachine ({
                NAME      => $name,
                VCPU      => 1,
                UUID      => $uuid,
                MEMORY    => $mem,
                STATUS    => $status,
                SUBSYSTEM => "Oracle xVM VirtualBox",
                VMTYPE    => "VirtualBox",
            });
        }

    }
    
    # try to found another VMs, not exectute by root
    my @vmRunnings = ();
    my $index = 0 ;
    foreach my $line ( `ps -ef` ) {
        chomp($line);
        if ( $line !~ m/^root/) {
            if ($line =~ m/^.*VirtualBox (.*)$/) {
                # Separate options
                my @process = split (/\s*\-\-/, $1);
                $name = $uuid = "N/A";
                foreach my $option ( @process ) {
                    if ($option =~ m/^comment (.*)/) {
                        $name = $1;
                    } elsif ($option =~ m/^startvm (\S+)/) {
                        $uuid = $1;
                    }
                }
                
                # If I will scan Home directories,
                if ($scanhomedirs == 1 ) {
                    # save the no-root running machine
                    $vmRunnings [$index] = $uuid;
                    $index += 1;
                } else {
                    # Add in inventory
                    $common->addVirtualMachine ({
                        NAME      => $name,
                        VCPU      => 1,
                        UUID      => $uuid,
                        STATUS    => "running",
                        SUBSYSTEM => "Oracle xVM VirtualBox",
                        VMTYPE    => "VirtualBox",
                    });
                }
            }
        }
    }

    # If home directories scan is authorized
    if ($scanhomedirs == 1 ) {
        # Read every Machines Xml File of every user
        foreach my $xmlMachine (bsd_glob("/home/*/.VirtualBox/Machines/*/*.xml")) {
            chomp($xmlMachine);
            # Open config file ...
            my $configFile = new XML::Simple;
            my $data = $configFile->XMLin($xmlMachine);
            # ... and read it
            if ($data->{Machine}->{uuid}) {
                my $uuid = $data->{Machine}->{uuid};
                $uuid =~ s/^{?(.{36})}?$/$1/;
                my $status = "off";
                foreach my $vmRun (@vmRunnings) {
                    if ($uuid eq $vmRun) {
                        $status = "running";
                    }
                }
          
                $common->addVirtualMachine ({
                    NAME      => $data->{Machine}->{name},
                    VCPU      => $data->{Machine}->{Hardware}->{CPU}->{count},
                    UUID      => $uuid,
                    MEMORY    => $data->{Machine}->{Hardware}->{Memory}->{RAMSize},
                    STATUS    => $status,
                    SUBSYSTEM => "Oracle xVM VirtualBox",
                    VMTYPE    => "VirtualBox",
                });
            }
        }
      
        foreach my $xmlVirtualBox (bsd_glob("/home/*/.VirtualBox/VirtualBox.xml")) {
            chomp($xmlVirtualBox);
            # Open config file ...
            my $configFile = new XML::Simple;
            my $data = $configFile->XMLin($xmlVirtualBox);
            # ... and read it
            my $defaultMachineFolder = $data->{Global}->{SystemProperties}->{defaultMachineFolder};
            if ( $defaultMachineFolder != 0 and $defaultMachineFolder != "Machines" and $defaultMachineFolder =~ /^\/home\/S+\/.VirtualBox\/Machines$/ ) {
                foreach my $xmlMachine (bsd_glob($defaultMachineFolder."/*/*.xml")) {
                    my $configFile = new XML::Simple;
                    my $data = $configFile->XMLin($xmlVirtualBox);

                    if ( $data->{Machine} != 0 and $data->{Machine}->{uuid} != 0 ) {
                        my $uuid = $data->{Machine}->{uuid};
                        $uuid =~ s/^{?(.{36})}?$/$1/;
                        my $status = "off";
                        foreach my $vmRun (@vmRunnings) {
                            if ($uuid eq $vmRun) {
                                $status = "running";
                            }
                        }

                        $common->addVirtualMachine ({
                            NAME      => $data->{Machine}->{name},
                            VCPU      => $data->{Machine}->{Hardware}->{CPU}->{count},
                            UUID      => $uuid,
                            MEMORY    => $data->{Machine}->{Hardware}->{Memory}->{RAMSize},
                            STATUS    => $status,
                            SUBSYSTEM => "Oracle xVM VirtualBox",
                            VMTYPE    => "VirtualBox",
                        });
                    }
                }
            }
        }
    }
}

1;
