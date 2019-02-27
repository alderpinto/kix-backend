# --
# Modified version of the work: Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get TranslationLanguage object
my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

########################################################################################################################################
# Pattern handling
########################################################################################################################################

# add pattern
my $Pattern = 'Pattern' . $Helper->GetRandomID();

my $PatternID = $TranslationObject->PatternAdd(
    Value   => $Pattern,
    UserID  => 1,
);

$Self->True(
    $PatternID,
    'PatternAdd()',
);

# add existing pattern
my $PatternIDWrong = $TranslationObject->PatternAdd(
    Value   => $Pattern,
    UserID  => 1,
);

$Self->False(
    $PatternIDWrong,
    'PatternAdd( - Try to add existing pattern',
);

# get the pattern by using the id
my %PatternData = $TranslationObject->PatternGet( ID => $PatternID );

$Self->Is(
    $PatternData{Value} || '',
    $Pattern,
    'PatternGet() - Value (using the pattern id)',
);

# lookup pattern
my $PatternIDExists = $TranslationObject->PatternExistsCheck( Value => $Pattern );

$Self->True(
    $PatternIDExists,
    'PatternExistsCheck() - existing pattern',
);

my $PatternIDNotExists = $TranslationObject->PatternExistsCheck( Value => $Pattern.'notexists' );

$Self->False(
    $PatternIDNotExists,
    'PatternExistsCheck() - non-existing pattern',
);

my %PatternList = $TranslationObject->PatternList();

$Self->True(
    exists $PatternList{$PatternID} && $PatternList{$PatternID} eq $Pattern,
    'PatternList() contains the pattern ' . $Pattern . ' with ID ' . $PatternID,
);

my $PatternUpdate = $Pattern . 'update';
my $Success = $TranslationObject->PatternUpdate(
    ID      => $PatternID,
    Value   => $PatternUpdate,
    UserID  => 1,
);

$Self->True(
    $Success,
    'PatternUpdate()',
);

%PatternData = $TranslationObject->PatternGet( ID => $PatternID );

$Self->Is(
    $PatternData{Value} || '',
    $PatternUpdate,
    'PatternGet() - Value',
);

# add another pattern
my $PatternSecond = $Pattern . 'second';
my $PatternIDSecond   = $TranslationObject->PatternAdd(
    Value   => $PatternSecond,
    UserID  => 1,
);

$Self->True(
    $PatternIDSecond,
    "PatternAdd() - Name: \'$PatternSecond\' ID: \'$PatternIDSecond\'",
);

# update with existing pattern
my $PatternUpdateWrong = $TranslationObject->PatternUpdate(
    ID      => $PatternIDSecond,
    Value   => $PatternUpdate,
    UserID  => 1,
);

$Self->False(
    $PatternUpdateWrong,
    "PatternUpdate() - Try to update the pattern with existing one",
);

# delete second pattern
$Success = $TranslationObject->PatternDelete(
    ID      => $PatternIDSecond,
    UserID  => 1,
);

$Self->True(
    $Success,
    "PatternDelete() - Try to delete the second pattern",
);

%PatternData = $TranslationObject->PatternGet( ID => $PatternIDSecond );

$Self->False(
    $PatternData{ID},
    'PatternGet() - does not return any data for second pattern id',
);

%PatternList = $TranslationObject->PatternList();

$Self->False(
    exists $PatternList{$PatternIDSecond},
    'PatternList() does not contain the deleted pattern',
);

########################################################################################################################################
# TranslationLanguage handling
########################################################################################################################################

# add TranslationLanguage
my %TranslationLanguage = (
    PatternID => $PatternID,
    Language  => 'de',
    Value     => 'TranslationLanguage' . $Helper->GetRandomID(),
);

$Success = $TranslationObject->TranslationLanguageAdd(
    %TranslationLanguage,
    PatternID => $PatternID,
    UserID    => 1,
);

$Self->True(
    $Success,
    'TranslationLanguageAdd()',
);

