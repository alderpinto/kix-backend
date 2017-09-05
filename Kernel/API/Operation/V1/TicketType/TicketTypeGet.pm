# --
# Kernel/API/Operation/V1/TicketType/TicketTypeGet.pm - API TicketType Get operation backend
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

package Kernel::API::Operation::V1::TicketType::TicketTypeGet;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::TicketType::TicketTypeGet - API TicketType Get Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::API::Operation::V1::TicketType::TicketTypeGet->new();

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
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::V1::TicketTypeGet');

    return $Self;
}

=item Run()

perform TicketTypeGet Operation. This function is able to return
one or more ticket entries in one call.

    my $Result = $OperationObject->Run(
        Data => {
            Authorization => {
                ...
            },
            TicketTypeID => 123       # comma separated in case of multiple or arrayref (depending on transport)
        },
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        Message => '',                               # In case of an error
        Data         => {
            TicketType => [
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
            'TicketTypeID' => {
                Type     => 'ARRAY',
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

    my @TicketTypeList;
    my $Message ='';
    
    # start type loop
    TYPE:    
    foreach my $TicketTypeID ( @{$Param{Data}->{TicketTypeID}} ) {

        # get the TicketType data
        my %TicketTypeData = $Kernel::OM->Get('Kernel::System::Type')->TypeGet(
            ID => $TicketTypeID,
        );

        if ( !IsHashRefWithData( \%TicketTypeData ) ) {

            $Message = 'Could not get TicketType data'
                . ' in Kernel::API::Operation::V1::TicketType::TicketTypeGet::Run()';

            return $Self->_Error(
                Code    => 'TicketTypeGet.InvalidTicketTypeID',
                Message => "TicketTypeGet: $Message",
            );
        }
        
        # add
        push(@TicketTypeList, \%TicketTypeData);
    }

    if ( !scalar(@TicketTypeList) ) {
        $Message = 'Could not get TicketType data'
            . ' in Kernel::API::Operation::V1::TicketType::TicketTypeGet::Run()';

        return $Self->_Error(
            Code    => 'TicketTypeGet.NotTicketTypeData',
            Message => "TicketTypeGet: $Message",
        );

    }

    if ( scalar(@TicketTypeList) == 1 ) {
        return $Self->_Success(
            TicketType => $TicketTypeList[0],
        );    
    }

    return $Self->_Success(
        TicketType => \@TicketTypeList,
    );
}

1;



