# --
# Kernel/API/Operation/DynamicField/DynamicFieldConfigUpdate.pm - API DynamicField Update operation backend
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

package Kernel::API::Operation::V1::DynamicField::DynamicFieldConfigUpdate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::DynamicField::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::DynamicField::DynamicFieldConfigUpdate - API DynamicField Update Operation backend

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

    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::V1::DynamicFieldConfigUpdate');

    return $Self;
}

=item Run()

perform DynamicFieldConfigUpdate Operation. This will return the updated DynamicFieldID.

    my $Result = $OperationObject->Run(
        Data => {
            DynamicFieldID => 123,
            DynamicFieldConfig => {
                ...
            }
	    },
	);
    

    $Result = {
        Success     => 1,                       # 0 or 1
        Code        => '',                      # in case of error
        Message     => '',                      # in case of error
        Data        => {                        # result data payload after Operation
            DynamicFieldID  => 123,             # ID of the updated DynamicField 
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
        $Self->_Error(
            Code    => 'Webservice.InvalidConfiguration',
            Message => $Result->{Message},
        );
    }

    # prepare data
    $Result = $Self->PrepareData(
        Data         => $Param{Data},
        Parameters   => {
            'DynamicFieldID' => {
                Required => 1
            },
            'DynamicFieldConfig' => {
                Type => 'HASH',
                Required => 1
            },
        }        
    );

    # check result
    if ( !$Result->{Success} ) {
        return $Self->_Error(
            Code    => 'Operation.PrepareDataError',
            Message => $Result->{Message},
        );
    }

    # isolate DynamicFieldConfig parameter
    my $DynamicFieldConfig = $Param{Data}->{DynamicFieldConfig};

    # remove leading and trailing spaces
    for my $Attribute ( sort keys %{$DynamicFieldConfig} ) {
        if ( ref $Attribute ne 'HASH' && ref $Attribute ne 'ARRAY' ) {

            #remove leading spaces
            $DynamicFieldConfig->{$Attribute} =~ s{\A\s+}{};

            #remove trailing spaces
            $DynamicFieldConfig->{$Attribute} =~ s{\s+\z}{};
        }
    }   

    # check if DynamicField exists 
    my $DynamicFieldData = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        ID => $Param{Data}->{DynamicFieldID},
    );
  
    if ( !IsHashRefWithData($DynamicFieldData) ) {
        return $Self->_Error(
            Code    => 'Object.NotFound',
            Message => "Cannot update DynamicField config. No DynamicField with ID '$Param{Data}->{DynamicFieldID}' found.",
        );
    }

    # update DynamicField
    my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldUpdate(
        ID         => $Param{Data}->{DynamicFieldID},
        Name       => $DynamicFieldData->{Name},
        Label      => $DynamicFieldData->{Label},
        FieldType  => $DynamicFieldData->{FieldType},
        ObjectType => $DynamicFieldData->{ObjectType},
        Config     => $DynamicFieldConfig,
        ValidID    => $DynamicFieldData->{ValidID},
        UserID     => $Self->{Authorization}->{UserID},
    );

    if ( !$Success ) {
        return $Self->_Error(
            Code    => 'Object.UnableToUpdate',
            Message => 'Could not update DynamicField config, please contact the system administrator',
        );
    }

    # return result    
    return $Self->_Success(
        DynamicFieldID => $Param{Data}->{DynamicFieldID},
    );    
}

