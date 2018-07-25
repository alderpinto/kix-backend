# --
# Kernel/API/Operation/V1/SenderType/SenderTypeGet.pm - API SenderType Get operation backend
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

package Kernel::API::Operation::V1::SenderType::SenderTypeGet;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::SenderType::SenderTypeGet - API SenderType Get Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::API::Operation::V1::SenderType::SenderTypeGet->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(DebuggerObject WebserviceID)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'Operation.InternalError',
                Message => "Got no $Needed!"
            );
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    # get config for this screen
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::V1::SenderType::SenderTypeGet');

    return $Self;
}

=item Run()

perform SenderTypeGet Operation. This function is able to return
one or more ticket entries in one call.

    my $Result = $OperationObject->Run(
        Data => {
            SenderTypeID => 123       # comma separated in case of multiple or arrayref (depending on transport)
        },
    );

    $Result = {
        Success      => 1,                           # 0 or 1
        Code         => '',                          # In case of an error
        Message      => '',                          # In case of an error
        Data         => {
            SenderType => [
                {
                    ...
                },
                {
                    ...
                },
            ]
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
        Data       => $Param{Data},
        Parameters => {
            'SenderTypeID' => {
                Type     => 'ARRAY',
                DataType => 'NUMERIC',
                Required => 1
            }                
        }
    );

    # check result
    if ( !$Result->{Success} ) {
        return $Self->_Error(
            Code    => 'Operation.PrepareDataError',
            Message => $Result->{Message},
        );
    }

    my @SenderTypeList;

    # start SenderType loop
    SenderType:    
    foreach my $SenderTypeID ( @{$Param{Data}->{SenderTypeID}} ) {

        # get the SenderType data
        my $SenderTypeName = $Kernel::OM->Get('Kernel::System::Ticket')->ArticleSenderTypeLookup(
            SenderTypeID => $SenderTypeID,
        );

        if ( !$SenderTypeName ) {
            return $Self->_Error(
                Code    => 'Object.NotFound',
                Message => "No data found for SenderTypeID $SenderTypeID.",
            );
        }
       
        my %SenderType;
        
        $SenderType{ID}   = $SenderTypeID;
        $SenderType{Name} = $SenderTypeName;
        
        # add
        push(@SenderTypeList, \%SenderType);
    }

    if ( scalar(@SenderTypeList) == 1 ) {
        return $Self->_Success(
            SenderType => $SenderTypeList[0],
        );    
    }

    # return result
    return $Self->_Success(
        SenderType => \@SenderTypeList,
    );
}

1;