# --
# Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::API::Operation::V1::Automation::ExecPlanGet;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::Automation::ExecPlanGet - API ExecPlan Get Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

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
        'ExecPlanID' => {
            Type     => 'ARRAY',
            DataType => 'NUMERIC',
            Required => 1
        }
    }
}

=item Run()

perform ExecPlanGet Operation. This function is able to return
one or more job entries in one call.

    my $Result = $OperationObject->Run(
        Data => {
            ExecPlanID => 123       # comma separated in case of multiple or arrayref (depending on transport)
        },
    );

    $Result = {
        Success      => 1,                           # 0 or 1
        Code         => '',                          # In case of an error
        Message      => '',                          # In case of an error
        Data         => {
            ExecPlan => [
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

    my @ExecPlanList;

    # start loop
    foreach my $ExecPlanID ( @{$Param{Data}->{ExecPlanID}} ) {

	    # get the ExecPlan data
	    my %ExecPlanData = $Kernel::OM->Get('Automation')->ExecPlanGet(
	        ID => $ExecPlanID,
	    );

        if ( !%ExecPlanData ) {
            return $Self->_Error(
                Code => 'Object.NotFound',
            );
        }

        # add
        push(@ExecPlanList, \%ExecPlanData);
    }

    if ( scalar(@ExecPlanList) == 1 ) {
        return $Self->_Success(
            ExecPlan => $ExecPlanList[0],
        );
    }

    # return result
    return $Self->_Success(
        ExecPlan => \@ExecPlanList,
    );
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
