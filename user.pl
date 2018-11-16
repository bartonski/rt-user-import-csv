#! /usr/bin/perl

use Modern::Perl;
use Getopt::Long;
use Text::CSV_XS;
use List::Util qw();
use List::MoreUtils qw(mesh);
use Data::Dumper;
#use RT;
use RT::User;
use RT::Interface::CLI qw(GetCurrentUser loc);
use RT::CustomFields;

my ($file, $log);

GetOptions(
    "file=s" => \$file
);


# Load the config file
RT::LoadConfig();

# adjust logging to the screen according to options
RT->Config->Set( LogToSTDERR => $log ) if $log;

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

#Get the current user all loaded
my $CurrentUser = GetCurrentUser();

unless ( $CurrentUser->Id ) {
    print loc("No RT user found. Please consult your RT administrator.") . "\n";
    exit(1);
}

sub is_header_ok {

    #  Header is OK if all of its values are in the following list...  
    #
    #  'id'.
    #  'Name'.
    #  'Password'.
    #  'AuthToken'.
    #  'Comments'.
    #  'Signature'.
    #  'EmailAddress'.
    #  'FreeformContactInfo'.
    #  'Organization'.
    #  'RealName'.
    #  'NickName'.
    #  'Lang'.
    #  'Gecos'.
    #  'HomePhone'.
    #  'WorkPhone'.
    #  'MobilePhone'.
    #  'PagerPhone'.
    #  'Address1'.
    #  'Address2'.
    #  'City'.
    #  'State'.
    #  'Zip'.
    #  'Country'.
    #  'Timezone'.

    # ... or if it's a custom field.

    my $header = shift;

    my @userfields = qw (
        Name         Password            AuthToken    Comments  Signature
        EmailAddress FreeformContactInfo Organization RealName  NickName
        Lang         Gecos               HomePhone    WorkPhone MobilePhone
        PagerPhone   Address1            Address2     City      State
        Zip          Country             Timezone
    );

    my $accepted_fields = {
        map { $_ => 1 } @userfields 
    };

    $accepted_fields->{id} = 1;

    my $return_value = 1;

    foreach my $header_field ( @$header ) {
        $return_value ||= defined $accepted_fields->{$header_field};
        # TODO should log a warning message if a header isn't in the accepted fields.
    }

    return $return_value;
}

my $CustomFields = RT::CustomFields->new( $CurrentUser );
$CustomFields->UnLimit;
$CustomFields->LimitToLookupType( 'RT::User' );
$CustomFields->GotoFirstItem;

while ( my $CustomField = $CustomFields->Next ) {
    say  "Custom field ... " .  $CustomField->{values}->{name};
}


my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $file or die "Could not open '$file': $!";

my $header = $csv->getline( $fh );
die( "Header contains bad field names." ) unless is_header_ok( $header );

while (my $row = $csv->getline ($fh)) {
    # TODO check to see if we have more entries in
    # $row than in $header. If so, truncate $row, and warn.
    my $userdata = { mesh @$header, @$row };
    
}

close $fh;

