# --
# Copyright (C) 2006-2023 KIX Service Software GmbH, https://www.kixdesk.com
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ObjectSearch::Database::ITSMConfigItem::Base;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = qw(
    Config
    Log
);

=head1 NAME

Kernel::System::ObjectSearch::Database::ITSMConfigItem::Base - base module for object search

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item GetBackends()

empty method to be overridden by specific attribute module if necessary

    $Object->GetBackends();

=cut

sub GetBackends {
    my ( $Self, %Param ) = @_;

    my $Backends = $Kernel::OM->Get('Config')->Get('ObjectSearch::Database::ITSMConfigItem::Module');
    my %AttributeModules;

    if ( !IsHashRefWithData($Backends) ) {
        $Kernel::OM->Get('Log')->Log(
            Priority => 'error',
            Message  => "No database search backend modules found!",
        );
        return;
    }

    BACKEND:
    foreach my $Backend ( sort keys %{$Backends} ) {

        my $Object = $Kernel::OM->Get($Backends->{$Backend}->{Module});

        # register module for each supported attribute
        my $SupportedAttributes = $Object->GetSupportedAttributes();
        if ( !IsHashRefWithData($SupportedAttributes) ) {
            $Kernel::OM->Get('Log')->Log(
                Priority => 'error',
                Message  => "SupportedAttributes return by module $Backends->{$Backend}->{Module} are not a HashRef!",
            );
            next BACKEND;
        }

        foreach my $Type ( qw(Search Sort) ) {
            if ( ref($SupportedAttributes->{$Type}) ne 'ARRAY' ) {
                $Kernel::OM->Get('Log')->Log(
                    Priority => 'error',
                    Message  => "SupportedAttributes->{$Type} return by module $Backends->{$Backend}->{Module} is not an ArrayRef!",
                );
                next BACKEND;
            }
            foreach my $Attribute ( @{$SupportedAttributes->{$Type}} ) {
                $AttributeModules{$Type}->{$Attribute} = $Object;
            }
        }
    }

    return \%AttributeModules;
}

sub BaseSQL {
    my ( $Self, %Param ) = @_;

    return {
        Select => 'SELECT DISTINCT(ci.id)',
        From   => 'FROM configitem ci',
        Where  => ' 1=1'
    };
}


=item CreatePermissionSQL()

generate SQL for ticket permission restrictions

    my %SQL = $Object->CreatePermissionSQL(
        UserID    => ...,                    # required
        UserType  => 'Agent' | 'Customer'    # required
    );

=cut

sub CreatePermissionSQL {
    my ( $Self, %Param ) = @_;

    my %Result;

    return %Result;
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
