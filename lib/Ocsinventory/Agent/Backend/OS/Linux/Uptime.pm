package Ocsinventory::Agent::Backend::OS::Linux::Uptime;
use strict;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_read("/proc/uptime") 
}

sub run {
    my $params = shift;
    my $common = $params->{common};
  
    # Uptime
    open UPTIME, "/proc/uptime";
    my $uptime = <UPTIME>;
    $uptime =~ s/^(.+)\s+.+/$1/;
    close UPTIME;

    # Convert uptime 
    my $uptime_converted = uptime_conversion($uptime);   
    
    chomp(my $DeviceType =`uname -m`);
    #  TODO$h->{'CONTENT'}{'HARDWARE'}{'DESCRIPTION'} = [ "$DeviceType/$uptime" ];
    $common->setHardware({ DESCRIPTION => "$DeviceType/$uptime_converted" });
 
}

sub uptime_conversion {
    my ($uptime) = @_;

    # Calculate current time
    my $current_time = time();

    # Calculate the time when the system was booted
    my $boot_time = $current_time - $uptime;

    # Convert boot time to human-readable format
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($boot_time);
    $year += 1900;
    $mon += 1;
    $sec += 1;

    # Format the date and time
    my $uptime_formated = sprintf("%02d-%02d-%04d %02d:%02d:%02d", $mday, $mon, $year, $hour, $min, $sec);

    return $uptime_formated;
}

1
