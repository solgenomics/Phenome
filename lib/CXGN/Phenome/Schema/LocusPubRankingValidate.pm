package CXGN::Phenome::Schema::LocusPubRankingValidate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::LocusPubRankingValidate

=cut

__PACKAGE__->table("locus_pub_ranking_validate");

=head1 ACCESSORS

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pub_id

  data_type: 'integer'
  is_nullable: 1

=head2 validate

  data_type: 'varchar'
  is_nullable: 1
  size: 18

=cut

__PACKAGE__->add_columns(
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pub_id",
  { data_type => "integer", is_nullable => 1 },
  "validate",
  { data_type => "varchar", is_nullable => 1, size => 18 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bDB8cgd5cQn9iSUCtOnDLQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
