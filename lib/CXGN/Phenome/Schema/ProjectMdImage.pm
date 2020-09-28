use utf8;
package CXGN::Phenome::Schema::ProjectMdImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::ProjectMdImage

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project_md_image>

=cut

__PACKAGE__->table("project_md_image");

=head1 ACCESSORS

=head2 project_md_image_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_md_image_project_md_image_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 image_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project_md_image_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_md_image_project_md_image_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "image_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_md_image_id>

=back

=cut

__PACKAGE__->set_primary_key("project_md_image_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iTZ+56nekLfeAe+qavFMsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
