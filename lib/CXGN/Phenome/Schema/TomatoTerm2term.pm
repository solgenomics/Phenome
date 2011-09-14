package CXGN::Phenome::Schema::TomatoTerm2term;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::TomatoTerm2term

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
  default_value: '0)::bigint'
  is_nullable: 0

=head2 term1_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 term2_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 complete

  data_type: 'bigint'
  default_value: '0)::bigint'
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
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "term1_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "term2_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "complete",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("tomato_term2term_id");
__PACKAGE__->add_unique_constraint(
  "term1_id_key",
  ["term1_id", "term2_id", "relationship_type_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZQrXZ/2RgW9IJgxC3YYIOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
