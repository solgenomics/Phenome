package LoadChadoProject;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Add missing locus_id indexes to phenome schema.';
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
create index locus_history_locus_id on phenome.locus_history(locus_id);
create index locus_pub_ranking_locus_id on phenome.locus_pub_ranking(locus_id);
create index allele_locus_id on phenome.allele(locus_id);
create index phenome.locus_alias_locus_id on phenome.locus_alias(locus_id);
create index locus_alias_locus_id on phenome.locus_alias(locus_id);
create index locus2locus_locus_id on phenome.locus2locus(locus_id);
create index locus2locus_locus_id on phenome.locus2locus(
create index locus2locus_subject_id on phenome.locus2locus(subject_id);
create index locus2locus_object_id on phenome.locus2locus(object_id);
create index individual_locus_locus_id on phenome.individual_locus(locus_id);
create index locus_image_locus_id on phenome.locus_image(locus_id);
EOSQL

    print "You're done!\n";
}


return 1;
