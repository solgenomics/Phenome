use utf8;
package CXGN::Phenome::Schema::PhenomeGenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::PhenomeGenotype

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenome_genotype>

=cut

__PACKAGE__->table("phenome_genotype");

=head1 ACCESSORS

=head2 phenome_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.genotype_genotype_id_seq'

=head2 individual_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 experiment_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 reference_map_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 background_accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 preferred

  data_type: 'boolean'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
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

=head2 genotype_experiment_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "phenome_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.genotype_genotype_id_seq",
  },
  "individual_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "experiment_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "reference_map_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "background_accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "preferred",
  { data_type => "boolean", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "genotype_experiment_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phenome_genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("phenome_genotype_id");

=head1 RELATIONS

=head2 genotype_experiment_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::GenotypeExperiment>

=cut

__PACKAGE__->belongs_to(
  "genotype_experiment_id",
  "CXGN::Phenome::Schema::GenotypeExperiment",
  { genotype_experiment_id => "genotype_experiment_id" },
);

=head2 genotype_regions

Type: has_many

Related object: L<CXGN::Phenome::Schema::GenotypeRegion>

=cut

__PACKAGE__->has_many(
  "genotype_regions",
  "CXGN::Phenome::Schema::GenotypeRegion",
  { "foreign.phenome_genotype_id" => "self.phenome_genotype_id" },
  undef,
);

=head2 individual_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Individual>

=cut

__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);

=head2 polymorphic_fragments

Type: has_many

Related object: L<CXGN::Phenome::Schema::PolymorphicFragment>

=cut

__PACKAGE__->has_many(
  "polymorphic_fragments",
  "CXGN::Phenome::Schema::PolymorphicFragment",
  { "foreign.phenome_genotype_id" => "self.phenome_genotype_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S8foNXth7vBf5w2fB4IpFA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
