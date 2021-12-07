# --
# Copyright (C) 2006-2021 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-GPL3 for license information (GPL3). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::API::Operation::V1::Contact::ContactGet;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

use base qw(
    Kernel::API::Operation::V1::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::Contact::ContactGet - API Contact Get Operation backend

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
        'ContactID' => {
            DataType => 'NUMERIC',
            Type     => 'ARRAY',
            Required => 1
        }
    }
}

=item Run()

perform ContactGet Operation. This function is able to return
one or more ticket entries in one call.

    my $Result = $OperationObject->Run(
        Data => {
            ContactID => 123       # comma separated in case of multiple or arrayref (depending on transport)
        },
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        Code         => '...'
        Message      => '',                               # In case of an error
        Data         => {
            Contact => [
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

    my @ContactList;

    if ( $Self->_CanRunParallel(Items => $Param{Data}->{ContactID}) ) {
        @ContactList = $Self->_RunParallel(
            \&_GetContactData,
            Items => $Param{Data}->{ContactID},
            %Param,
        );

        foreach my $ContactData (@ContactList) {
            if (defined $ContactData->{Success} && $ContactData->{Success} == 0) {
                return $Self->_Error(
                    Code => $ContactData->{Code} ? $ContactData->{Code} : 'Object.Invalid'
                );
            }
        }

    }
    else {
        # start loop
        foreach my $ContactID ( @{$Param{Data}->{ContactID}} ) {
            my $ContactData = $Self->_GetContactData(
                ContactID => $ContactID,
                Data      => $Param{Data}
            );

            if (IsHashRefWithData($ContactData)) {

                if (defined $ContactData->{Success} && $ContactData->{Success} == 0) {
                    return $Self->_Error(
                        Code => $ContactData->{Code} ? $ContactData->{Code} : 'Object.Invalid'
                    );
                }

                push @ContactList, $ContactData;
            }
        }
    }

    if ( scalar(@ContactList) == 1 ) {
        return $Self->_Success(
            Contact => $ContactList[0],
        );
    }

    return $Self->_Success(
        Contact => \@ContactList,
    );
}

sub _GetContactData {
    my ( $Self, %Param ) = @_;

    my $ContactID = $Param{Item} || $Param{ContactID};

    # get the Contact data
    my %ContactData = $Kernel::OM->Get('Contact')->ContactGet(
        ID            => $ContactID,
        DynamicFields => $Param{Data}->{include}->{DynamicFields},
    );

    if ( !IsHashRefWithData( \%ContactData ) ) {

        return $Self->_Error(
            Code => 'Object.NotFound',
        );
    }

    if ( $Param{Data}->{include}->{DynamicFields} ) {
        my @DynamicFields;

        # inform API caching about a new dependency
        $Self->AddCacheDependency(Type => 'DynamicField');

        # remove all dynamic fields from contact hash and set them into an array.
        ATTRIBUTE:
        for my $Attribute ( sort keys %ContactData ) {

            if ( $Attribute =~ m{\A DynamicField_(.*) \z}msx ) {
                if ( $ContactData{$Attribute} ) {
                    my $DynamicFieldConfig = $Kernel::OM->Get('DynamicField')->DynamicFieldGet(
                        Name => $1,
                    );
                    if ( IsHashRefWithData($DynamicFieldConfig) ) {

                        # ignore DFs which are not visible for the customer, if the user session is a Customer session
                        next ATTRIBUTE if $Self->{Authorization}->{UserType} eq 'Customer' && !$DynamicFieldConfig->{CustomerVisible};

                        my $PreparedValue = $Self->_GetPrepareDynamicFieldValue(
                            Config => $DynamicFieldConfig,
                            Value  => $ContactData{$Attribute}
                        );

                        if (IsHashRefWithData($PreparedValue)) {
                            push(@DynamicFields, $PreparedValue);
                        }
                    }
                    delete $ContactData{$Attribute};
                }
                next ATTRIBUTE;
            }
        }

        # add dynamic fields array into 'DynamicFields' hash key if any
        if (@DynamicFields) {
            $ContactData{DynamicFields} = \@DynamicFields;
        }
        else {
            $ContactData{DynamicFields} = [];
        }
    }

    # filter valid attributes
    if ( IsHashRefWithData($Self->{Config}->{AttributeWhitelist}) ) {
        foreach my $Attr (sort keys %ContactData) {
            delete $ContactData{$Attr} if !$Self->{Config}->{AttributeWhitelist}->{$Attr};
        }
    }

    # filter valid attributes
    if ( IsHashRefWithData($Self->{Config}->{AttributeBlacklist}) ) {
        foreach my $Attr (sort keys %ContactData) {
            delete $ContactData{$Attr} if $Self->{Config}->{AttributeBlacklist}->{$Attr};
        }
    }

    # include TicketStats if requested
    if ( $Param{Data}->{include}->{TicketStats} ) {
        # execute ticket searches
        my %TicketStats;
        # new tickets
        $TicketStats{NewCount} = $Kernel::OM->Get('Ticket')->TicketSearch(
            Search => {
                AND => [
                    {
                        Field    => 'ContactID',
                        Operator => 'EQ',
                        Value    => $ContactID,
                    },
                    {
                        Field    => 'StateType',
                        Operator => 'EQ',
                        Value    => 'new',
                    },
                ]
            },
            UserID => $Self->{Authorization}->{UserID},
            Result => 'COUNT',
        );
        # open tickets
        $TicketStats{OpenCount} = $Kernel::OM->Get('Ticket')->TicketSearch(
            Search => {
                AND => [
                    {
                        Field    => 'ContactID',
                        Operator => 'EQ',
                        Value    => $ContactID,
                    },
                    {
                        Field    => 'StateType',
                        Operator => 'EQ',
                        Value    => 'open',
                    },
                ]
            },
            UserID => $Self->{Authorization}->{UserID},
            Result => 'COUNT',
        );
        # pending tickets
        $TicketStats{PendingReminderCount} = $Kernel::OM->Get('Ticket')->TicketSearch(
            Search => {
                AND => [
                    {
                        Field    => 'ContactID',
                        Operator => 'EQ',
                        Value    => $ContactID,
                    },
                    {
                        Field    => 'StateType',
                        Operator => 'EQ',
                        Value    => 'pending reminder',
                    },
                ]
            },
            UserID => $Self->{Authorization}->{UserID},
            Result => 'COUNT',
        );

        $ContactData{TicketStats} = \%TicketStats;

        # inform API caching about a new dependency
        $Self->AddCacheDependency(Type => 'Ticket');
        $Self->AddCacheDependency(Type => 'User');
    }

    # include assigned user if requested (and existing)

    #FIXME: workaround KIX2018-3308####################
    $Self->AddCacheDependency(Type => 'User');
    my $UserData;
    if ($ContactData{AssignedUserID}) {
        $UserData = $Self->ExecOperation(
            OperationType => 'V1::User::UserGet',
            Data          => {
                UserID => $ContactData{AssignedUserID},
            }
        );
    }
    $ContactData{Login} = ($UserData && $UserData->{Success}) ? $UserData->{Data}->{User}->{UserLogin} : undef;
    #######################

    #comment back in when 3308 is resolved properly
    if ($Param{Data}->{include}->{User}) {
        # $Self->AddCacheDependency( Type => 'User' );
        # $ContactData{User} = undef;
        # if ($ContactData{AssignedUserID}) {
        #     my $UserData = $Self->ExecOperation(
        #         OperationType => 'V1::User::UserGet',
        #         Data          => {
        #             UserID => $ContactData{AssignedUserID},
        #         }
        #     );
            $ContactData{User} = ($UserData->{Success}) ? $UserData->{Data}->{User} : undef;
        # }
    }

    # include assigned config items if requested
    if ( $Param{Data}->{include}->{AssignedConfigItems} ) {

        # add user data for
        my %CIContact = %ContactData;
        if (!$CIContact{User} && $CIContact{AssignedUserID}) {
            my $UserData = $Self->ExecOperation(
                OperationType => 'V1::User::UserGet',
                Data          => {
                    UserID => $CIContact{AssignedUserID},
                }
            );
            $CIContact{User} = ($UserData->{Success}) ? $UserData->{Data}->{User} : undef;
            $Self->AddCacheDependency(Type => 'User');
        }

        my $ItemIDs = $Kernel::OM->Get('ITSMConfigItem')->GetAssignedConfigItemsForObject(
            ObjectType => 'Contact',
            Object     => \%CIContact
        );

        # filter for customer assigned config items if necessary
        my @ConfigItemIDList = $Self->_FilterCustomerUserVisibleObjectIds(
            ObjectType   => 'ConfigItem',
            ObjectIDList => $ItemIDs
        );

        $ContactData{AssignedConfigItems} = \@ConfigItemIDList;

        $Self->AddCacheDependency(Type => 'ITSMConfigurationManagement');
    }

    # delete the UserID in %ContactData, because it's some backwards compatibility fix (KIX2018-2515) masking the
    # the contact ID as the user ID and should not be delivered through the API to the client.
    delete($ContactData{UserID});

    #always delete the User ID of the assigned User. If user information is requested, the assigned User Object is
    # included.
    #delete($ContactData{AssignedUserID});

    return \%ContactData;
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
