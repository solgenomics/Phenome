package CXGN::Phenome::Schema::Population;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Population

=cut

__PACKAGE__->table("population");

=head1 ACCESSORS

=head2 population_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'population_population_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 person_id

  data_type: 'integer'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 background_accession_id

  data_type: 'bigint'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 cross_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 female_parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 male_parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 recurrent_parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 donor_parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 web_uploaded

  data_type: 'boolean'
  is_nullable: 1

=head2 common_name_id

  data_type: 'integer'
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "population_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "population_population_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "person_id",
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "background_accession_id",
  { data_type => "bigint", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "cross_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "female_parent_id",
  { data_type => "integer", is_nullable => 1 },
  "male_parent_id",
  { data_type => "integer", is_nullable => 1 },
  "recurrent_parent_id",
  { data_type => "integer", is_nullable => 1 },
  "donor_parent_id",
  { data_type => "integer", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "web_uploaded",
  { data_type => "boolean", is_nullable => 1 },
  "common_name_id",
  { data_type => "integer", is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("population_id");
__PACKAGE__->add_unique_constraint("population_name_key", ["name"]);

=head1 RELATIONS

=head2 individuals

Type: has_many

Related object: L<CXGN::Phenome::Schema::Individual>

=cut

__PACKAGE__->has_many(
  "individuals",
  "CXGN::Phenome::Schema::Individual",
  { "foreign.population_id" => "self.population_id" },
  {},
);

=head2 is_publics

Type: has_many

Related object: L<CXGN::Phenome::Schema::IsPublic>

=cut

__PACKAGE__->has_many(
  "is_publics",
  "CXGN::Phenome::Schema::IsPublic",
  { "foreign.population_id" => "self.population_id" },
  {},
);

=head2 cross_type_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::CrossType>

=cut

__PACKAGE__->belongs_to(
  "cross_type_id",
  "CXGN::Phenome::Schema::CrossType",
  { cross_type_id => "cross_type_id" },
);

=head2 population_dbxrefs

Type: has_many

Related object: L<CXGN::Phenome::Schema::PopulationDbxref>

=cut

__PACKAGE__->has_many(
  "population_dbxrefs",
  "CXGN::Phenome::Schema::PopulationDbxref",
  { "foreign.population_id" => "self.population_id" },
  {},
);

=head2 user_trait_units

Type: has_many

Related object: L<CXGN::Phenome::Schema::UserTraitUnit>

=cut

__PACKAGE__->has_many(
  "user_trait_units",
  "CXGN::Phenome::Schema::UserTraitUnit",
  { "foreign.population_id" => "self.population_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3mxUL/553UQW3ihsMhY2Wg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
