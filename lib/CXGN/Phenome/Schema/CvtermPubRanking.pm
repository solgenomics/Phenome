package CXGN::Phenome::Schema::CvtermPubRanking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::CvtermPubRanking

=cut

__PACKAGE__->table("cvterm_pub_ranking");

=head1 ACCESSORS

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 1

=head2 pub_id

  data_type: 'integer'
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
  "cvterm_id",
  { data_type => "integer", is_nullable => 1 },
  "pub_id",
  { data_type => "integer", is_nullable => 1 },
  "rank",
  { data_type => "real", is_nullable => 1 },
  "match_type",
  { data_type => "text", is_nullable => 1 },
  "headline",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zkb9qudf+HJQRb5AZqOnjA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
