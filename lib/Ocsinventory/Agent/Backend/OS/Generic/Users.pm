package Ocsinventory::Agent::Backend::OS::Generic::Users;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};

    if (($common->can_read("/etc/passwd") && $common->can_read("/etc/group"))) {
        return 1;
    } else {
        return 0;
    }
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};

    my %users;

    # Logged on users
    if ($common->can_run("who")) {
        for (`who`){
            my $user = $1 if /^(\S+)./;
            $common->addUser ({ LOGIN => $user });
        }
    } else { 
        $logger->debug("who command not found");
    }

    # Local users
    foreach my $user (_getLocalUsers()) {
        push @{$users{$user->{GID}}}, $user->{LOGIN};
	    #delete $user->{GID};

        $common->addLocalUser({
            LOGIN   => $user->{LOGIN},
            ID_USER => $user->{ID_USER},
            GID     => $user->{GID},
            NAME    => $user->{NAME},
            HOME    => $user->{HOME},
            SHELL   => $user->{SHELL}
        });
    }

    # Local groups with members
    foreach my $group (_getLocalGroups()) {
        push @{$group->{MEMBER}}, @{$users{$group->{ID_GROUP}}} if $users{$group->{ID_GROUP}};
        my $group_member = join ',', @{$group->{MEMBER}};

        $common->addLocalGroup({
            ID_GROUP    => $group->{ID_GROUP},
            NAME        => $group->{NAME},
            MEMBER      => $group_member
        });
    }
}

sub _getLocalUsers{

     open(my $fh, '<:encoding(UTF-8)', "/etc/passwd") or warn;
     my @userinfo=<$fh>;
     close($fh);

     my @users;
    
     foreach my $line (@userinfo){
         
         next if $line =~ /^#/;
         next if $line =~ /^[+-]/; # old format for external inclusion
         chomp $line;
         my ($login, undef, $uid, $gid, $gecos, $home, $shell) = split(/:/, $line);

         push @users, {
             LOGIN      => $login,
             ID_USER    => $uid,
             GID        => $gid,
             NAME       => $gecos,
             HOME       => $home,
             SHELL      => $shell,
         };
     }

     return @users;

}

sub _getLocalGroups {

     open(my $fh, '<:encoding(UTF-8)', "/etc/group") or warn;
     my @groupinfo=<$fh>;
     close($fh);

     my @groups;

     foreach my $line (@groupinfo){
         next if $line =~ /^#/;
         chomp $line;
         my ($name, undef, $gid, $members) = split(/:/, $line);
         
         my @members = split(/,/, $members);   
         push @groups, {
             ID_GROUP   => $gid,
             NAME       => $name,
             MEMBER     => \@members,
         };
     }

     return @groups;

}

1;
