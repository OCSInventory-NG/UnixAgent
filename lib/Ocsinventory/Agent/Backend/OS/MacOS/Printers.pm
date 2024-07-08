package Ocsinventory::Agent::Backend::OS::MacOS::Printers;
use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return(undef) unless -r '/usr/sbin/system_profiler';
    return(undef) unless $common->can_load("Mac::SysProfile");
    return 1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $profile = Mac::SysProfile->new();
    my $data = $profile->gettype('SPPrintersDataType');
    return(undef) unless(ref($data) eq 'ARRAY');

    my $status = "";
    my $description = "";
    my $shared = "";
    my @shared = "";
    my $oslevel = `sw_vers -productVersion`;
    if ($oslevel =~ /10\.[3-6]\./) {
        $shared = `awk \'/Info / {gsub("Info ",""); printf \$0">"}; /Shared/ {print \$NF}\' /etc/cups/printers.conf 2>/dev/null | grep -i yes`;
        @shared = split(/\n/,$shared);
    }

    foreach my $printer (@$data){
        next if ($printer->{'_name'} =~ /^The\sprinters\slist\sis\sempty\.(.*)$/);
        $description = "Status: $printer->{'status'}";
        next if ($description =~ /^Status:\s$/);
        next if ($description =~ /^Status:\sno_info_found$/);
      
        if ($printer->{'default'} eq "Yes") { $description .= " - Default printer"; }

        if ($oslevel =~ /10\.[3-6]\./) {
           foreach my $printShared (@shared) {
               my ($thisPrinter,$isShared) = split(/>/,$printShared);
               if ($printer->{'_name'} eq $thisPrinter) { $description .= " - Shared: yes"; }
           }
        } else {
           if ($printer->{'shared'} eq "Yes") { $description .= " - Shared: yes"; }
        }

        $common->addPrinter({
            NAME        => $printer->{'_name'},
            DRIVER      => $printer->{'ppd'},
            PORT        => $printer->{'uri'},
            DESCRIPTION => $description,
        });
    }

}
1;
