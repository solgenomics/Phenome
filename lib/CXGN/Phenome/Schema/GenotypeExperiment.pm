package CXGN::Phenome::Schema::GenotypeExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::GenotypeExperiment

=cut

__PACKAGE__->table("genotype_experiment");

=head1 ACCESSORS

=head2 genotype_experiment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotype_experiment_genotype_experiment_id_seq'

=head2 experiment_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 reference_map_id

  data_type: 'bigint'
  is_nullable: 1

=head2 background_accession_id

  data_type: 'bigint'
  is_nullable: 1

=head2 preferred

  data_type: 'boolean'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_nullable: 1

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "genotype_experiment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotype_experiment_genotype_experiment_id_seq",
  },
  "experiment_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "reference_map_id",
  { data_type => "bigint", is_nullable => 1 },
  "background_accession_id",
  { data_type => "bigint", is_nullable => 1 },
  "preferred",
  { data_type => "boolean", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("genotype_experiment_id");

=head1 RELATIONS

=head2 genotypes

Type: has_many

Related object: L<CXGN::Phenome::Schema::Genotype>

=cut

__PACKAGE__->has_many(
  "genotypes",
  "CXGN::Phenome::Schema::Genotype",
  {
    "foreign.genotype_experiment_id" => "self.genotype_experiment_id",
  },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:te5D/DO/pbItqa50+po+Aw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
