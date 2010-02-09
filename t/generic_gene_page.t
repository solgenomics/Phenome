#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use CXGN::DB::Connection;
use CXGN::Phenome::GenericGenePage;

$SIG{__DIE__} = \&Carp::confess;

throws_ok {
    CXGN::Phenome::GenericGenePage->new( -id => 428 )
} qr/-dbh/, 'dies without dbh param';


my $dbh = CXGN::DB::Connection->new;
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
