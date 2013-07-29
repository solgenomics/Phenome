use utf8;
package CXGN::Phenome::Schema::TomatoTerm2term;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::TomatoTerm2term

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tomato_term2term>

=cut

__PACKAGE__->table("tomato_term2term");

=head1 ACCESSORS

=head2 tomato_term2term_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tomato_term2term_tomato_term2term_id_seq'

=head2 relationship_type_id

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 term1_id

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 term2_id

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 complete

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tomato_term2term_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tomato_term2term_tomato_term2term_id_seq",
  },
  "relationship_type_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "term1_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "term2_id",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "complete",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tomato_term2term_id>

=back

=cut

__PACKAGE__->set_primary_key("tomato_term2term_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<term1_id_key>

=over 4

=item * L</term1_id>

=item * L</term2_id>

=item * L</relationship_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "term1_id_key",
  ["term1_id", "term2_id", "relationship_type_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u3+Hq6Dev580kO9mPlFD2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
