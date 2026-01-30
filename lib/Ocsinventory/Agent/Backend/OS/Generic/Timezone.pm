package Ocsinventory::Agent::Backend::OS::Generic::Timezone;

use strict;
use warnings;
use Data::Dumper;

use English qw(-no_match_vars);

use POSIX;
use Time::Local;

sub run {

    my $params = shift;
    my $logger = $params->{logger};
    my $common = $params->{common};

    my @t = localtime(time);

    my $utc_offset_seconds= timegm(@t) - timelocal(@t);
    my $utc_offset_seconds_abs = abs($utc_offset_seconds);

    my $offset_sign = $utc_offset_seconds < 0 ? '-': '+';

    my $tz_offset = strftime($offset_sign."\%H\%M",gmtime($utc_offset_seconds_abs));

    my $tz_name = '';

    $logger->debug("Using DateTime::TimeZone to get the timezone name");
    $tz_name = strftime("%Z",localtime());

    $common->addTimezone({
          NAME => $tz_name,
	  OFFSET => $tz_offset,
    });

}

1;
