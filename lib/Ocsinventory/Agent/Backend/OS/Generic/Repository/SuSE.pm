package Ocsinventory::Agent::Backend::OS::Generic::Repository::SuSE;

use strict;
use warnings;
use Data::Dumper;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("zypper");
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my @repository=`LANG=C zypper lr -Ed 2>/dev/null`;

    for (my $i=0;$i<=$#repository;$i++){
         my $line=$repository[$i];
         next if ($line =~ /^#/);
         next if ($line =~ /^-/);
         my ($num,$alias,$name,$enabled,$gpg,$refresh,$priority,$type,$url)=split('\|',$line);
         $url =~ s/\s+//g;
         $name =~ s/^\s+//;
         $name =~ s/\s+$//;
         $common->addRepo({
             BASEURL => $url,
             NAME => $name,
         });
    }
}

1;
