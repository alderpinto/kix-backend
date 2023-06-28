# --
# Modified version of the work: Copyright (C) 2006-2023 c.a.p.e. IT GmbH, https://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file LICENSE-AGPL for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::HTMLToPDF::Render;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);

sub Render {
    my ( $Self, %Param ) = @_;

    return q{} if !IsArrayRefWithData($Param{Block});

    my $HasPage = 0;
    my $Output  = q{};
    my $Result  = $Param{Result} || q{};
    my $Object  = $Param{Object};
    my $Css     = q{};
    my $IDKey   = $Param{IDKey} || q{};
    my %Keys;

    if ( $Object ) {
        for my $Key ( qw{IDKey NumberKey} ) {
            if ( $Self->{"Backend$Object"}->{$Key} ) {
                $Keys{$Self->{"Backend$Object"}->{$Key}} = $Param{$Self->{"Backend$Object"}->{$Key}} || q{};
                $Keys{$Key} = $Self->{"Backend$Object"}->{$Key};
            }
        }

        if (
            !$Self->{$Object . 'Data'}
            || (
                $IDKey
                && $Keys{$IDKey}
                && $Self->{$Object . 'Data'}->{$IDKey} ne $Keys{$IDKey}
            )
        ) {
            $Self->{$Object . 'Data'} = $Self->{"Backend$Object"}->DataGet(
                %Keys,
                UserID  => $Param{UserID},
                Expands => $Param{Expands},
                Filters => $Param{Filters},
                Count   => $Param{Count}
            );

            return if !$Self->{$Object . 'Data'};
        }

        for my $Key ( qw{IDKey NumberKey} ) {
            if ( $Self->{"Backend$Object"}->{$Key} ) {
                my $ParamKey = $Self->{"Backend$Object"}->{$Key};
                $Keys{$ParamKey} = $Self->{$Object . 'Data'}->{$ParamKey} || q{};
            }
        }
    }

    my $Datas = $Self->{$Object . 'Data'};
    if ( $Param{Data} ) {
        return q{} if ( !$Datas->{Expands}->{$Param{Data}} );
        $Datas = $Datas->{Expands}->{$Param{Data}};
    }

    for my $Block ( @{$Param{Block}} ) {
        $HasPage = 1 if $Block->{Type} && $Block->{Type} eq 'Page';
        my $Content = q{};
        my $BlockData;
        if ( $Block->{Data} ) {
            next if ( !$Datas->{Expands}->{$Block->{Data}} );
            $BlockData = $Datas->{Expands}->{$Block->{Data}};
        }
        elsif (
            $Block->{Include}
            && $Datas->{Expands}->{$Block->{Include}}
        ) {
            %{$BlockData} = (
                %{$Self->{$Object . 'Data'}},
                %{$Self->{$Object . 'Data'}->{Expands}->{$Block->{Include}}}
            );
        }
        else {
            $BlockData = $Datas;
        }

        if ( $Block->{Blocks} ) {
            if ( !$Block->{ID} ) {
                $Block->{ID} = 'Blocks';
            }
            if (
                $Block->{Type}
                && $Block->{Type} eq 'List'
                && $Block->{Object}
                && $Block->{Data}
            ) {

                my $Count = 0;
                ID:
                for my $ID ( @{$BlockData} ) {
                    $Count++;

                    my %ListKeys;

                    if( $Self->{"Backend$Block->{Object}"}->{IDKey} ) {
                        $ListKeys{$Self->{"Backend$Block->{Object}"}->{IDKey}} = $ID || q{};
                        $ListKeys{IDKey} = $Self->{"Backend$Block->{Object}"}->{IDKey};
                    }

                    my %HTML = $Self->Render(
                        %ListKeys,
                        UserID     => $Param{UserID},
                        Block      => $Block->{Blocks},
                        Result     => 'Content',
                        Object     => $Block->{Object} || $Object,
                        Expands    => $Block->{Expand},
                        Count      => $Count,
                        Filters    => $Param{Filters},
                        Allows     => $Param{Allows},
                        Ignores    => $Param{Ignores}
                    );

                    next ID if !%HTML;

                    $Css     .= $HTML{Css};
                    $Content .= $HTML{HTML};
                }
            }
            else {
                my %HTML = $Self->Render(
                    %Param,
                    Object  => $Block->{Object} || $Object,
                    Data    => $Block->{Data} || q{},
                    Block   => $Block->{Blocks},
                    Result  => 'Content',
                    Filters => $Param{Filters},
                    Allows  => $Param{Allows},
                    Ignores => $Param{Ignores}
                );
                $Css     .= $HTML{Css};
                $Content .= $HTML{HTML};
            }
        }
        elsif ( $Block->{Type} ) {
            my %HTML = $Self->{"Render$Block->{Type}"}->Run(
                %Keys,
                Data    => $BlockData,
                Block   => $Block,
                UserID  => $Param{UserID},
                Count   => $Param{Count},
                Allows  => $Param{Allows},
                Ignores => $Param{Ignores},
                Object  => $Block->{Object} || $Object
            );
            $Css     .= $HTML{Css};
            $Content .= $HTML{HTML};
        }
        $Output .= $Content;
    }

    if ( $Result ne 'Content' ) {

        my $HTML = $Self->{RenderContainer}->Run(
            Data => {
                Value     => $Output,
                CSS       => $Css,
                HasPage   => $HasPage,
                IsContent => $Param{IsContent} || 0,
                %Keys
            }
        );

        # write html to fs
        return $Kernel::OM->Get('Main')->FileWrite(
            Directory  => $Param{Directory},
            Filename   => $Param{Filename} . '.html',
            Content    => \$HTML,
            Mode       => 'binmode',
            Type       => 'Local',
            Permission => '640',
        );

    }

    return (
        Css  => $Css,
        HTML => $Output
    );
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