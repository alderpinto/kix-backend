# --
# Kernel/API/Operation/GeneralCatalog/GeneralCatalogUpdate.pm - API GeneralCatalog Update operation backend
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

package Kernel::API::Operation::V1::GeneralCatalog::GeneralCatalogUpdate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::GeneralCatalog::GeneralCatalogUpdate - API GeneralCatalog Create Operation backend

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

    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::V1::GeneralCatalogUpdate');

    return $Self;
}

=item Run()

perform GeneralCatalogUpdate Operation. This will return the updated TypeID.

    my $Result = $OperationObject->Run(
        Data => {
            GeneralCatalogItemID => 123,
            GeneralCatalog  => {
                Class         => 'ITSM::Service::Type',
                Name          => 'Item Name',
                ValidID       => 1,
                Comment       => 'Comment',              # (optional)
            },
        },
    );
    

    $Result = {
        Success     => 1,                       # 0 or 1
        Code        => '',                      # in case of error
        Message     => '',                      # in case of error
        Data        => {                        # result data payload after Operation
            GeneralCatalogID  => 123,                     # ID of the updated GeneralCatalog 
        },
    };
   
=cut


sub Run {
    my ( $Self, %Param ) = @_;

    # init webGeneralCatalog
    my $Result = $Self->Init(
        WebserviceID => $Self->{WebserviceID},
    );

    if ( !$Result->{Success} ) {
        $Self->_Error(
            Code    => 'WebService.InvalidConfiguration',
            Message => $Result->{Message},
        );
    }

    # prepare data
    $Result = $Self->PrepareData(
        Data         => $Param{Data},
        Parameters   => {
            'GeneralCatalogItemID' => {
                Required => 1
            },
            'GeneralCatalog' => {
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

    # isolate GeneralCatalog parameter
    my $GeneralCatalog = $Param{Data}->{GeneralCatalog};

    # remove leading and trailing spaces
    for my $Attribute ( sort keys %{$GeneralCatalog} ) {
        if ( ref $Attribute ne 'HASH' && ref $Attribute ne 'ARRAY' ) {

            #remove leading spaces
            $GeneralCatalog->{$Attribute} =~ s{\A\s+}{};

            #remove trailing spaces
            $GeneralCatalog->{$Attribute} =~ s{\s+\z}{};
        }
    }   

    # check if GeneralCatalog exists 
    my $GeneralCatalogData = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        ItemID => $Param{Data}->{GeneralCatalogItemID},
    );

    if ( !$GeneralCatalogData ) {
        return $Self->_Error(
            Code    => 'Object.NotFound',
            Message => "Cannot update GeneralCatalog. No GeneralCatalog with ID '$Param{Data}->{GeneralCatalogID}' found.",
        );
    }

    # update GeneralCatalog
    my $Success = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemUpdate(
        ItemID       => $Param{Data}->{GeneralCatalogItemID} || $GeneralCatalogData->{ItemID},    
        Class    => $GeneralCatalog->{Class} || $GeneralCatalogData->{Class},
        Name     => $GeneralCatalog->{Name} || $GeneralCatalogData->{Name},
        Comment  => $GeneralCatalog->{Comment} || $GeneralCatalogData->{Comment},
        ValidID  => $GeneralCatalog->{ValidID} || $GeneralCatalogData->{ValidID},
        UserID   => $Self->{Authorization}->{UserID},                        
    );

    if ( !$Success ) {
        return $Self->_Error(
            Code    => 'Object.UnableToUpdate',
            Message => 'Could not update GeneralCatalog, please contact the system administrator',
        );
    }

    # return result    
    return $Self->_Success(
        GeneralCatalogID => $Param{Data}->{GeneralCatalogID},
    );    
}

1;
