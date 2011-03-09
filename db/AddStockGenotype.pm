#!/usr/bin/env perl


=head1 NAME

 AddStockGenotype.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a patch for adding stock_id column to tables migrated to chado's stock schem (genotype)

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddStockGenotype;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';


sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Adding stock_id FK to phenome.genotype table';
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


    $self->dbh->do(<<EOSQL);

SET SEARCH_PATH  TO phenome;
--do your SQL here

     ALTER TABLE phenome.genotype ADD COLUMN stock_id INTEGER;

    UPDATE genotype SET stock_id  = individual.stock_id FROM individual WHERE genotype.individual_id = individual.individual_id ;


EOSQL

print "You're done!\n";
}


return 1;
