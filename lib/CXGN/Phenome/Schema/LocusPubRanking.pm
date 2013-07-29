use utf8;
package CXGN::Phenome::Schema::LocusPubRanking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::LocusPubRanking

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<locus_pub_ranking>

=cut

__PACKAGE__->table("locus_pub_ranking");

=head1 ACCESSORS

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rank

  data_type: 'real'
  is_nullable: 1

=head2 match_type

  data_type: 'text'
  is_nullable: 1

=head2 headline

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rank",
  { data_type => "real", is_nullable => 1 },
  "match_type",
  { data_type => "text", is_nullable => 1 },
  "headline",
  { data_type => "text", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/l15DbP8ZXtnxK1ji46iCg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
