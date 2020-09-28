use utf8;
package CXGN::Phenome::Schema::Locus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::Locus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<locus>

=cut

__PACKAGE__->table("locus");

=head1 ACCESSORS

=head2 locus_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus_locus_id_seq'

=head2 locus_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 locus_symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 original_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 gene_activity

  data_type: 'text'
  is_nullable: 1

=head2 locus_notes

  data_type: 'text'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
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

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 linkage_group

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 lg_arm

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 common_name_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 updated_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 locus

  data_type: 'varchar'
  is_nullable: 1
  size: 24

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "locus_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus_locus_id_seq",
  },
  "locus_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "locus_symbol",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "original_symbol",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "gene_activity",
  { data_type => "text", is_nullable => 1 },
  "locus_notes",
  { data_type => "text", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "linkage_group",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "lg_arm",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "common_name_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updated_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "locus",
  { data_type => "varchar", is_nullable => 1, size => 24 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</locus_id>

=back

=cut

__PACKAGE__->set_primary_key("locus_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<locus_name_key>

=over 4

=item * L</locus_name>

=item * L</common_name_id>

=item * L</obsolete>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "locus_name_key",
  ["locus_name", "common_name_id", "obsolete"],
);

=head2 C<locus_symbol_key>

=over 4

=item * L</locus_symbol>

=item * L</common_name_id>

=item * L</obsolete>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "locus_symbol_key",
  ["locus_symbol", "common_name_id", "obsolete"],
);

=head1 RELATIONS

=head2 allele_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::AlleleHistory>

=cut

__PACKAGE__->has_many(
  "allele_histories",
  "CXGN::Phenome::Schema::AlleleHistory",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 alleles

Type: has_many

Related object: L<CXGN::Phenome::Schema::Allele>

=cut

__PACKAGE__->has_many(
  "alleles",
  "CXGN::Phenome::Schema::Allele",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 individual_loci

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualLocus>

=cut

__PACKAGE__->has_many(
  "individual_loci",
  "CXGN::Phenome::Schema::IndividualLocus",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus2locus_object_ids

Type: has_many

Related object: L<CXGN::Phenome::Schema::Locus2locus>

=cut

__PACKAGE__->has_many(
  "locus2locus_object_ids",
  "CXGN::Phenome::Schema::Locus2locus",
  { "foreign.object_id" => "self.locus_id" },
  undef,
);

=head2 locus2locus_subject_ids

Type: has_many

Related object: L<CXGN::Phenome::Schema::Locus2locus>

=cut

__PACKAGE__->has_many(
  "locus2locus_subject_ids",
  "CXGN::Phenome::Schema::Locus2locus",
  { "foreign.subject_id" => "self.locus_id" },
  undef,
);

=head2 locus_alias

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusAlias>

=cut

__PACKAGE__->has_many(
  "locus_alias",
  "CXGN::Phenome::Schema::LocusAlias",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_dbxrefs

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusDbxref>

=cut

__PACKAGE__->has_many(
  "locus_dbxrefs",
  "CXGN::Phenome::Schema::LocusDbxref",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusHistory>

=cut

__PACKAGE__->has_many(
  "locus_histories",
  "CXGN::Phenome::Schema::LocusHistory",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_images

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusImage>

=cut

__PACKAGE__->has_many(
  "locus_images",
  "CXGN::Phenome::Schema::LocusImage",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_markers

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusMarker>

=cut

__PACKAGE__->has_many(
  "locus_markers",
  "CXGN::Phenome::Schema::LocusMarker",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_owners

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusOwner>

=cut

__PACKAGE__->has_many(
  "locus_owners",
  "CXGN::Phenome::Schema::LocusOwner",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_pub_ranking_validates

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusPubRankingValidate>

=cut

__PACKAGE__->has_many(
  "locus_pub_ranking_validates",
  "CXGN::Phenome::Schema::LocusPubRankingValidate",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_pub_rankings

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusPubRanking>

=cut

__PACKAGE__->has_many(
  "locus_pub_rankings",
  "CXGN::Phenome::Schema::LocusPubRanking",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_registries

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusRegistry>

=cut

__PACKAGE__->has_many(
  "locus_registries",
  "CXGN::Phenome::Schema::LocusRegistry",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locus_unigenes

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusUnigene>

=cut

__PACKAGE__->has_many(
  "locus_unigenes",
  "CXGN::Phenome::Schema::LocusUnigene",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 locusgroup_members

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusgroupMember>

=cut

__PACKAGE__->has_many(
  "locusgroup_members",
  "CXGN::Phenome::Schema::LocusgroupMember",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);

=head2 variants

Type: has_many

Related object: L<CXGN::Phenome::Schema::Variant>

=cut

__PACKAGE__->has_many(
  "variants",
  "CXGN::Phenome::Schema::Variant",
  { "foreign.locus_id" => "self.locus_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RbTxMMGAr2EMtuHFBft13Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
