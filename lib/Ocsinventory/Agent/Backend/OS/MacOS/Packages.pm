package Ocsinventory::Agent::Backend::OS::MacOS::Packages;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};

    return unless $common->can_load("Mac::SysProfile");
    # Do not run an package inventory if there is the --nosoftware parameter
    return if ($params->{config}->{nosoftware});

    1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $profile = Mac::SysProfile->new();
    my $data = $profile->gettype('SPApplicationsDataType'); # might need to check version of darwin

    return unless($data && ref($data) eq 'ARRAY');

    # for each app, normalize the information, then add it to the inventory stack
    foreach my $app (@$data){
        #my $a = $apps->{$app};
        my $path = $app->{'path'} ? $app->{'path'} : 'unknown';

        #Exlude from /System/Library/xxx : you can save 150 entries
        if ($path =~ /^\/System\/Library\//) {next;}
        if ($path =~ /\/System\/Library\// and $path =~ /^\/Volumes\//) {next;}
        
        #Exlude from xxx/Library/Printers/xxx : you can save 10 entries because a printer is an app
        if ($path =~ /\/Library\/Printers\//) {next;}

        my $kind = $app->{'runtime_environment'} ? $app->{'runtime_environment'} : 'UNKNOWN';
        my $store = $app->{'app_store'} ? $app->{'app_store'} : 'no';
        my $comments = 'AppStore: '.$store.' - Type: '.$kind.' ';
        my $bits = $app->{'has64BitIntelCode'} ? $app->{'has64BitIntelCode'} : 'unknown';
        if ($bits eq 'yes') {$bits = '64';} else {$bits = '32';}
        
        $common->addSoftware({
            'NAME'        => $app->{'_name'},
            'VERSION'     => $app->{'version'} || 'unknown',
            'COMMENTS'    => $comments,
            'PUBLISHER'   => $app->{'info'} || 'unknown',
            'INSTALLDATE' => $app->{'lastModified'},
            'FOLDER'      => $path,
            'BITSWIDTH'   => $bits,
        });
    }
}

1;
