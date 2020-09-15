use utf8;
package CXGN::Phenome::Schema::NdExperimentMdImages;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::NdExperimentMdImages

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_md_images>

=cut

__PACKAGE__->table("nd_experiment_md_images");

=head1 ACCESSORS

=head2 nd_experiment_md_images_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_md_images_nd_experiment_md_images_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 image_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_md_images_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_md_images_nd_experiment_md_images_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "image_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_md_images_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_md_images_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TY9iu9sx4rRAe8JWyQ9pHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
