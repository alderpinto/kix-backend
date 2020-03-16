# --
# Modified version of the work: Copyright (C) 2006-2020 c.a.p.e. IT GmbH, https://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketTemplate;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Main',
    'Kernel::System::Log',
    'Kernel::System::SysConfig',
    'Kernel::System::JSON'
);

=head1 NAME

Kernel::System::TicketTemplate

=head1 SYNOPSIS

All ticket temaplte functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketTemplateObject = $Kernel::OM->Get('Kernel::System::TicketTemplate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    $Self->{CacheType} = 'TicketTemplate';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=item TicketTemplateList()

Returns all available ticket templates

    my @TemplateList = $TicketObject->TicketTemplateList();

=cut

sub TicketTemplateList {
    my ($Self, %Param) = @_;

    my $TemplateDefinitionsJSON = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Template::Definitions');

    my $TemplateDefinitions = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $TemplateDefinitionsJSON
    );

    # return empty array if wqe have no templates
    return () if !IsArrayRefWithData($TemplateDefinitions);

    return @{$TemplateDefinitions};
}

=item TicketTemplateGet()

Returns data of one ticket template

    my %Template = $TicketObject->TicketTemplateGet(
        Name  => 'TicketTemplateName'
    );

=cut

sub TicketTemplateGet {
    my ($Self, %Param) = @_;

    # check needed stuff
    if (!$Param{Name}) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message => "TicketTemplateGet: Need Name!");
        return;
    }

    my @TemplateList = $Self->TicketTemplateList();

    my %Result;
    foreach my $Template (@TemplateList) {
        next if $Template->{TemplateID} ne $Param{Name};

        %Result = %{$Template};
        last;
    }

    if (!%Result) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message => "TicketTemplateGet: No template with name '$Param{Name}' found!");
        return;
    }
    
    return %Result;
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