# --
# Copyright (C) 2006-2023 KIX Service Software GmbH, https://www.kixdesk.com
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ObjectSearch::Database::ITSMConfigItem::Owner;

use strict;
use warnings;

use base qw(
    Kernel::System::ObjectSearch::Database::ITSMConfigItem::Common
);

our @ObjectDependencies = qw(
    Log
);

=head1 NAME

Kernel::System::ObjectSearch::Database::Ticket::OwnerResponsible - attribute module for database object search

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item GetSupportedAttributes()

defines the list of attributes this module is supporting

    my $AttributeList = $Object->GetSupportedAttributes();

    $Result = {
        Search => [ ],
        Sort   => [ ],
    };

=cut

sub GetSupportedAttributes {
    my ( $Self, %Param ) = @_;

    return {
        Search => [
            'CreateBy',
            'ChangeBy',
        ],
        Sort => [
            'CreateBy',
            'ChangeBy',
        ]
    };
}


=item Search()

run this module and return the SQL extensions

    my $Result = $Object->Search(
        Search => {}
    );

    $Result = {
        SQLWhere   => [ ],
    };

=cut

sub Search {
    my ( $Self, %Param ) = @_;
    my @SQLWhere;

    # check params
    if ( !$Param{Search} ) {
        $Kernel::OM->Get('Log')->Log(
            Priority => 'error',
            Message  => "Need Search!",
        );
        return;
    }

    my %AttributeMapping = (
        'CreateBy' => 'ci.create_by',
        'ChangeBy' => 'ci.change_by',
    );

    my %SupportedOperator = (
        'EQ' => 1,
        'NE' => 1,
        'IN' => 1,
    );

    if ( !$SupportedOperator{$Param{Search}->{Operator}} ) {
        $Kernel::OM->Get('Log')->Log(
            Priority => 'error',
            Message  => "Unsupported Operator $Param{Search}->{Operator}!",
        );
        return;
    }

    my $Where = $Self->GetOperation(
        Operator => $Param{Search}->{Operator},
        Column   => $AttributeMapping{$Param{Search}->{Field}},
        Value    => $Param{Search}->{Value},
    );

    return if !$Where;

    push( @SQLWhere, $Where);

    return {
        SQLWhere => \@SQLWhere,
    };
}


=item Sort()

run this module and return the SQL extensions

    my $Result = $Object->Sort(
        Attribute => '...'      # required
    );

    $Result = {
        SQLAttrs   => [ ],          # optional
        SQLOrderBy => [ ]           # optional
    };

=cut

sub Sort {
    my ( $Self, %Param ) = @_;

    my %AttributeMapping = (
        'CreateBy' => 'ci.create_by',
        'ChangeBy' => 'ci.change_by',
    );

    return {
        SQLAttrs => [
            $AttributeMapping{$Param{Attribute}}
        ],
        SQLOrderBy => [
            $AttributeMapping{$Param{Attribute}}
        ],
    };
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
