package DropNdUnique;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Drop the unique constraint from nd_experiment_phenotype and nd_experiment_genotype, and add adding an (experiment_id,phenotype_id) unique  C';
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
    alter table nd_experiment_phenotype  DROP CONSTRAINT nd_experiment_phenotype_nd_experiment_id_key;

    alter table nd_experiment_phenotype ADD CONSTRAINT nd_experiment_phenotype_c1 UNIQUE (nd_experiment_id, phenotype_id);

    alter table nd_experiment_genotype  DROP CONSTRAINT nd_experiment_genotype_nd_experiment_id_key;

    alter table nd_experiment_genotype ADD CONSTRAINT nd_experiment_genotype_c1 UNIQUE (nd_experiment_id, genotype_id);

EOSQL

    print "You're done!\n";
}


return 1;
