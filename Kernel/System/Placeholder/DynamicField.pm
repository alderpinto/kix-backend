# --
# Modified version of the work: Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Placeholder::DynamicField;

use strict;
use warnings;

use Kernel::Language;

use Kernel::System::VariableCheck qw(:all);

use base qw(Kernel::System::Placeholder::Base);

our @ObjectDependencies = (
    'DynamicField',
    'DynamicField::Backend',
    'Log'
);

=head1 NAME

Kernel::System::Placeholder::DynamicField

=cut

=begin Internal:

=cut

sub _Replace {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Text UserID)) {
        if ( !defined $Param{$_} ) {
            $Kernel::OM->Get('Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    my $Tag = $Self->{Start} . 'KIX_TICKET_DynamicField_';

    if ( IsHashRefWithData($Param{Ticket}) ) {

        # Dropdown, Checkbox and MultipleSelect DynamicFields, can store values (keys) that are
        # different from the the values to display
        # <KIX_TICKET_DynamicField_NameX> returns the display value
        # <KIX_TICKET_DynamicField_NameX_Value> also returns the display value
        # <KIX_TICKET_DynamicField_NameX_Key> returns the stored key for select fields (multiselect, reference)
        # <KIX_TICKET_DynamicField_NameX_HTML> returns a special HTML display value (e.g. checklist) or default display value
        # <KIX_TICKET_DynamicField_NameX_Short> returns a short display value (e.g. checklist) or default display value

        my %DynamicFields;

        # For systems with many Dynamic fields we do not want to load them all unless needed
        # Find what Dynamic Field Values are requested
        while ( $Param{Text} =~ m/$Tag(\S+?)(_Value|_Key|_HTML|_Short)? $Self->{End}/gixms ) {
            $DynamicFields{$1} = 1;
        }

        # to store all the required DynamicField display values
        my %DynamicFieldDisplayValues;

        # get dynamic field objects
        my $DynamicFieldObject        = $Kernel::OM->Get('DynamicField');
        my $DynamicFieldBackendObject = $Kernel::OM->Get('DynamicField::Backend');

        # get the dynamic fields for ticket object
        my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
            Valid      => 1,
            ObjectType => ['Ticket'],
        ) || [];

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            # only prepare values of the requested ones
            next DYNAMICFIELD if !$DynamicFields{ $DynamicFieldConfig->{Name} };

            # get the display values for each dynamic field
            my $DisplayValueStrg = $DynamicFieldBackendObject->DisplayValueRender(
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Ticket}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
                HTMLOutput         => $Param{RichText}
            );
            if ( IsHashRefWithData($DisplayValueStrg) ) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_Value' }
                    = $DisplayValueStrg->{Value};
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} }
                    = $DisplayValueStrg->{Value};
            }

            # get the display keys for each dynamic field
            my $DisplayKeyStrg = $DynamicFieldBackendObject->DisplayKeyRender(
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Ticket}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
            );

            if (IsHashRefWithData($DisplayKeyStrg) && $DisplayKeyStrg->{Value}) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_Key' }
                    = $DisplayKeyStrg->{Value} ;
            } elsif (IsHashRefWithData($DisplayValueStrg)) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_Key' }
                    = $DisplayValueStrg->{Value};
            }

            # get the html display values for each dynamic field
            my $HTMLDisplayValueStrg = $DynamicFieldBackendObject->HTMLDisplayValueRender(
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Ticket}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
            );
            if ( IsHashRefWithData($HTMLDisplayValueStrg) && $HTMLDisplayValueStrg->{Value} ) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_HTML' }
                    = $HTMLDisplayValueStrg->{Value};
            } elsif (IsHashRefWithData($DisplayValueStrg)) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_HTML' }
                    = $DisplayValueStrg->{Value};
            }

            # get the short display values for each dynamic field
            my $ShortDisplayValueStrg = $DynamicFieldBackendObject->ShortDisplayValueRender(
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Ticket}->{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
            );
            if ( IsHashRefWithData($ShortDisplayValueStrg) && $ShortDisplayValueStrg->{Value} ) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_Short' }
                    = $ShortDisplayValueStrg->{Value};
            } elsif (IsHashRefWithData($DisplayValueStrg)) {
                $DynamicFieldDisplayValues{ $DynamicFieldConfig->{Name} . '_Short' }
                    = $DisplayValueStrg->{Value};
            }
        }

        # replace it
        $Param{Text} = $Self->_HashGlobalReplace( $Param{Text}, $Tag, %DynamicFieldDisplayValues );
    }

    # cleanup
    $Param{Text} =~ s/$Tag.+?$Self->{End}/-/gi;

    return $Param{Text};
}

1;

=end Internal:

=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<https://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
LICENSE-AGPL for license information (AGPL). If you did not receive this file, see

<https://www.gnu.org/licenses/agpl.txt>.

=cut
