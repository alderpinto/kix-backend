# --
# Modified version of the work: Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::API::Operation::V1::CMDB::ConfigItemHistoryGet;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use base qw(
    Kernel::API::Operation::V1::CMDB::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::CMDB::ConfigItemHistoryGet - API ConfigItemHistoryGet Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::API::Operation::V1->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(DebuggerObject WebserviceID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!",
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=item Run()

perform ConfigItemHistoryGet Operation.

    my $Result = $OperationObject->Run(
        ConfigItemID => 1,                                # required 
        HistoryID    => 1                                 # required
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        Code         => '',                               # In case of an error
        Message      => '',                               # In case of an error
        Data         => {
            ConfigItemHistory => [
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
            'ConfigItemID' => {
                DataType => 'NUMERIC',
                Required => 1
            },
            'HistoryID' => {
                Type     => 'ARRAY',
                DataType => 'NUMERIC',
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

    # check if ConfigItem exists
    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->HistoryGet(
        ConfigItemID => $ConfigItemID,
    );

    if (!IsHashRefWithData($ConfigItem)) {
        return $Self->_Error(
            Code    => 'Object.NotFound',
            Message => "Could not get data for ConfigItemID $Param{Data}->{ConfigItemID}",
        );
    }

    my @HistoryList;        
    foreach my $HistoryID ( @{$Param{Data}->{HistoryID}} ) {                 

        my $HistoryItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->HistoryEntryGet(
            HistoryEntryID => $HistoryID
        );

        if (!IsHashRefWithData($HistoryItem)) {
            return $Self->_Error(
                Code    => 'Object.NotFound',
                Message => "Could not get data for HistoryID $HistoryID in ConfigItemID $Param{Data}->{ConfigItemID}",
            );
        }     

        push(@HistoryList, $HistoryItem);
    }

    if ( scalar(@HistoryList) == 0 ) {
        return $Self->_Error(
            Code    => 'Object.NotFound',
            Message => "Could not get data for HistoryID ".join(',', $Param{Data}->{HistoryID}),
        );
    }
    elsif ( scalar(@HistoryList) == 1 ) {
        return $Self->_Success(
            ConfigItemHistory => $HistoryList[0],
        );    
    }

    return $Self->_Success(
        ConfigItemHistory => \@HistoryList,
    );
}

1;




=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut
