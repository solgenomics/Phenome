package CXGN::Phenome::Schema::Allele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Allele

=cut

__PACKAGE__->table("allele");

=head1 ACCESSORS

=head2 allele_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'allele_allele_id_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 allele_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 allele_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mode_of_inheritance

  data_type: 'varchar'
  is_nullable: 1
  size: 18

=head2 allele_synonym

  data_type: 'character varying[]'
  is_nullable: 1
  size: 255

=head2 allele_phenotype

  data_type: 'text'
  is_nullable: 1

=head2 allele_notes

  data_type: 'text'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
  is_nullable: 1

=head2 is_default

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 sequence

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "allele_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "allele_allele_id_seq",
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "allele_symbol",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "allele_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mode_of_inheritance",
  { data_type => "varchar", is_nullable => 1, size => 18 },
  "allele_synonym",
  { data_type => "character varying[]", is_nullable => 1, size => 255 },
  "allele_phenotype",
  { data_type => "text", is_nullable => 1 },
  "allele_notes",
  { data_type => "text", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_nullable => 1 },
  "is_default",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "sequence",
  { accessor => undef, data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("allele_id");

=head1 RELATIONS

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);

=head2 allele_alias

Type: has_many

Related object: L<CXGN::Phenome::Schema::AlleleAlias>

=cut

__PACKAGE__->has_many(
  "allele_alias",
  "CXGN::Phenome::Schema::AlleleAlias",
  { "foreign.allele_id" => "self.allele_id" },
  {},
);

=head2 allele_dbxrefs

Type: has_many

Related object: L<CXGN::Phenome::Schema::AlleleDbxref>

=cut

__PACKAGE__->has_many(
  "allele_dbxrefs",
  "CXGN::Phenome::Schema::AlleleDbxref",
  { "foreign.allele_id" => "self.allele_id" },
  {},
);

=head2 allele_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::AlleleHistory>

=cut

__PACKAGE__->has_many(
  "allele_histories",
  "CXGN::Phenome::Schema::AlleleHistory",
  { "foreign.allele_id" => "self.allele_id" },
  {},
);

=head2 individual_alleles

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualAllele>

=cut

__PACKAGE__->has_many(
  "individual_alleles",
  "CXGN::Phenome::Schema::IndividualAllele",
  { "foreign.allele_id" => "self.allele_id" },
  {},
);

=head2 stock_alleles

Type: has_many

Related object: L<CXGN::Phenome::Schema::StockAllele>

=cut

__PACKAGE__->has_many(
  "stock_alleles",
  "CXGN::Phenome::Schema::StockAllele",
  { "foreign.allele_id" => "self.allele_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hpH1yOQLBTWsZ7Uk0PtN3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
