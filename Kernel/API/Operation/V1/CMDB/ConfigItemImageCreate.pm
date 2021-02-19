# --
# Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::API::Operation::V1::CMDB::ConfigItemImageCreate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use base qw(
    Kernel::API::Operation::V1::CMDB::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::CMDB::ConfigItemImageCreate - API ConfigItemImage Create Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::API::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'Operation.InternalError',
                Message => "Got no $Needed!"
            );
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=item ParameterDefinition()

define parameter preparation and check for this operation

    my $Result = $OperationObject->ParameterDefinition(
        Data => {
            ...
        },
    );

    $Result = {
        ...
    };

=cut

sub ParameterDefinition {
    my ( $Self, %Param ) = @_;

    return {
        'ConfigItemID' => {
            Required => 1,
        },
        'Image' => {
            Required => 1,
            Type     => 'HASH'
        },
        'Image::Filename' => {
            Required => 1,
        },
        'Image::ContentType' => {
            Required => 1,
        },
        'Image::Content' => {
            Required => 1,
        },
    }
}

=item Run()

perform ConfigItemImageCreate Operation. This will return the created VersionID.

    my $Result = $OperationObject->Run(
        Data => {
            ConfigItemID => 123,
            Image => {
                ...                                
            },
        },
    );

    $Result = {
        Success         => 1,                       # 0 or 1
        Code            => '',                      # 
        Message         => '',                      # in case of error
        Data            => {                        # result data payload after Operation
            VersionID  => '',                       # VersionID 
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # if necessary check if config item is accessible for current customer user
    my $CustomerCheck = $Self->_CheckCustomerAssignedConfigItem(
        ConfigItemIDList => $Param{Data}->{ConfigItemID}
    );
    if ( !$CustomerCheck->{Success} ) {
        return $Self->_Error(
            %{$CustomerCheck},
        );
    }

    # get config item data
    my $ConfigItem = $Kernel::OM->Get('ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $Param{Data}->{ConfigItemID}
    );

    # check if ConfigItem exists
    if ( !$ConfigItem ) {
        return $Self->_Error(
            Code => 'ParentObject.NotFound',
        );
    }

    # isolate and trim Image parameter
    my $Image = $Self->_Trim(
        Data => $Param{Data}->{Image}
    );

    # everything is ok, let's create the image
    my $ImageID = $Kernel::OM->Get('ITSMConfigItem')->ImageAdd(
        ConfigItemID => $Param{Data}->{ConfigItemID},
        Filename     => $Image->{Filename},
        Content      => $Image->{Content},
        ContentType  => $Image->{ContentType},
        Comment      => $Image->{Comment},
        UserID       => $Self->{Authorization}->{UserID},
    );

    if ( !$ImageID ) {
        return $Self->_Error(
            Code => 'Object.UnableToCreate',
        );
    }

    return $Self->_Success(
        Code      => 'Object.Created',
        ImageID => $ImageID,
    )
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
