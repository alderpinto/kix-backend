# --
# Copyright (C) 2006-2022 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Automation::MacroAction::Ticket::Common;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

use base qw(Kernel::System::Automation::MacroAction::Common);

our @ObjectDependencies = (
    'Config',
    'Encode',
    'Main',
    'Queue',
    'TemplateGenerator',
    'Ticket',
    'Log',
);

=item _CheckParams()

Check if all required parameters are given.

Example:
    my $Result = $Object->_CheckParams(
        TicketID => 123,
        Config   => {
            ...
        }
    );

=cut

sub _ConvertScalar2ArrayRef {
    my ( $Self, %Param ) = @_;

    # FIXME: check if correct
    # BPMX-capeIT
    #    my @Data = split /,/, $Param{Data};
    my @Data = split( '/,/,', $Param{Data} );

    # EO BPMX-capeIT

    # remove any possible heading and tailing white spaces
    for my $Item (@Data) {
        $Item =~ s{\A\s+}{};
        $Item =~ s{\s+\z}{};
    }

    return \@Data;
}

sub _ReplaceValuePlaceholder {
    my ( $Self, %Param ) = @_;

    # add ticket id, to be sure
    $Param{EventData} ||= IsHashRefWithData($Self->{EventData}) ? $Self->{EventData} : {};
    $Param{EventData}->{TicketID} = $Self->{RootObjectID} || $Param{TicketID};

    return $Self->SUPER::_ReplaceValuePlaceholder(%Param);
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-AGPL for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
