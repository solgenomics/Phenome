#!/usr/bin/perl
use strict;
use warnings;

use lib '../sgn/t/lib';
use SGN::Test::WWW::Mechanize;
use Test::More tests => 4;
use Test::Exception;

use CXGN::Phenome::GenericGenePage;

$SIG{__DIE__} = \&Carp::confess;

throws_ok {
    CXGN::Phenome::GenericGenePage->new( -id => 428 )
} qr/-dbh/, 'dies without dbh param';

my $m = SGN::Test::WWW::Mechanize->new();

my $dbh = $m->context->dbc->dbh;

my $ggp = CXGN::Phenome::GenericGenePage
    ->new( -id => 428,
	   -dbh => $dbh,
	 );

test_xml( $ggp->render_xml );

sub test_xml {
    my $x = shift;
    like( $x, qr/dwarf/, 'result looks OK');
    like( $x, qr/<gene/, 'result looks OK');
    like( $x, qr/<data_provider>/, 'result looks OK');
}

#$dbh->disconnect(42);
