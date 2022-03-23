# --
# Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Installation::Migration::KIX17::TextModule;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use base qw(
    Kernel::System::Installation::Migration::KIX17::Common
);

our @ObjectDependencies = (
    'Config',
    'DB',
    'Log',
);

=item Describe()

describe what is supported and what is required

=cut

sub Describe {
    my ( $Self, %Param ) = @_;

    return {
        Supports => [
            'kix_text_module'
        ],
        Depends => {
            'create_by' => 'users',
            'change_by' => 'users',
        }
    }
}

=item Run()

create a new item in the DB

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # get source data
    my $SourceData = $Self->GetSourceData(Type => 'kix_text_module');

    # bail out if we don't have something to todo
    return if !IsArrayRefWithData($SourceData);

    # load categories
    my $CategoryData = $Self->GetSourceData(Type => 'kix_text_module_category', NoProgress => 1);
    my %Categories = map { $_->{id} => $_->{name} } @{$CategoryData};

    $Self->InitProgress(Type => $Param{Type}, ItemCount => scalar(@{$SourceData}));

    foreach my $Item ( @{$SourceData} ) {

        # check if this object is already mapped
        my $MappedID = $Self->GetOIDMapping(
            ObjectType     => 'text_module',
            SourceObjectID => $Item->{id}
        );
        if ( $MappedID ) {
            $Self->UpdateProgress($Param{Type}, 'Ignore');
            next;
        }

        # rewrite placeholders
        foreach my $Key ( sort keys %{$Item} ) {
            $Item->{$Key} =~ s/<OTRS_/<KIX_/g;
            $Item->{$Key} =~ s/&lt;OTRS_/&lt;KIX_/g;
        }

        # prepare keywords
        my %Keywords = map { my $Tmp = $_; $Tmp =~ s/\s/_/g; $Tmp => 1 } split(/\s*,\s*/, $Item->{keywords});
        my $AssignedCategoriesData = $Self->GetSourceData(
            Type       => 'kix_text_module_object_link',
            Where      => "object_type = 'TextModuleCategory' AND text_module_id = $Item->{id}",
            NoProgress => 1
        );
        CATEGORY:
        foreach my $AssignedObject ( @{$AssignedCategoriesData||[]} ) {

            my $Category = $Categories{$AssignedObject->{object_id}};
            next if !$Category;
            $Category =~ s/\s/_/g;       # replace spaces with _
            $Keywords{$Category} = 1;
        }
        $Item->{keywords} = join(' ', sort keys %Keywords);

        $Item->{comment} = 'migrated from KIX17';

        if ($Item->{'f_customer'} || $Item->{'f_public'}) {
            # extend comment
            my @Frontend;
            push @Frontend, 'customer' if $Item->{'f_customer'};
            push @Frontend, 'public' if $Item->{'f_public'};
            $Item->{comment} .= sprintf ' (was %s frontend)', join('/', @Frontend);
            # deactivate too
            $Item->{valid_id} = 2;
        }

        my $ID = $Self->Insert(
            Table          => 'text_module',
            PrimaryKey     => 'id',
            Item           => $Item,
            AutoPrimaryKey => 1,
        );

        if ( $ID ) {
            $Self->UpdateProgress($Param{Type}, 'OK');
        }
        else {
            $Self->UpdateProgress($Param{Type}, 'Error');
        }
    }

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-GPL3 for license information (GPL3). If you did not receive this file, see

<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
