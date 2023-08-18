package Ocsinventory::Agent::Backend::OS::Generic::Packaging::Deb;

use strict;
use warnings;
use File::Basename;
use File::stat;


sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("dpkg") }

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};
    my $size;
    my $key;
    my $value;
    my %statinfo;
    my @infos;

    # List of files from which installation date will be extracted
    my @listfile=glob('"/var/lib/dpkg/info/*.list"');

    foreach my $file_list (@listfile){
        my $stat=stat($file_list);
        my ($year,$month,$day,$hour,$min,$sec)=(localtime($stat->mtime))[5,4,3,2,1,0];
        $value=sprintf "%02d/%02d/%02d %02d:%02d:%02d",($year+1900),($month+1),$day,$hour,$min,$sec;
        $key=fileparse($file_list, ".list");
        $key =~ s/(\s+):.+/$1/;
        $statinfo{$key}=$value;
    }
  
    # Use binary:Package to see all packages (amd64,deb) with dpkg > 1162
    my $ver=`dpkg --list dpkg | tail -n 1 | cut -d" " -f14`;
    $ver=~chomp($ver);
    my $vers=$common->convertVersion($ver,4);

    if ($vers > 1162 ){
        @infos=`dpkg-query --show --showformat='\${binary:Package}---\${Architecture}---\${Version}---\${Installed-Size}---\${Status}---\${Homepage}---\${Description}\n'`;
    } else {
        @infos=`dpkg-query --show --showformat='\${Package}---\${Architecture}---\${Version}---\${Installed-Size}---\${Status}---\${Homepage}---\${Description}\n'`;
    }

    my @manual_IM = `apt-mark showmanual`;
    my @auto_IM = `apt-mark showauto`;
    my $installationMethod;

    my @updates = `apt list --upgradable 2>/dev/null`;
    my $name;
    my $type;
    my $lastUpdate;
    my $updateType;

    foreach my $line (@infos) {
        next if $line =~ /^ /;
        chomp $line;
        my @deb=split("---",$line);
        if ($deb[4] && $deb[4] !~ / installed/) {
            $logger->debug("Skipping $deb[0] package as not installed, status='$deb[4]'");
            next;
        }
        foreach my $package (@manual_IM)
        {
            chomp $package;
            if ($package eq $deb[0])
            {
                $installationMethod = "Manual";
                last;
            }
        }
        foreach my $package (@auto_IM)
        {
            chomp $package;
            if ($package eq $deb[0])
            {
                $installationMethod = "Automatic";
                last;
            }
        }
        foreach my $package (@updates)
        {
            $lastUpdate = "";
            $updateType = "";
            if ($package =~ /(?<package>\S+)?\/(?<type>\S+) (?<update_version>\S+) (?<architecture>\S+) \[.+?: (?<current_version>\S+)?\]/)
            {
                $name = $1;
                if ($name eq $deb[0])
                {
                    $lastUpdate = $3;
                    $type = $2;

                    if ($type =~ /security/)
                    {
                        $updateType = "Security";
                    }
                    if ($type =~ /updates/)
                    {
                        $updateType = "Updates";
                    }
                    if ($type =~ /security/)
                    {
                        if ($type =~ /updates/)
                        {
                            $updateType = "Security and updates";
                        }
                    }
                    last;
                }
            }
        }
        $key=$deb[0];
        if (exists $statinfo{$key}) {
            $common->addSoftware ({
                'NAME'          => $deb[0],
                'ARCHITECTURE'  => $deb[1],
                'VERSION'       => $deb[2],
                'LASTUPDATE'    => $lastUpdate,
                'UPDATETYPE'    => $updateType,
                'FILESIZE'      => ( $deb[3] || 0 ) * 1024,
                'PUBLISHER'     => $deb[5],
                'INSTALLDATE'   => $statinfo{$key},
                'INSTALLMETHOD' => $installationMethod,
                'COMMENTS'      => $deb[6],
                'FROM'          => 'deb'
            });
        }
    }
}

1;
