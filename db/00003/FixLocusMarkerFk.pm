package FixLocusMarkerFk;

use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub init_patch {

    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is ':" .  $name . "\n\n";
    my $description = 'phenome.locus_marker.marker_id has a FK to sgn.marker, instead of deprecated_markers';
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

    $self->dbh->do( <<EOF );
    alter table phenome.locus_marker drop CONSTRAINT locus_marker_marker_id_fkey ;
    alter table phenome.locus_marker ADD  CONSTRAINT locus_marker_marker_id_fkey  foreign key (marker_id) references sgn.marker (marker_id) ;

EOF

    print "You're done!\n";
}


####
1; #
####

