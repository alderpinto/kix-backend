# --
# Kernel/API/Operation/User/UserUpdate.pm - API User Create operation backend
# Copyright (C) 2006-2016 c.a.p.e. IT GmbH, http://www.cape-it.de
#
# written/edited by:
# * Rene(dot)Boehm(at)cape(dash)it(dot)de
# 
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::API::Operation::V1::User::UserUpdate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::User::V1::UserUpdate - API User Create Operation backend

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
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::V1::UserUpdate');

    return $Self;
}

=item Run()

perform UserUpdate Operation. This will return the updated UserID.

    my $Result = $OperationObject->Run(
        Data => {
            Authorization => {
                ...
            },

            User => {
                UserLogin       => '...'                                        # requires a value if given
                UserFirstname   => '...'                                        # requires a value if given
                UserLastname    => '...'                                        # requires a value if given
                UserEmail       => '...'                                        # requires a value if given
                UserPassword    => '...'                                        # optional                
                UserPhone       => '...'                                        # optional                
                UserTitle       => '...'                                        # optional
                ValidID         = 0 | 1 | 2                                     # optional
            },
        },
    );

    $Result = {
        Success         => 1,                       # 0 or 1
        ErrorMessage    => '',                      # in case of error
        Data            => {                        # result data payload after Operation
            UserID  => '',                          # UserID 
            Error => {                              # should not return errors
                    ErrorCode    => 'User.Create.ErrorCode'
                    ErrorMessage => 'Error Description'
            },
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # init webservice
    my $Result = $Self->Init(
        WebserviceID => $Self->{WebserviceID},
    );

    if ( !$Result->{Success} ) {
        $Self->ReturnError(
            ErrorCode    => 'Webservice.InvalidConfiguration',
            ErrorMessage => $Result->{ErrorMessage},
        );
    }

    # parse and prepare parameters
    $Result = $Self->ParseParameters(
        Data       => $Param{Data},
        Parameters => {
            'User' => {
                Type     => 'HASH',
                Required => 1
            },
            'User::UserLogin' => {
                RequiresValueIfUsed => 1
            },
            'User::UserFirstname' => {
                RequiresValueIfUsed => 1
            },
            'User::UserLastname' => {
                RequiresValueIfUsed => 1
            },
            'User::UserEmail' => {
                RequiresValueIfUsed => 1
            },
        }
    );

    # check result
    if ( !$Result->{Success} ) {
        return $Self->ReturnError(
            ErrorCode    => 'UserUpdate.MissingParameter',
            ErrorMessage => $Result->{ErrorMessage},
        );
    }

    # isolate User parameter
    my $User = $Param{Data}->{User};

    # remove leading and trailing spaces
    for my $Attribute ( sort keys %{$User} ) {
        if ( ref $Attribute ne 'HASH' && ref $Attribute ne 'ARRAY' ) {

            #remove leading spaces
            $User->{$Attribute} =~ s{\A\s+}{};

            #remove trailing spaces
            $User->{$Attribute} =~ s{\s+\z}{};
        }
    }

    # check UserLogin exists
    my %UserData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        User => $User->{UserLogin},
    );
    if ( !%UserData ) {
        return {
            Success      => 0,
            ErrorMessage => "Can not update user. No user with ID '$User->{UserID}' found.",
        }
    }

    # check UserEmail exists
    my %UserList = $Kernel::OM->Get('Kernel::System::User')->UserSearch(
        Search => $User->{UserEmail},
    );
    if ( %UserList && (scalar(keys %UserList) > 1 || !$UserList{$UserData{UserID}})) {        
        return {
            Success      => 0,
            ErrorMessage => 'Can not update user. User with same login already exists.',
        }
    }
    
    # update User
    my $Success = $Kernel::OM->Get('Kernel::System::User')->UserUpdate(
        %UserData,
        %{$User},
        ChangeUserID  => $Param{Data}->{Authorization}->{UserID},
    );    
    if ( !$Success ) {
        return {
            Success      => 0,
            ErrorMessage => 'Could not update user, please contact the system administrator',
        }
    }
    
    return {
        Success => 1,
        Data    => {
            UserID => $UserData{UserID},
        },
    };
}