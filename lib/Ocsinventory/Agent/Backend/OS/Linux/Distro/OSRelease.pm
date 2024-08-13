package Ocsinventory::Agent::Backend::OS::Linux::Distro::OSRelease;

use warnings;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_read("/etc/os-release");
}

sub run {

    my $name;
    my $version     = "";
    my $description = "";

    my $params = shift;
    my $common = $params->{common};
    my $first_non_commented_line;

    open my $v, '<', "/etc/os-release" or warn;
    foreach (<$v>) {
        next if /^#/;
        $first_non_commented_line //= $_; # Capture the first non-commented line
        $name        = $1 if (/^NAME="?([^"]+)"?/);
        $version     = $1 if (/^VERSION_ID="?([^"]+)"?/);
        $description = $1 if (/^PRETTY_NAME="?([^"]+)"?/);
    }
    close $v;

    $name = $first_non_commented_line unless defined $name;

    chomp($name)        if defined $name;
    chomp($version)     if defined $version;
    chomp($description) if defined $description;

    # Debian version number is set in/etc/debian_version file
    if ( -r "/etc/debian_version" ) {
        if ( `uname -v` =~ /debian/i ) {
            open my $v, '<', "/etc/debian_version" or warn;
            foreach (<$v>) {
                $version = $1 if ( $_ =~ /^(\d+.*)/ );
            }
            close $v;
            chomp($version) if defined $version;
        }
    }

    # CentOS exact version number is set in /etc/centos-release file
    my @centOsRedHatfiles = ( "/etc/centos-release", "/etc/redhat-release" );
    foreach my $file (@centOsRedHatfiles) {
        if ( -r $file ) {
            open my $v, '<', $file or warn;
            foreach my $line (<$v>) {
                $version     = $1 if ( $line =~ /(\d+\.\d+)./g );
                $description = $line;
            }
            close $v;
            chomp($version)     if defined $version;
            chomp($description) if defined $description;
            last;    # Exit the loop after finding the first matching file
        }
    }

    if ( !defined $version || $version eq "" ) {

   # if no version found try to retrieve it on the name with format x.x or x.x.x
        $version = $1 if ( $name =~ /^(\d+.*)/ );
    }

    my $fullosname = $name;
    $fullosname .= " $version" if $version;
    $fullosname =~ s/^\s+|\s+$//g;

    $common->setHardware(
        {
            OSNAME     => $fullosname,
            OSVERSION  => $version,
            OSCOMMENTS => $description,
        }
    );

}

1;