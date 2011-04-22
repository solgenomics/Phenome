package CXGN::Phenome::Schema::Genotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Genotype

=cut

__PACKAGE__->table("genotype");

=head1 ACCESSORS

=head2 genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotype_genotype_id_seq'

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

=head2 genotype_experiment_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotype_genotype_id_seq",
  },
  "individual_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
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
  "genotype_experiment_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("genotype_id");

=head1 RELATIONS

=head2 genotype_experiment_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::GenotypeExperiment>

=cut

__PACKAGE__->belongs_to(
  "genotype_experiment_id",
  "CXGN::Phenome::Schema::GenotypeExperiment",
  { "genotype_experiment_id" => "genotype_experiment_id" },
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

=head2 genotype_regions

Type: has_many

Related object: L<CXGN::Phenome::Schema::GenotypeRegion>

=cut

__PACKAGE__->has_many(
  "genotype_regions",
  "CXGN::Phenome::Schema::GenotypeRegion",
  { "foreign.genotype_id" => "self.genotype_id" },
  {},
);

=head2 polymorphic_fragments

Type: has_many

Related object: L<CXGN::Phenome::Schema::PolymorphicFragment>

=cut

__PACKAGE__->has_many(
  "polymorphic_fragments",
  "CXGN::Phenome::Schema::PolymorphicFragment",
  { "foreign.genotype_id" => "self.genotype_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xhURpp4dlJdLIAfy/5nKaQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
