use utf8;
package CXGN::Phenome::Schema::Individual;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::Individual

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<individual>

=cut

__PACKAGE__->table("individual");

=head1 ACCESSORS

=head2 individual_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'individual_individual_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 population_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 common_name_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 accession_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "individual_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "individual_individual_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "population_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "common_name_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "accession_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</individual_id>

=back

=cut

__PACKAGE__->set_primary_key("individual_id");

=head1 RELATIONS

=head2 germplasms

Type: has_many

Related object: L<CXGN::Phenome::Schema::Germplasm>

=cut

__PACKAGE__->has_many(
  "germplasms",
  "CXGN::Phenome::Schema::Germplasm",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_alias

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualAlias>

=cut

__PACKAGE__->has_many(
  "individual_alias",
  "CXGN::Phenome::Schema::IndividualAlias",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_alleles

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualAllele>

=cut

__PACKAGE__->has_many(
  "individual_alleles",
  "CXGN::Phenome::Schema::IndividualAllele",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_dbxrefs

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualDbxref>

=cut

__PACKAGE__->has_many(
  "individual_dbxrefs",
  "CXGN::Phenome::Schema::IndividualDbxref",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualHistory>

=cut

__PACKAGE__->has_many(
  "individual_histories",
  "CXGN::Phenome::Schema::IndividualHistory",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_images

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualImage>

=cut

__PACKAGE__->has_many(
  "individual_images",
  "CXGN::Phenome::Schema::IndividualImage",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 individual_loci

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualLocus>

=cut

__PACKAGE__->has_many(
  "individual_loci",
  "CXGN::Phenome::Schema::IndividualLocus",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 phenome_genotypes

Type: has_many

Related object: L<CXGN::Phenome::Schema::PhenomeGenotype>

=cut

__PACKAGE__->has_many(
  "phenome_genotypes",
  "CXGN::Phenome::Schema::PhenomeGenotype",
  { "foreign.individual_id" => "self.individual_id" },
  undef,
);

=head2 population_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Population>

=cut

__PACKAGE__->belongs_to(
  "population_id",
  "CXGN::Phenome::Schema::Population",
  { population_id => "population_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g2UfFCRM+vu/o8Nugk6g8A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