# add existing TranslationLanguage
$Success = $TranslationObject->TranslationLanguageAdd(
    %TranslationLanguage,
    UserID    => 1,
);

$Self->False(
    $Success,
    'TranslationLanguageAdd() - Try to add existing TranslationLanguage',
);

# add TranslationLanguage with non-existing PatternID
$Success = $TranslationObject->TranslationLanguageAdd(
    UserID    => 1,
    %TranslationLanguage,
    PatternID => 123456789,
);

$Self->False(
    $Success,
    'TranslationLanguageAdd() - Try to add TranslationLanguage with non-existing PatternID',
);


# get the TranslationLanguage using the id
my %TranslationLanguageData = $TranslationObject->TranslationLanguageGet( 
    PatternID => $PatternID,
    Language  => $TranslationLanguage{Language}
);

$Self->Is(
    $TranslationLanguageData{PatternID} || '',
    $TranslationLanguage{PatternID},
    'TranslationLanguageGet() - PatternID (using the TranslationLanguage id)',
);

$Self->Is(
    $TranslationLanguageData{Language} || '',
    $TranslationLanguage{Language},
    'TranslationLanguageGet() - Language (using the TranslationLanguage id)',
);

$Self->Is(
    $TranslationLanguageData{Value} || '',
    $TranslationLanguage{Value},
    'TranslationLanguageGet() - Value (using the TranslationLanguage id)',
);

my %TranslationLanguageList = $TranslationObject->TranslationLanguageList(
    PatternID => $PatternID
);

$Self->True(
    exists $TranslationLanguageList{$TranslationLanguage{Language}} && $TranslationLanguageList{$TranslationLanguage{Language}} eq $TranslationLanguage{Value},
    'TranslationLanguageList() contains the entry ' . $TranslationLanguage{Value} . ' with language ' . $TranslationLanguage{Language},
);

$Success = $TranslationObject->TranslationLanguageUpdate(
    %TranslationLanguage,
    Value   => $TranslationLanguage{Value}.'update',
    UserID  => 1,
);

$Self->True(
    $Success,
    'TranslationLanguageUpdate() - update value',
);

$Success = $TranslationObject->TranslationLanguageUpdate(
    %TranslationLanguage,
    PatternID => 1234567890,
    UserID  => 1,
);

$Self->False(
    $Success,
    'TranslationLanguageUpdate() - update with non-existing PatternID',
);

%TranslationLanguageData = $TranslationObject->TranslationLanguageGet( 
    PatternID => $PatternID,
    Language  => $TranslationLanguage{Language},
);

$Self->Is(
    $TranslationLanguageData{Value} || '',
    $TranslationLanguage{Value}.'update',
    'TranslationLanguageGet() - updated value',
);

# delete TranslationLanguage
$Success = $TranslationObject->TranslationLanguageDelete(
    PatternID => $PatternID,
    Language  => $TranslationLanguage{Language},
    UserID    => 1,
);

$Self->True(
    $Success,
    "TranslationLanguageDelete() - Try to delete the TranslationLanguage",
);

%TranslationLanguageData = $TranslationObject->TranslationLanguageGet( 
    PatternID => $PatternID,
    Language   => $TranslationLanguage{Language},
);

$Self->False(
    $TranslationLanguageData{Language},
    'TranslationLanguageGet() - does not return any data for deleted entry',
);

%TranslationLanguageList = $TranslationObject->TranslationLanguageList(
    PatternID => $PatternID
);

$Self->False(
    exists $TranslationLanguageList{$TranslationLanguage{Value}},
    'TranslationLanguageList() does not contain the deleted TranslationLanguage',
);

# cleanup is done by RestoreDatabase.

1;


=back

=head1 TERMS AND CONDITIONS

This software is part of the KIX project
(L<http://www.kixdesk.com/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file
COPYING for license information (AGPL). If you did not receive this file, see

<http://www.gnu.org/licenses/agpl.txt>.

=cut