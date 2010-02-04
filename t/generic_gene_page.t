#!/usr/bin/env perl
use strict;
use warnings;
use English;

use Test::More tests => 2;
use Test::Exception;

use CXGN::DB::Connection;
use CXGN::Phenome::GenericGenePage;

throws_ok {
    CXGN::Phenome::GenericGenePage->new( -id => 428 )
} qr/-dbh/, 'dies without dbh param';

my $dbh = CXGN::DB::Connection->new;
my $ggp = CXGN::Phenome::GenericGenePage->new( -id => 428, -dbh => $dbh );

can_ok( $ggp, 'render_xml' );

my $xml = $ggp->render_xml;

like( $xml, qr/dwarf/i, 'xml looks ok');
