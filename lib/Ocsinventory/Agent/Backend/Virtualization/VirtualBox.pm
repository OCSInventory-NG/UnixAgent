package Ocsinventory::Agent::Backend::Virtualization::VirtualBox;

use strict;

use XML::Simple;
use File::Glob ':glob';

sub check { 
    my $params = shift;
    my $common = $params->{common};
    return $common->can_run('VirtualBox') and $common->can_run('VBoxManage') 
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $scanhomedirs = $params->{accountinfo}{config}{scanhomedirs};
  
    my $cmd_list_vms = "VBoxManage -nologo list vms";

    my ( $version ) = ( `VBoxManage --version` =~ m/^(\d\.\d).*$/ ) ;
    if ( $version > 2.1 ) {         # detect VirtualBox version 2.2 or higher
        $cmd_list_vms = "VBoxManage -nologo list --long vms";
    }
    
    my $in = 0;
    my $uuid;
    my $mem;
    my $status;
    my $name;
    my $current_user = `printenv SUDO_USER`; # fetches the current user
    chomp ($current_user);
        
    foreach my $line (`sudo -u $current_user $cmd_list_vms`){                 # read only the information on the first paragraph of each vm
        chomp ($line);
        if ($in == 0 and $line =~ m/^Name:\s+(.*)$/) {      # begin
            $name = $1;
            $in = 1; 
        } elsif ($in == 1 ) {
            if ($line =~ m/^UUID:\s+(.*)/) {
                $uuid = $1;
            } elsif ($line =~ m/^Memory size:\s+(.*)/ ) {
                $mem = $1;
            } elsif ($line =~ m/^State:\s+(.*)\(.*/) {
                $status = ( $1 =~ m/off/ ? "off" : $1 );
            } elsif ($line =~ m/^\s*$/) {                        # finish
                $in = 0 ;
                next if $uuid =~ /^N\\A$/ ;   #If no UUID found, it is not a virtualmachine
                $common->addVirtualMachine ({
                    NAME      => $name,
                    VCPU      => 1,
                    UUID      => $uuid,
                    MEMORY    => $mem,
                    STATUS    => $status,
                    SUBSYSTEM => "Oracle xVM VirtualBox",
                    VMTYPE    => "VirtualBox",
                });

                $name = $status = $mem = $uuid = 'N\A';     # useless but need it for security (new version, ...)
            }
        }
    }
    
    if ($in == 1) {     # Anormal situation ! save the current vm information ...
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
    
    # try to found another VMs, not exectute by root
    my @vmRunnings = ();
    my $index = 0 ;
    foreach my $line ( `ps -ef` ) {
        chomp($line);
        if ( $line !~ m/^root/) {
            if ($line =~ m/^.*VirtualBox (.*)$/) {
                my @process = split (/\s*\-\-/, $1);     #separate options
                $name = $uuid = "N/A";
                foreach my $option ( @process ) {
                    #print $option."\n";
                    if ($option =~ m/^comment (.*)/) {
                        $name = $1;
                    } elsif ($option =~ m/^startvm (\S+)/) {
                        $uuid = $1;
                    }
                }
                
                if ($scanhomedirs == 1 ) {    # If I will scan Home directories,
                    $vmRunnings [$index] = $uuid;   # save the no-root running machine
                    $index += 1;
                } else {
                    $common->addVirtualMachine ({  # add in inventory
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
