#!/usr/bin/env perl


=head1 NAME

AddItagLocusField.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

Patch for adding a 'locus' field in the locus and locus_history tables
and populate it with the ITAG locus identifiers as stored currently in locus_alias

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddItagLocusField ;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
Patch for adding a 'locus' field in the locus and locus_history tables
and populate it with the ITAG locus identifiers as stored currently in locus_alias


sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";
    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";
    try {
        #set the searchpath
        $self->dbh->do('set search_path to phenome, public');
        $self->dbh->do('ALTER TABLE phenome.locus ADD COLUMN locus varchar(24) DEFAULT null');
        $self->dbh->do('ALTER TABLE phenome.locus_history ADD COLUMN locus varchar(24) DEFAULT null');
        my $q = "SELECT locus_id, alias FROM phenome.locus_alias where alias ilike 'solyc%' ";
        my $sth = $self->dbh->prepare($q);
        $sth->execute();
        print "Loading ITAG locus names.... \n";
        while ( my $hashref = $sth->fetchrow_hashref ) {
            my $locus_id   = $hashref->{locus_id};
            my $itag_locus = $hashref->{alias};
            if ($locus_id && $itag_locus) {
                $self->dbh->do("UPDATE phenome.locus SET locus = '". $itag_locus . "' WHERE locus_id = $locus_id") ;
                print "Loaded locus $itag_locus for locus_id $locus_id \n";
            } else { no warnings 'uninitialized'; warn "NULL VALUE FOUND! locus_id = $locus_id, alias = $itag_locus \n" ; }

        }
        if ($self->trial) {
            print "Trial mode! Rolling back transaction\n\n";
            $self->dbh->rollback;
        }
        print "Data committed! \n";
    } catch {
        $self->dbh->rollback;
        die "Load failed! " . $_ . "\n" ;
    };
}

return 1;
