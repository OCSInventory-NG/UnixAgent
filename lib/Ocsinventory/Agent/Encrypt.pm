package Ocsinventory::Agent::Encrypt;

use MIME::Base64;

sub getClearText {
    my ($encodedpass) = @_;

    return decode_base64($encodedpass);
}

1;