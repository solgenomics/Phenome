#!/usr/bin/env perl


=head1 NAME

 AddStockLinks.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a patch for adding stock_id column to tables migrated to chado's stock schem (accession, population, individual)

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddStockLinks;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';


sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Adding stock_id FK to accession , population , individual';
    my @previous_requested_patches = (); #ADD HERE

    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);

}

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";

    my @tables = ( 
	qw /
sgn.accession
phenome.population
phenome.individual
/ );
    $self->dbh->do(<<EOSQL);

SET SEARCH_PATH  TO public;
--do your SQL here

    ALTER TABLE sgn.accession ADD COLUMN stock_id INTEGER;
    ALTER TABLE phenome.population ADD COLUMN stock_id INTEGER;
     ALTER TABLE phenome.individual ADD COLUMN stock_id INTEGER;


EOSQL

print "You're done!\n";
}


return 1;
