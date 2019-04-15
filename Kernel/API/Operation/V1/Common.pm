# --
# Modified version of the work: Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# based on the original work of:
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::API::Operation::V1::Common;

use strict;
use warnings;
use Hash::Flatten;
use Data::Sorting qw(:arrays);

use Kernel::API::Operation;
use Kernel::API::Validator;
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::API::Operation::V1::Common - Base class for all Operations

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut


=item RunOperation()

initialize and run the current operation

    my $Return = $CommonObject->RunOperation(
        Data => {
            ...
        }
    );

    $Return = {
        Success => 1,                       # or 0 in case of failure,
        Code    => 123
        Message => 'Error Message',
        Data => {
            ...
        }
    }

=cut

sub RunOperation {
    my ( $Self, %Param ) = @_;
    my %FilteredPermissionObjects; 

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

    # check user permissions based on property values
    # UserID 1 has God Mode if SecureMode isn't active
    if ( $Self->{Authorization}->{UserID} && ($Kernel::OM->Get('Kernel::Config')->Get('SecureMode') || $Self->{Authorization}->{UserID} != 1) ) {

        my %Permissions = $Kernel::OM->Get('Kernel::System::User')->PermissionList(
            UserID => $Self->{Authorization}->{UserID},
            Types  => [ 'PropertyValue' ],
        );

        foreach my $Permission ( values %Permissions ) {
            # prepare target
            my $Target = $Permission->{Target};
            $Target =~ s/\*/.*?/g;
            $Target =~ s/\//\\\//g;
            $Target =~ s/\{.*?\}$//g;

            # only match the current RequestURI
            next if $Self->{RequestURI} !~ /^$Target$/g;

            next if $Permission->{Target} !~ /^.*?\{(\w+)\.(\w+)\s+(\w+)\s+(.*?)\}$/;

            my ($Object, $Attribute, $Operator, $Value) = ($1, $2, $3, $4);

            $Self->_PermissionDebug(sprintf("found relevant PropertyValue permission on target \"%s\" with value 0x%04x", $Permission->{Target}, $Permission->{Value}));

            if ( $Self->{RequestMethod} =~ /GET|POST/ ) { 
                my $Not = 0;

                # add a NOT filter if we have no READ permission (including DENY)
                $Not = 1 if ( ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{READ}) != Kernel::System::Role::Permission->PERMISSION->{READ} || 
                              ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{DENY}) == Kernel::System::Role::Permission->PERMISSION->{DENY});

                # add a filter accordingly
                my $Result = $Self->AddPermissionFilterForObject(
                    Object    => $Object,
                    Field     => $Attribute,
                    Operator  => $Operator,
                    Value     => $Value,
                    Not       => $Not,
                );
                if ( !$Result->{Success} ) {

                    return $Self->_Error(
                        %{$Result},
                    );
                }

                if ( $Self->{RequestMethod} eq 'POST' ) {
                    # we need some special handling here sind we don't have the object yet to be read
                    # return 403 if we don't have permission to execute this
                    my $PermissionName = Kernel::API::Operation->REQUEST_METHOD_PERMISSION_MAPPING->{$Self->{RequestMethod}};

                    if ( ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{$PermissionName}) != Kernel::System::Role::Permission->PERMISSION->{$PermissionName} || 
                        ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{DENY}) == Kernel::System::Role::Permission->PERMISSION->{DENY}) {

                        my %Data = %{$Param{Data}};
                        
                        # active the permission filters
                        $Self->_ActivatePermissionFilters();

                        # we need to check the object against the filters
                        my $Result = $Self->_ApplyFilter(                   
                            Data               => \%Data,
                            IsPermissionFilter => 1,
                        );

                        # if the filtered object is undef then we don't have permission to create it
                        if ( !$Data{$Object} ) {
                            $Self->_PermissionDebug(sprintf("object to be created matches the permission target --> denying request"));

                            return $Self->_Error(
                                Code => 'Forbidden',
                            );
                        }
                    }
                }

                # save the filtered object for later use
                $FilteredPermissionObjects{$Object} = 1;
            }
            else {                
                # for all other methods we need to get the object with permission filters to check if it matches (use a "faked" ExecOperation)
                my $GetResult = $Self->ExecOperation(
                    RequestMethod => 'GET',
                    OperationType => $Self->{AvailableMethods}->{GET}->{Operation},
                    Data          => $Param{Data}
                );    

                if ( !IsHashRefWithData($GetResult) || !$GetResult->{Success} ) {
                    # no success, simply return what we got
                    return $GetResult;
                }

                # return 403 if we don't have permission to execute this
                my $PermissionName = Kernel::API::Operation->REQUEST_METHOD_PERMISSION_MAPPING->{$Self->{RequestMethod}};

                if ( ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{$PermissionName}) != Kernel::System::Role::Permission->PERMISSION->{$PermissionName} || 
                     ($Permission->{Value} & Kernel::System::Role::Permission->PERMISSION->{DENY}) == Kernel::System::Role::Permission->PERMISSION->{DENY}) {

                    return $Self->_Error(
                        Code => 'Forbidden',
                    );
                }
            }
        }
    }     
    

    # get parameter definitions (if available)
    my $Parameters;
    if ( $Self->can('ParameterDefinition') ) {
        $Parameters = $Self->ParameterDefinition(
            %Param,
        );
    }

    # prepare data
    $Result = $Self->PrepareData(
        Data       => $Param{Data},
        Parameters => $Parameters,
    );

    # check result
    if ( !$Result->{Success} ) {
        return $Self->_Error(
            Code    => 'Operation.PrepareDataError',
            Message => $Result->{Message},
        );
    }

    # check cache if CacheType is set for this operation
    if ( $Kernel::OM->Get('Kernel::Config')->Get('API::Cache') && $Self->{OperationConfig}->{CacheType} ) {
        # add own cache dependencies, if available
        if ( $Self->{OperationConfig}->{CacheTypeDependency} ) {
            $Self->AddCacheDependency(Type => $Self->{OperationConfig}->{CacheTypeDependency});
        }

        my $CacheKey = $Self->_GetCacheKey();

        my $CacheResult = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => $Self->{OperationConfig}->{CacheType},           
            Key  => $CacheKey,
        );

        if ( IsHashRefWithData($CacheResult) ) {
            if ( $Kernel::OM->Get('Kernel::Config')->Get('Cache::Debug') ) {
                $Kernel::OM->Get('Kernel::System::Cache')->_Debug($Self->{LevelIndent}, "return cached response");
            }
            $Self->{'_CachedResponse'} = 1;
            $Result = $Self->_Success(
                %{$CacheResult}
            );
        }
    }

    # run the operation itself if we don't return a cached response
    if ( !$Self->{'_CachedResponse'} ) {
        $Result = $Self->Run(
            %Param,
        );
    }

    # check the result for filtered objects
    if ( $Self->{RequestMethod} eq 'GET' && IsHashRefWithData($Result) && $Result->{Success} && %FilteredPermissionObjects ) {
        foreach my $Object ( keys %FilteredPermissionObjects ) {
            # if the filtered object is undef then we don't have permission to read it
            if ( !$Result->{Data}->{$Object} ) {
                return $Self->_Error(
                    Code => 'Forbidden',
                );
            }
        }
    }

    # log created ID of POST requests
    if ( $Self->{RequestMethod} eq 'POST' && IsHashRefWithData($Result) && $Result->{Success} ) {
        my @Data = %{$Result->{Data}};
        $Self->_Debug($Self->{LevelIndent}, "created new item (".join('=', @Data).")");
    }

    return $Result    
}

=item AddPermissionFilterForObject()

adds a permission filter 

    my $Return = $CommonObject->AddPermissionFilterForObject(
        Object    => 'Ticket',
        Field     => 'QueueID',
        Operator  => 'EQ',
        Value     => 12,
        Not       => 0|1
    );

    $Return = {
        Success => 1,                       # or 0 in case of failure,
        Code    => 123
        Message => 'Error Message',
        Data => {
            ...
        }
    }

=cut

sub AddPermissionFilterForObject {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Object Field Operator Value)) {
        if ( !$Param{$Needed} ) {
            # use Forbidden here to prevent access to data
            return $Self->_Error(
                Code    => 'Forbidden',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    use Data::Dumper;
    $Self->_PermissionDebug("adding permission filter: ".Dumper(\%Param));

    # init PermissionFilters if not done already
    $Self->{PermissionFilters} ||= [];

    # store the required filter information for use in PrepareData
    push(@{$Self->{PermissionFilters}}, { %Param });

    return $Self->_Success();
}

=item Options()

initialize and gather information about the operation

    my $Return = $CommonObject->Options();

    $Return = {
        Success => 1,                       # or 0 in case of failure,
        Code    => 123
        Message => 'Error Message',
        Data => {
            ...
        }
    }

=cut

sub Options {
    my ( $Self, %Param ) = @_;
    my %Data;

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

    # get parameter definitions (if available)
    my $Parameters;
    if ( $Self->can('ParameterDefinition') ) {
        $Parameters = $Self->ParameterDefinition(
            %Param,
        );

        if ( IsHashRefWithData($Parameters) ) {
            # add parameter information to result
            $Data{Parameters} = $Parameters;
        }
    }

    # add the schema if available
    my $SchemaLocation = $Kernel::OM->Get('Kernel::Config')->Get('API::JSONSchema::Location');
    if ( $SchemaLocation && -d $SchemaLocation ) {
        foreach my $Type ( qw(Request Response) ) {
            my $Object = $Self->{OperationConfig}->{$Type.'Object'};
            if ( $Object ) {
                my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
                    Location => "$SchemaLocation/$Object.json",                    
                );
                if ( $Content ) {
                    $Data{$Type}->{JSONSchema} = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                        Data => $$Content
                    );
                }
            }
        }
    }

    # add the example if available
    my $ExampleLocation = $Kernel::OM->Get('Kernel::Config')->Get('API::Example::Location');
    if ( $ExampleLocation && -d $ExampleLocation ) {
        foreach my $Type ( qw(Request Response) ) {
            my $Object = $Self->{OperationConfig}->{$Type.'Object'};
            if ( $Object ) {
                my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
                    Location => "$ExampleLocation/$Object.json",
                );
                if ( $Content ) {
                    $Data{$Type}->{Example} = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                        Data => $$Content
                    );
                }
            }
        }
    }

    return $Self->_Success(
        IsOptionsResponse => 1,
        %Data
    );
}

=item Init()

initialize the operation by checking the webservice configuration

    my $Return = $CommonObject->Init(
        WebserviceID => 1,
    );

    $Return = {
        Success => 1,                       # or 0 in case of failure,
        Message => 'Error Message',
    }

=cut

sub Init {
    my ( $Self, %Param ) = @_;

    # check needed
    if ( !$Param{WebserviceID} ) {
        return $Self->_Error(
            Code    => 'Webservice.InternalError',
            Message => "Got no WebserviceID!",
        );
    }

    # get webservice configuration
    my $Webservice = $Kernel::OM->Get('Kernel::System::API::Webservice')->WebserviceGet(
        ID => $Param{WebserviceID},
    );

    if ( !IsHashRefWithData($Webservice) ) {
        return $Self->_Error(
            Code    => 'Webservice.InternalError',
            Message => 'Could not determine Web service configuration in Kernel::API::Operation::V1::Common::Init()',
        );
    }

    $Self->{CacheKeyExtensions} = [];

    # Search parameter is not handled in API by default
    $Self->{HandleSearchInAPI} = 0;

    # calculate LevelIndent for Logging
    $Self->{Level} = $Self->{Level} || 0;

    $Self->{LevelIndent} = '    ' x $Self->{Level} || '';

    return $Self->_Success();
}

=item PrepareData()

prepare data, check given parameters and parse them according to type

    my $Return = $CommonObject->PrepareData(
        Data   => {
            ...
        },
        Parameters => {
            <Parameter> => {                                            # if Parameter is a attribute of a hashref, just separate it by ::, i.e. "User::UserFirstname"
                Type                => 'ARRAY' | 'ARRAYtoHASH',         # optional, use this to parse a comma separated string into an array or a hash with all array entries as keys and 1 as values
                DataType            => 'NUMERIC',                       # optional, use this to force numeric datatype in JSON response
                Required            => 1,                               # optional
                RequiredIfNot       => [ '<AltParameter>', ... ]        # optional, specify the alternate parameters to be checked, if one of them has a value
                RequiredIf          => [ '<Parameter>', ... ]           # optional, specify the parameters that should be checked for values
                RequiresValueIfUsed => 1                                # optional
                Default             => ...                              # optional
                OneOf               => [...]                            # optional
                Format              => '...'                            # optional, RegEx that defines the format pattern
            }
        }
    );

    $Return = {
        Success => 1,                       # or 0 in case of failure,
        Message => 'Error Message',
    }

=cut

sub PrepareData {
    my ( $Self, %Param ) = @_;
    my $Result = {
        Success => 1
    };

    # check needed stuff
    for my $Needed (qw(Data)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'PrepareData.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    # prepare filter
    if ( exists($Param{Data}->{filter}) ) {
        my $Result = $Self->_ValidateFilter(
            Filter => $Param{Data}->{filter},
            Type   => 'filter',
        );
        if ( IsHashRefWithData($Result) && exists $Result->{Success} && $Result->{Success} == 0 ) {
            # error occured
            return $Result;
        }
        $Self->{Filter} = $Result;
    }

    # prepare search
    if ( exists($Param{Data}->{search}) ) {
        # we use the same syntax like the filter, so we can you the same validation method
        my $Result = $Self->_ValidateFilter(
            Filter => $Param{Data}->{search},
            Type   => 'search',
        );
        if ( IsHashRefWithData($Result) && exists $Result->{Success} && $Result->{Success} == 0 ) {
            # error occured
            return $Result;
        }
        $Self->{Search} = $Result;
    }

    # extend filter and search with permission filters
    if ( IsArrayRefWithData($Self->{PermissionFilters}) ) {
        $Self->_ActivatePermissionFilters();
    }

    # prepare field selector
    if ( (exists($Param{Data}->{fields}) && IsStringWithData($Param{Data}->{fields})) || IsStringWithData($Self->{OperationConfig}->{'FieldSet::Default'}) ) {
        my $FieldSet = $Param{Data}->{fields} || ':Default';
        if ($FieldSet =~ /^:(.*?)/ ) {
            # get pre-defined FieldSet
            $FieldSet = $Self->{OperationConfig}->{'FieldSet:'.$FieldSet};
        }
        foreach my $FieldSelector ( split(/,/, $FieldSet) ) {
            my ($Object, $Field) = split(/\./, $FieldSelector, 2);
            if ($Field =~ /^\[(.*?)\]$/g ) {
                my @Fields = split(/\s*;\s*/, $1);
                $Self->{Fields}->{$Object} = \@Fields;
            }
            else {
                if ( !IsArrayRefWithData($Self->{Fields}->{$Object}) ) {
                    $Self->{Fields}->{$Object} = [];
                }
                push @{$Self->{Fields}->{$Object}}, $Field;
            }
        }
    }
    
    # prepare limiter
    if ( exists($Param{Data}->{limit}) && IsStringWithData($Param{Data}->{limit}) ) {
        foreach my $Limiter ( split(/,/, $Param{Data}->{limit}) ) {
            my ($Object, $Limit) = split(/\:/, $Limiter, 2);
            if ( $Limit && $Limit =~ /\d+/ ) {
               $Self->{Limit}->{$Object} = $Limit;
            }
            else {
                $Self->{Limit}->{__COMMON} = $Object;
            }
        }
    }

    # prepare offset
    if ( exists($Param{Data}->{offset}) && IsStringWithData($Param{Data}->{offset}) ) {
        foreach my $Offset ( split(/,/, $Param{Data}->{offset}) ) {
            my ($Object, $Index) = split(/\:/, $Offset, 2);
            if ( $Index && $Index =~ /\d+/ ) {
               $Self->{Offset}->{$Object} = $Index;
            }
            else {
                $Self->{Offset}->{__COMMON} = $Object;
            }
        }
    }

    # prepare sorter
    if ( exists($Param{Data}->{sort}) && IsStringWithData($Param{Data}->{sort}) ) {
        foreach my $Sorter ( split(/,/, $Param{Data}->{sort}) ) {
            my ($Object, $FieldSort) = split(/\./, $Sorter, 2);
            my ($Field, $Type) = split(/\:/, $FieldSort);
            my $Direction = 'ascending';
            $Type = uc($Type || 'TEXTUAL');

            # check if sort type is valid
            if ( $Type && $Type !~ /(NUMERIC|TEXTUAL|NATURAL|DATE|DATETIME)/g ) {
                return $Self->_Error(
                    Code    => 'PrepareData.InvalidSort',
                    Message => "Unknown type $Type in $Sorter!",
                );                
            }
            
            # should we sort ascending or descending
            if ( $Field =~ /^-(.*?)$/g ) {
                $Field = $1;
                $Direction = 'descending';
            }
            
            if ( !IsArrayRefWithData($Self->{Sorter}->{$Object}) ) {
                $Self->{Sort}->{$Object} = [];
            }
            push @{$Self->{Sort}->{$Object}}, { 
                Field => $Field, 
                Direction => $Direction, 
                Type  => ($Type || 'cmp')
            };
        }
    }

    my %Data = %{$Param{Data}};

    # store data for later use
    $Self->{RequestData} = \%Data;

    # prepare Parameters
    my %Parameters;
    if ( IsHashRefWithData($Param{Parameters}) ) {
        %Parameters = %{$Param{Parameters}};
    }

    # always add include and expand parameter if given
    if ($Param{Data}->{include}) {
        $Parameters{'include'} = {
            Type => 'ARRAYtoHASH',
        };
    }
    if ($Param{Data}->{expand}) {
        $Parameters{'expand'} = {
            Type => 'ARRAYtoHASH',
        };
    }

    # if needed flatten hash structure for easier access to sub structures
    if ( %Parameters ) {

        if ( grep(/::/, keys %Parameters) ) {

            my $FlatData = Hash::Flatten::flatten(
                $Param{Data},
                {
                    HashDelimiter => '::',
                }
            );

            # add pseudo entries for substructures for requirement checking
            foreach my $Entry ( keys %{$FlatData} ) {
                next if $Entry !~ /^.*?::.*?::/g;

                my @Parts = split(/::/, $Entry);
                pop(@Parts);
                my $DummyKey = join('::', @Parts);

                next if exists($FlatData->{$DummyKey});
                $FlatData->{$DummyKey} = {};
            }

            # combine flattened array for requirement checking
            foreach my $Entry ( keys %{$FlatData} ) {
                next if $Entry !~ /^(.*?):\d+/g;

                $FlatData->{$1} = [];
            }

            %Data = (
                %Data,
                %{$FlatData},
            );
        }

        foreach my $Parameter ( sort keys %Parameters ) {

            # check requirement
            if ( $Parameters{$Parameter}->{Required} && !defined($Data{$Parameter}) ) {
                $Result->{Success} = 0;
                $Result->{Message} = "Required parameter $Parameter is missing or undefined!",
                last;
            }
            elsif ( $Parameters{$Parameter}->{RequiredIfNot} && ref($Parameters{$Parameter}->{RequiredIfNot}) eq 'ARRAY' ) {
                my $AltParameterHasValue = 0;
                foreach my $AltParameter ( @{$Parameters{$Parameter}->{RequiredIfNot}} ) {
                    if ( exists($Data{$AltParameter}) && defined($Data{$AltParameter}) ) {
                        $AltParameterHasValue = 1;
                        last;
                    }
                }
                if ( !exists($Data{$Parameter}) && !$AltParameterHasValue ) {
                    $Result->{Success} = 0;
                    $Result->{Message} = "Required parameter $Parameter or ".( join(" or ", @{$Parameters{$Parameter}->{RequiredIfNot}}) )." is missing or undefined!",
                    last;
                }
            }

            # check complex requirement (required if another parameter has value)
            if ( $Parameters{$Parameter}->{RequiredIf} && ref($Parameters{$Parameter}->{RequiredIf}) eq 'ARRAY' ) {
                my $OtherParameterHasValue = 0;
                foreach my $OtherParameter ( @{$Parameters{$Parameter}->{RequiredIf}} ) {
                    if ( exists($Data{$OtherParameter}) && defined($Data{$OtherParameter}) ) {
                        $OtherParameterHasValue = 1;
                        last;
                    }
                }
                if ( !exists($Data{$Parameter}) && $OtherParameterHasValue ) {
                    $Result->{Success} = 0;
                    $Result->{Message} = "Required parameter $Parameter is missing!",
                    last;
                }
            }

            # parse into arrayref if parameter value is scalar and ARRAY type is needed
            if ( $Parameters{$Parameter}->{Type} && $Parameters{$Parameter}->{Type} =~ /(ARRAY|ARRAYtoHASH)/ && $Data{$Parameter} && ref($Data{$Parameter}) ne 'ARRAY' ) {
                my @Values = split('\s*,\s*', $Data{$Parameter});
                if ( $Parameters{$Parameter}->{DataType} && $Parameters{$Parameter}->{DataType} eq 'NUMERIC') {
                    @Values = map { 0 + $_ } @Values;
                }
                $Self->_SetParameter(
                    Data      => $Param{Data},
                    Attribute => $Parameter,
                    Value     => \@Values,                    
                );
            }

            # convert array to hash if we have to 
            if ( $Parameters{$Parameter}->{Type} && $Parameters{$Parameter}->{Type} eq 'ARRAYtoHASH' && $Data{$Parameter} && ref($Param{Data}->{$Parameter}) eq 'ARRAY' ) {
                my %NewHash = map { $_ => 1 } @{$Param{Data}->{$Parameter}};
                $Self->_SetParameter(
                    Data      => $Param{Data},
                    Attribute => $Parameter,
                    Value     => \%NewHash,
                );
            }            

            # set default value
            if ( !$Data{$Parameter} && exists($Parameters{$Parameter}->{Default}) ) {
                $Self->_SetParameter(
                    Data      => $Param{Data},
                    Attribute => $Parameter,
                    Value     => $Parameters{$Parameter}->{Default},
                );
            }

            # check if we have an optional parameter that needs a value
            if ( $Parameters{$Parameter}->{RequiresValueIfUsed} && exists($Data{$Parameter}) && !defined($Data{$Parameter}) ) {
                $Result->{Success} = 0;
                $Result->{Message} = "Optional parameter $Parameter is used without a value!",
                last;
            }

            # check valid values
            if ( exists($Data{$Parameter}) && exists($Parameters{$Parameter}->{OneOf}) && ref($Parameters{$Parameter}->{OneOf}) eq 'ARRAY') {
                if ( !grep(/^$Data{$Parameter}$/g, @{$Parameters{$Parameter}->{OneOf}}) ) {
                    $Result->{Success} = 0;
                    $Result->{Message} = "Parameter $Parameter is not one of '".(join(',', @{$Parameters{$Parameter}->{OneOf}}))."'!",
                    last;
                }
            }
            if ( exists($Data{$Parameter}) && exists($Parameters{$Parameter}->{Format}) ) {
                if ( $Data{$Parameter} !~ /$Parameters{$Parameter}->{Format}/g ) {
                    $Result->{Success} = 0;
                    $Result->{Message} = "Parameter $Parameter has the wrong format!",
                    last;
                }
            }

            # check if we have an optional parameter that needs a value
            if ( $Parameters{$Parameter}->{RequiresValueIfUsed} && exists($Data{$Parameter}) && !defined($Data{$Parameter}) ) {
                $Result->{Success} = 0;
                $Result->{Message} = "Optional parameter $Parameter is used without a value!",
                last;
            }
        }
    }

    # store include and expand for later
    $Self->{Include} = $Param{Data}->{include} || {};
    $Self->{Expand}  = $Param{Data}->{expand} || {};
    
    return $Result; 
}

=item AddCacheDependency()

add a new cache dependency to inform the system about foreign depending objects included in the response

    $CommonObject->AddCacheDependency(
        Type => '...'
    );

=cut

sub AddCacheDependency {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'AddCacheDependency.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    foreach my $Type (split(/,/, $Param{Type})) {
        if ( exists $Self->{CacheDependencies}->{$Type} ) {
            $Self->_Debug($Self->{LevelIndent}, "adding cache type dependencies: $Type...already exists");
            next;
        }
        $Self->_Debug($Self->{LevelIndent}, "adding cache type dependencies: $Type");
        $Self->{CacheDependencies}->{$Type} = 1;
    }
}

=item AddCacheKeyExtension()

add an extension to the cache key used to cache this request

    $CommonObject->AddCacheKeyExtension(
        Extension => []
    );

=cut

sub AddCacheKeyExtension {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Extension)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'AddCacheKeyExtension.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    if ( !IsArrayRefWithData($Param{Extension}) ) {
        return $Self->_Error(
            Code    => 'AddCacheKeyExtension.WringParameter',
            Message => "Extension is not an array reference!",
        );
    }

    foreach my $Extension ( @{$Param{Extension}} ) {
        push(@{$Self->{CacheKeyExtensions}}, $Extension);
    }
}

=item HandleSearchInAPI()

Tell the API core to handle the "search" parameter in the API. This is needed for operations that don't handle the "search" parameter and leave the work to the API core.

    $CommonObject->HandleSearchInAPI();

=cut

sub HandleSearchInAPI {
    my ( $Self, %Param ) = @_;

    $Self->{HandleSearchInAPI} = 1;
}

=item _Success()

helper function to return a successful result.

    my $Return = $CommonObject->_Success(
        ...
    );

=cut

sub _Success {
    my ( $Self, %Param ) = @_;

    # ignore cached calues if we have a cached response (see end of Init method)

    # handle Search parameter if we have to
    if ( !$Param{IsOptionsResponse} ) {
        if ( !$Self->{'_CachedResponse'} && $Self->{HandleSearchInAPI} && IsHashRefWithData($Self->{Search}) ) {
            $Self->_ApplyFilter(
                Data   => \%Param,
                Filter => $Self->{Search}
            );
        }

        # honor a filter, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Filter}) ) {
            $Self->_ApplyFilter(
                Data => \%Param,
            );
        }

        # honor a sorter, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Sort}) ) {
            $Self->_ApplySort(
                Data => \%Param,
            );
        }

        # honor an offset, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Offset}) ) {
            $Self->_ApplyOffset(
                Data => \%Param,
            );
        }

        # honor a limiter, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Limit}) ) {
            $Self->_ApplyLimit(
                Data => \%Param,
            );
        }

        # honor a field selector, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Fields}) ) {
            $Self->_ApplyFieldSelector(
                Data => \%Param,
            );
        }

        # honor a generic include, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Include}) ) {
            $Self->_ApplyInclude(
                Data => \%Param,
            );
        }

        # honor an expander, if we have one
        if ( !$Self->{'_CachedResponse'} && IsHashRefWithData($Self->{Expand}) ) {
            $Self->_ApplyExpand(
                Data => \%Param,
            );
        }

        # honor permission filters
        if ( IsHashRefWithData(\%Param) && IsArrayRefWithData($Self->{PermissionFilters}) ) {
            # in case of a GET request to a collection resource, this should have been done in the filter already
            # but we will make sure nothing gets out that should not and we have to honor item resources as well
            $Self->_ApplyFilter(
                Data               => \%Param,
                IsPermissionFilter => 1,
            );
        }

        # cache request without offset and limit if CacheType is set for this operation
        if ( $Kernel::OM->Get('Kernel::Config')->Get('API::Cache') && !$Self->{'_CachedResponse'} && IsHashRefWithData(\%Param) && $Self->{OperationConfig}->{CacheType} ) {
            $Self->_CacheRequest(
                Data => \%Param,
            );
        }
    }

    # prepare result
    my $Code    = $Param{Code};
    my $Message = $Param{Message};
    delete $Param{Code};
    delete $Param{Message};
    delete $Param{IsOptionsResponse};

    # return structure
    my $Result = {
        Success => 1,
        Code    => $Code,
        Message => $Message,
    };
    if ( IsHashRefWithData(\%Param) ) {
        $Result->{Data} = {
            %Param
        };
    }

    return $Result;
}

=item _Error()

helper function to return an error message.

    my $Return = $CommonObject->_Error(
        Code    => Ticket.AccessDenied,
        Message => 'You don't have rights to access this ticket',
    );

=cut

sub _Error {
    my ( $Self, %Param ) = @_;

    $Self->{DebuggerObject}->Error(
        Summary => $Param{Code},
        Data    => $Param{Message},
    );

    # return structure
    return {
        Success => 0,
        Code    => $Param{Code},
        Message => $Param{Message},
    };
}

=item ExecOperation()

helper function to execute another operation to work with its result.

    my $Return = $CommonObject->ExecOperation(
        OperationType => '...'                              # required
        Data          => {

        }
    );

=cut

sub ExecOperation {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OperationType Data)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => 'ExecOperation.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    # get webservice config
    my $Webservice = $Kernel::OM->Get('Kernel::System::API::Webservice')->WebserviceGet(
        ID => $Self->{WebserviceID},
    );
    if ( !IsHashRefWithData($Webservice) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Could not load web service configuration for web service with ID $Self->{WebserviceID}",
        );

        return $Self->_Error(
            Code    => 'Operation.InternalError',
            Message => "Could not load web service configuration for web service with ID $Self->{WebserviceID}!",
        );
    }
    my $Config = $Webservice->{Config}->{Provider}->{Transport}->{Config};

    # prepare RequestURI
    my $RequestURI = $Config->{RouteOperationMapping}->{$Param{OperationType}}->{Route};
    $RequestURI =~ s/:(\w*)/$Param{Data}->{$1}/egx;

    # determine available methods
    my %AvailableMethods;
    for my $CurrentOperation ( sort keys %{ $Config->{RouteOperationMapping} } ) {

        next if !IsHashRefWithData( $Config->{RouteOperationMapping}->{$CurrentOperation} );

        my %RouteMapping = %{ $Config->{RouteOperationMapping}->{$CurrentOperation} };
        my $RouteRegEx = $RouteMapping{Route};
        $RouteRegEx =~ s{:([^\/]+)}{(?<$1>[^\/]+)}xmsg;

        next if !( $RequestURI =~ m{^ $RouteRegEx $}xms );

        $AvailableMethods{$RouteMapping{RequestMethod}->[0]} = {
            Operation => $CurrentOperation,
            Route     => $RouteMapping{Route}
        };
    }

    # init new Operation object
    my $OperationObject = Kernel::API::Operation->new(
        DebuggerObject          => $Self->{DebuggerObject},
        Operation               => (split(/::/, $Param{OperationType}))[-1],
        OperationType           => $Param{OperationType},
        WebserviceID            => $Self->{WebserviceID},
        RequestMethod           => $Param{RequestMethod} || $Self->{RequestMethod},
        AvailableMethods        => \%AvailableMethods,
        RequestURI              => $RequestURI,
        CurrentRoute            => $Webservice->{Config}->{Provider}->{Transport}->{Config}->{RouteOperationMapping}->{$Param{OperationType}}->{Route},
        OperationRouteMapping   => $Self->{OperationRouteMapping},
        Authorization           => $Self->{Authorization},
        Level                   => $Self->{Level} + 1,
    );

    # if operation init failed, bail out
    if ( ref $OperationObject ne 'Kernel::API::Operation' ) {
        return $Self->_Error(
            %{$OperationObject},
        );
    }

    $Self->_Debug($Self->{LevelIndent}, "executing operation $OperationObject->{OperationConfig}->{Name}");

    my $Result = $OperationObject->Run(
        Data    => {
            %{$Param{Data}},
            include => $Self->{RequestData}->{include},
            expand  => $Self->{RequestData}->{expand},
        }
    );

    # check result and add cachetype if neccessary
    if ( $Result->{Success} && $OperationObject->{OperationConfig}->{CacheType} && $Self->{OperationConfig}->{CacheType}) {
        $Self->AddCacheDependency(Type => $OperationObject->{OperationConfig}->{CacheType});
        if ( IsHashRefWithData($OperationObject->GetCacheDependencies()) ) {
            foreach my $CacheDep ( keys %{$OperationObject->GetCacheDependencies()} ) {
                $Self->AddCacheDependency(Type => $CacheDep);
            }
        }
        if ( $Kernel::OM->Get('Kernel::Config')->Get('API::Debug') ) {
            $Self->_Debug($Self->{LevelIndent},"    cache type $Self->{OperationConfig}->{CacheType} now depends on: ".join(',', keys %{$Self->{CacheDependencies}}));
        }
    }

    return $Result;
}


# BEGIN INTERNAL

sub _ValidateFilter {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !$Param{Filter} ) {
        # nothing to do
        return;
    }    

    my %OperatorTypeMapping = (
        'EQ'         => { 'NUMERIC' => 1, 'STRING'  => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'NE'         => { 'NUMERIC' => 1, 'STRING'  => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'LT'         => { 'NUMERIC' => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'GT'         => { 'NUMERIC' => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'LTE'        => { 'NUMERIC' => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'GTE'        => { 'NUMERIC' => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'IN'         => { 'NUMERIC' => 1, 'STRING'  => 1, 'DATE' => 1, 'DATETIME' => 1 },
        'CONTAINS'   => { 'STRING'  => 1 },
        'STARTSWITH' => { 'STRING'  => 1 },
        'ENDSWITH'   => { 'STRING'  => 1 },
        'LIKE'       => { 'STRING'  => 1 },
    );
    my $ValidOperators = join('|', keys %OperatorTypeMapping);
    my %ValidTypes;
    foreach my $Tmp ( values %OperatorTypeMapping ) {
        foreach my $Type ( keys %{$Tmp} ) { 
            $ValidTypes{$Type} = 1;
        } 
    }

    # if we have been given a perl hash as filter (i.e. when called by ExecOperation), we can use it right away
    my $FilterDef = $Param{Filter};

    # if we have a JSON string, we have to decode it
    if (IsStringWithData($FilterDef)) {
        $FilterDef = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Param{Filter}
        );
    }

    if ( !IsHashRefWithData($FilterDef) ) {
        return $Self->_Error(
            Code    => 'BadRequest',
            Message => "JSON parse error in $Param{Type}!",
        );
    }

    foreach my $Object ( keys %{$FilterDef} ) {
        # do we have a object definition ?
        if ( !IsHashRefWithData($FilterDef->{$Object}) ) {
            return $Self->_Error(
                Code    => 'BadRequest',
                Message => "Invalid $Param{Type} for object $Object!",
            );                
        }

        foreach my $BoolOperator ( keys %{$FilterDef->{$Object}} ) {
            if ( $BoolOperator !~ /^(AND|OR)$/g ) {
                return $Self->_Error(
                    Code    => 'BadRequest',
                    Message => "Invalid $Param{Type} for object $Object!",
                );                
            }

            # do we have a valid boolean operator
            if ( !IsArrayRefWithData($FilterDef->{$Object}->{$BoolOperator}) ) {
                return $Self->_Error(
                    Code    => 'BadRequest',
                    Message => "Invalid $Param{Type} for object $Object!, operator $BoolOperator",
                );                
            }

            # iterate filters
            foreach my $Filter ( @{$FilterDef->{$Object}->{$BoolOperator}} ) {
                $Filter->{Operator} = uc($Filter->{Operator} || '');
                $Filter->{Type} = uc($Filter->{Type} || 'STRING');

                # check if filter field is valid
                if ( !$Filter->{Field} ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "No field in $Object.$Filter->{Field}!",
                    );
                }
                # check if filter Operator is valid
                if ( $Filter->{Operator} !~ /^($ValidOperators)$/g ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "Unknown filter operator $Filter->{Operator} in $Object.$Filter->{Field}!",
                    );
                }
                # check if type is valid
                if ( !$ValidTypes{$Filter->{Type}} ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "Unknown type $Filter->{Type} in $Object.$Filter->{Field}!",
                    );                
                }
                # check if combination of filter Operator and type is valid
                if ( !$OperatorTypeMapping{$Filter->{Operator}}->{$Filter->{Type}} ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "Type $Filter->{Type} not valid for operator $Filter->{Operator} in $Object.$Filter->{Field}!",
                    );                                
                }

                # check DATE value
                if ( $Filter->{Type} eq 'DATE' && $Filter->{Value} !~ /\d{4}-\d{2}-\d{2}/ && $Filter->{Value} !~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/ ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "Invalid date value $Filter->{Value} in $Object.$Filter->{Field}!",
                    );
                }

                # check DATETIME value
                if ( $Filter->{Type} eq 'DATETIME' && $Filter->{Value} !~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/ ) {
                    return $Self->_Error(
                        Code    => 'BadRequest',
                        Message => "Invalid datetime value $Filter->{Value} in $Object.$Filter->{Field}!",
                    );
                }
            }
        }
    }

    return $FilterDef;
}

sub _ApplyFilter {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    my $Filter = $Param{Filter} || $Self->{Filter};

    OBJECT:
    foreach my $Object ( keys %{$Filter} ) {
        my $ObjectData = $Param{Data}->{$Object};

        if ( $Param{IsPermissionFilter} && IsHashRefWithData($Param{Data}->{$Object}) ) {
            # if we do permission filtering and the relevant object is a hashref then its a GET request to an item resource
            # we have to prepare something so the filter can handle it
            # if nothing comes out of the filter, the object can't be read
            $ObjectData = [ $Param{Data}->{$Object} ];
        }
        if ( IsArrayRefWithData($ObjectData) ) {
            # filter each contained hash
            my @FilteredResult;
            
            OBJECTITEM:
            foreach my $ObjectItem ( @{$ObjectData} ) {                
                if ( ref($ObjectItem) eq 'HASH' ) {
                    my $Match = 1;

                    BOOLOPERATOR:
                    foreach my $BoolOperator ( keys %{$Filter->{$Object}} ) {
                        my $BoolOperatorMatch = 1;

                        FILTER:
                        foreach my $FilterItem ( @{$Filter->{$Object}->{$BoolOperator}} ) {
                            my $FilterMatch = 1;

                            # if filter attributes are not contained in the response, check if it references a sub-structure
                            if ( !exists($ObjectItem->{$FilterItem->{Field}}) ) {

                                if ( $FilterItem->{Field} =~ /\./ ) {
                                    # yes it does, filter sub-structure
                                    my ($SubObject, $SubField) = split(/\./, $FilterItem->{Field}, 2);
                                    my $SubData = {
                                        $SubObject => IsArrayRefWithData($ObjectItem->{$SubObject}) ? $ObjectItem->{$SubObject} : [ $ObjectItem->{$SubObject} ]
                                    };
                                    my %SubFilter = %{$FilterItem};
                                    $SubFilter{Field} = $SubField;

                                    # continue if the sub-structure attribute exists
                                    if ( exists($ObjectItem->{$SubObject}) ) {
                                        # execute filter on sub-structure
                                        $Self->_ApplyFilter(
                                            Data => $SubData,
                                            Filter => {
                                                $SubObject => {
                                                    OR => [
                                                        \%SubFilter
                                                    ]
                                                }
                                            }
                                        );

                                        # check filtered SubData
                                        if ( !IsArrayRefWithData($SubData->{$SubObject}) ) {
                                            # the filter didn't match the sub-structure
                                            $FilterMatch = 0;
                                        }
                                    }
                                    else {
                                        # the sub-structure attribute doesn't exist, ignore this item
                                        $FilterMatch = 0;
                                    }
                                }
                                else {
                                    # filtered attribute not found, ignore this item 
                                    $FilterMatch = 0;
                                }
                            }
                            else {
                                my $FieldValue = $ObjectItem->{$FilterItem->{Field}};
                                my $FilterValue = $FilterItem->{Value};
                                my $Type = $FilterItem->{Type} || 'STRING';

                                # check if the value references a field in our hash and take its value in this case
                                if ( $FilterValue && $FilterValue =~ /^\$(.*?)$/ ) {
                                    $FilterValue =  exists($ObjectItem->{$1}) ? $ObjectItem->{$1} : undef;
                                }
                                elsif ( $FilterValue ) {
                                    # replace wildcards with valid RegEx in FilterValue
                                    $FilterValue =~ s/\*/.*?/g;
                                }
                                else {
                                    $FilterValue = undef;
                                }

                                my @FieldValues = ( $FieldValue );
                                if ( IsArrayRefWithData($FieldValue) ) {
                                    @FieldValues = @{$FieldValue}
                                }

                                # handle multiple FieldValues (array)
                                FIELDVALUE:
                                foreach my $FieldValue ( @FieldValues ) {
                                    $FilterMatch = 1;

                                    # prepare date compare
                                    if ( $Type eq 'DATE' ) {
                                        # convert values to unixtime
                                        my ($DatePart, $TimePart) = split(/\s+/, $FieldValue);
                                        $FieldValue = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
                                            String => $DatePart.' 12:00:00',
                                        );
                                        # handle this as a numeric compare
                                        $Type = 'NUMERIC';
                                    }
                                    # prepare datetime compare
                                    elsif ( $Type eq 'DATETIME' ) {
                                        # convert values to unixtime
                                        $FieldValue = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
                                            String => $FieldValue,
                                        );
                                        # handle this as a numeric compare
                                        $Type = 'NUMERIC';
                                    }

                                    # equal (=)
                                    if ( $FilterItem->{Operator} eq 'EQ' ) {
                                        if ( !$FilterValue && $FieldValue ) {
                                            $FilterMatch = 0
                                        }
                                        elsif ( $Type eq 'STRING' && ($FieldValue||'') ne ($FilterValue||'') ) {
                                            $FilterMatch = 0;
                                        }
                                        elsif ( $Type eq 'NUMERIC' && ($FieldValue||'') != ($FilterValue||'') ) {
                                            $FilterMatch = 0;
                                        }                                        
                                    }
                                    # not equal (!=)
                                    elsif ( $FilterItem->{Operator} eq 'NE' ) {                        
                                        if ( !$FilterValue && !$FieldValue ) {
                                            $FilterMatch = 0
                                        }
                                        elsif ( $Type eq 'STRING' && ($FieldValue||'') eq ($FilterValue||'') ) {
                                            $FilterMatch = 0;
                                        }
                                        elsif ( $Type eq 'NUMERIC' && ($FieldValue||'') == ($FilterValue||'') ) {
                                            $FilterMatch = 0;
                                        }                                
                                    }
                                    # less than (<)
                                    elsif ( $FilterItem->{Operator} eq 'LT' ) {                        
                                        if ( $Type eq 'NUMERIC' && $FieldValue >= $FilterValue ) {
                                            $FilterMatch = 0;
                                        }                                
                                    }
                                    # greater than (>)
                                    elsif ( $FilterItem->{Operator} eq 'GT' ) {                        
                                        if ( $Type eq 'NUMERIC' && $FieldValue <= $FilterValue ) {
                                            $FilterMatch = 0;
                                        }                                
                                    }
                                    # less than or equal (<=)
                                    elsif ( $FilterItem->{Operator} eq 'LTE' ) {                        
                                        if ( $Type eq 'NUMERIC' && $FieldValue > $FilterValue ) {
                                            $FilterMatch = 0;
                                        }                                
                                    }
                                    # greater than or equal (>=)
                                    elsif ( $FilterItem->{Operator} eq 'GTE' ) {                        
                                        if ( $Type eq 'NUMERIC' && $FieldValue < $FilterValue ) {
                                            $FilterMatch = 0;
                                        }                                
                                    }
                                    # value is contained in an array or values
                                    elsif ( $FilterItem->{Operator} eq 'IN' ) {
                                        $FilterMatch = 0;
                                        foreach $FilterValue ( @{$FilterValue} ) {
                                            if ( $Type eq 'NUMERIC' ) {                                    
                                                next if $FilterValue != $FieldValue + 0;
                                            }
                                            next if $FilterValue ne $FieldValue;
                                            $FilterMatch = 1;
                                        }
                                    }
                                    # the string contains a part
                                    elsif ( $FilterItem->{Operator} eq 'CONTAINS' ) {               
                                        my $FilterValueQuoted = quotemeta $FilterValue;
                                        if ( $Type eq 'STRING' && $FieldValue !~ /$FilterValueQuoted/ ) {
                                            $FilterMatch = 0;
                                        }
                                    }
                                    # the string starts with the part
                                    elsif ( $FilterItem->{Operator} eq 'STARTSWITH' ) {                        
                                        my $FilterValueQuoted = quotemeta $FilterValue;
                                        if ( $Type eq 'STRING' && $FieldValue !~ /^$FilterValueQuoted/ ) {
                                            $FilterMatch = 0;
                                        }
                                    }
                                    # the string ends with the part
                                    elsif ( $FilterItem->{Operator} eq 'ENDSWITH' ) {                        
                                        my $FilterValueQuoted = quotemeta $FilterValue;
                                        if ( $Type eq 'STRING' && $FieldValue !~ /$FilterValueQuoted$/ ) {
                                            $FilterMatch = 0;
                                        }
                                    }
                                    # the string matches the pattern
                                    elsif ( $FilterItem->{Operator} eq 'LIKE' ) {  
                                        if ( $Type eq 'STRING' && $FieldValue !~ /^$FilterValue$/ig ) {
                                            $FilterMatch = 0;
                                        }
                                    }

                                    last FIELDVALUE if $FilterMatch;
                                }
                            }

                            if ( $FilterItem->{Not} ) {
                                # negate match result
                                $FilterMatch = !$FilterMatch;
                            }

                            # abort filters for this bool operator, if we have a non-match
                            if ( $BoolOperator eq 'AND' && !$FilterMatch ) {
                                # signal the operator that it didn't match
                                $BoolOperatorMatch = 0;
                                last FILTER;
                            }
                            elsif ( $BoolOperator eq 'OR' && $FilterMatch ) {
                                # we don't need to check more filters in this case
                                $BoolOperatorMatch = 1;
                                last FILTER; 
                            }
                            elsif ( $BoolOperator eq 'OR' && !$FilterMatch ) {
                                $BoolOperatorMatch = 0;
                            }                            
                        }

                        # abort filters for this object, if we have a non-match in the operator filters
                        if ( !$BoolOperatorMatch ) {
                            $Match = 0;
                            last BOOLOPERATOR;
                        }
                    }

                    # all filter criteria match, add to result
                    if ( $Match ) {
                        push @FilteredResult, $ObjectItem;
                    }
                }
            }
            if ( $Param{IsPermissionFilter} && IsHashRefWithData($Param{Data}->{$Object}) ) {
                # if we are in the permission filter mode and have prepared something in the beginning, check if we have an item in the filtered result
                # if not, the item cannot be read
                $Param{Data}->{$Object} = $FilteredResult[0];
            }
            else {
                $Param{Data}->{$Object} = \@FilteredResult;
            }
        }
    } 

    return 1;
}

sub _ApplyFieldSelector {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    foreach my $Object ( keys %{$Self->{Fields}} ) {
        if ( ref($Param{Data}->{$Object}) eq 'HASH' ) {
            # extract filtered fields from hash
            my %NewObject;
            foreach my $Field ( (@{$Self->{Fields}->{$Object}}, keys %{$Self->{Include}}) ) {
                if ( $Field eq '*' ) {
                    # include all fields
                    %NewObject = %{$Param{Data}->{$Object}};
                    last;
                }
                else {                    
                    $NewObject{$Field} = $Param{Data}->{$Object}->{$Field};
                }
            }
            $Param{Data}->{$Object} = \%NewObject;
        }
        elsif ( ref($Param{Data}->{$Object}) eq 'ARRAY' ) {
            # filter keys in each contained hash
            foreach my $ObjectItem ( @{$Param{Data}->{$Object}} ) {
                if ( ref($ObjectItem) eq 'HASH' ) {
                    my %NewObjectItem;
                    foreach my $Field ( (@{$Self->{Fields}->{$Object}}, keys %{$Self->{Include}}) ) {
                        if ( $Field eq '*' ) {
                            # include all fields
                            %NewObjectItem = %{$ObjectItem};
                            last;
                        }
                        else {                    
                            $NewObjectItem{$Field} = $ObjectItem->{$Field};
                        }
                    }
                    $ObjectItem = \%NewObjectItem;
                }
            }
        }
    } 

    return 1;
}

sub _ApplyOffset {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    foreach my $Object ( keys %{$Self->{Offset}} ) {
        if ( $Object eq '__COMMON' ) {
            foreach my $DataObject ( keys %{$Param{Data}} ) {
                # ignore the object if we have a specific start index for it
                next if exists($Self->{Offset}->{$DataObject});

                if ( ref($Param{Data}->{$DataObject}) eq 'ARRAY' ) {
                    my @ResultArray = splice @{$Param{Data}->{$DataObject}}, $Self->{Offset}->{$Object};
                    $Param{Data}->{$DataObject} = \@ResultArray;
                }
            }
        }
        elsif ( ref($Param{Data}->{$Object}) eq 'ARRAY' ) {
            my @ResultArray = splice @{$Param{Data}->{$Object}}, $Self->{Offset}->{$Object};
            $Param{$Object} = \@ResultArray;
        }
    } 
}

sub _ApplyLimit {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    foreach my $Object ( keys %{$Self->{Limit}} ) {
        if ( $Object eq '__COMMON' ) {
            foreach my $DataObject ( keys %{$Param{Data}} ) {
                # ignore the object if we have a specific limiter for it
                next if exists($Self->{Limit}->{$DataObject});

                if ( ref($Param{Data}->{$DataObject}) eq 'ARRAY' ) {
                    my @LimitedArray = splice @{$Param{Data}->{$DataObject}}, 0, $Self->{Limit}->{$Object};
                    $Param{Data}->{$DataObject} = \@LimitedArray;
                }
            }
        }
        elsif ( ref($Param{Data}->{$Object}) eq 'ARRAY' ) {
            my @LimitedArray = splice @{$Param{Data}->{$Object}}, 0, $Self->{Limit}->{$Object};
            $Param{$Object} = \@LimitedArray;
        }
    } 
}

sub _ApplySort {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    foreach my $Object ( keys %{$Self->{Sort}} ) {
        if ( ref($Param{Data}->{$Object}) eq 'ARRAY' ) {
            # sort array by given criteria
            my @SortCriteria;
            my %SpecialSort;
            foreach my $Sort ( @{$Self->{Sort}->{$Object}} ) {
                my $SortField = $Sort->{Field};
                my $Type = $Sort->{Type};

                # special handling for DATE and DATETIME sorts
                if ( $Sort->{Type} eq 'DATE' ) {
                    # handle this as a numeric compare
                    $Type = 'NUMERIC';
                    $SortField = $SortField.'_DateSort';
                    $SpecialSort{'_DateSort'} = 1;

                    # convert field values to unixtime
                    foreach my $ObjectItem ( @{$Param{Data}->{$Object}} ) {
                        my ($DatePart, $TimePart) = split(/\s+/, $ObjectItem->{$Sort->{Field}});
                        $ObjectItem->{$SortField} = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
                            String => $DatePart.' 12:00:00',
                        );
                    }
                }
                elsif ( $Sort->{Type} eq 'DATETIME' ) {
                    # handle this as a numeric compare
                    $Type = 'NUMERIC';
                    $SortField = $SortField.'_DateTimeSort';
                    $SpecialSort{'_DateTimeSort'} = 1;

                    # convert field values to unixtime
                    foreach my $ObjectItem ( @{$Param{Data}->{$Object}} ) {
                        $ObjectItem->{$SortField} = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
                            String => $ObjectItem->{$Sort->{Field}},
                        );
                    }
                }

                push @SortCriteria, { 
                    order     => $Sort->{Direction}, 
                    compare   => lc($Type), 
                    sortkey   => $SortField,                    
                };
            }

            my @SortedArray = sorted_arrayref($Param{Data}->{$Object}, @SortCriteria);

            # remove special sort attributes
            if ( %SpecialSort ) {
                SPECIALSORTKEY:
                foreach my $SpecialSortKey ( keys %SpecialSort ) {
                    foreach my $ObjectItem ( @SortedArray ) {
                        last SPECIALSORTKEY if !IsHashRefWithData($ObjectItem);

                        my %NewObjectItem;
                        foreach my $ItemAttribute ( keys %{$ObjectItem}) {
                            if ( $ItemAttribute !~ /.*?$SpecialSortKey$/g ) {
                                $NewObjectItem{$ItemAttribute} = $ObjectItem->{$ItemAttribute};
                            }
                        }

                        $ObjectItem = \%NewObjectItem;                    
                    }
                }
            }

            $Param{Data}->{$Object} = \@SortedArray;
        }
    } 
}

sub _ApplyInclude {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    if ( $ENV{'REQUEST_METHOD'} ne 'GET' || !$Self->{OperationConfig}->{ObjectID} || !$Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}} ) {
        # no GET request or no ObjectID configured or given
        return;
    }

    # check if a given include can be matched to a sub-resource
    if ( IsHashRefWithData($Self->{OperationRouteMapping}) ) {
        my %ReverseOperationRouteMapping = reverse %{$Self->{OperationRouteMapping}};

        foreach my $Include ( keys %{$Self->{Include}} ) {
            next if !$Self->{OperationRouteMapping}->{$Self->{OperationType}};

            my $IncludeOperation = $ReverseOperationRouteMapping{"$Self->{OperationRouteMapping}->{$Self->{OperationType}}/" . lc($Include)};
            next if !$IncludeOperation;

            foreach my $Object ( keys %{$Param{Data}} ) {
                if ( IsArrayRefWithData($Param{Data}->{$Object}) ) {
                    my $Index = 0;
                    foreach my $ObjectID ( split(/\s*,\s*/, $Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}}) ) {
                        # we found a sub-resource include
                        my $Result = $Self->ExecOperation(
                            OperationType => $IncludeOperation,
                            Data          => {
                                %{$Self->{RequestData}},
                                $Self->{OperationConfig}->{ObjectID} => $ObjectID,
                            }
                        );
                        if ( IsHashRefWithData($Result) && $Result->{Success} ) {
                            # get first response object as the include - this is not the perfect solution but it works for the moment
                            $Param{Data}->{$Object}->[$Index++]->{$Include} = $Result->{Data}->{ (keys %{$Result->{Data}})[0] };
                        }
                    }
                }
                else {
                    # we found a sub-resource include
                    my $Result = $Self->ExecOperation(
                        OperationType => $IncludeOperation,
                        Data          => {
                            %{$Self->{RequestData}},
                            $Self->{OperationConfig}->{ObjectID} => $Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}}
                        }
                    );
                    if ( IsHashRefWithData($Result) && $Result->{Success} ) {
                        # get first response object as the include - this is not the perfect solution but it works for the moment
                        $Param{Data}->{$Object}->{$Include} = $Result->{Data}->{(keys %{$Result->{Data}})[0]};
                    }
                }
            }
        }
    }

    # handle generic includes
    my $GenericIncludes = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::GenericInclude');
    if ( IsHashRefWithData($GenericIncludes) ) {
        foreach my $Include ( keys %{$Self->{Include}} ) {
            next if !$GenericIncludes->{$Include};
            next if $Self->{OperationType} =~ /$GenericIncludes->{$Include}->{IgnoreOperationRegEx}/;

            # we've found a requested generic include, now we have to handle it
            my $IncludeHandler = 'Kernel::API::Operation::' . $GenericIncludes->{$Include}->{Module};

            if ( !$Self->{IncludeHandler}->{$IncludeHandler} ) {
                if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($IncludeHandler) ) {

                    return $Self->_Error(
                        Code    => 'Operation.InternalError',
                        Message => "Can't load include handler $IncludeHandler!"
                    );
                }
                $Self->{IncludeHandler}->{$IncludeHandler} = $IncludeHandler->new(
                    %{$Self},
                );
            }

            # if CacheType is set in config of GenericInclude
            if ( defined $GenericIncludes->{$Include}->{CacheType} ) {
                $Self->AddCacheDependency(Type => $GenericIncludes->{$Include}->{CacheType});
                $Self->AddCacheDependency(Type => $GenericIncludes->{$Include}->{CacheTypeDependency});
            }

            $Self->_Debug($Self->{LevelIndent}, "GenericInclude: $Include");

            # do it for every object in the response
            foreach my $Object ( keys %{$Param{Data}} ) {
                if ( IsArrayRefWithData($Param{Data}->{$Object}) ) {

                    my $Index = 0;
                    foreach my $ObjectID ( split(/\s*,\s*/, $Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}}) ) {
                        
                        $Param{Data}->{$Object}->[$Index++]->{$Include} = $Self->{IncludeHandler}->{$IncludeHandler}->Run(
                            OperationConfig => $Self->{OperationConfig},
                            RequestURI      => $Self->{RequestURI},
                            Object          => $Object,
                            ObjectID        => $ObjectID,
                            UserID          => $Self->{Authorization}->{UserID},
                        );

                        # add specific cache dependencies after exec if available
                        if ( $Self->{IncludeHandler}->{$IncludeHandler}->can('GetCacheDependencies') ) {
                            foreach my $CacheDep ( keys %{$Self->{IncludeHandler}->{$IncludeHandler}->GetCacheDependencies()} ) {
                                $Self->{CacheDependencies}->{$CacheDep} = 1;
                            }
                        }
                    }
                }
                else {
                    my $Result = $Self->{IncludeHandler}->{$IncludeHandler}->Run(
                        OperationConfig => $Self->{OperationConfig},
                        RequestURI      => $Self->{RequestURI},
                        Object          => $Object,
                        ObjectID        => $Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}},
                        UserID          => $Self->{Authorization}->{UserID},
                    );

                    if ( $Result ) {
                        $Param{Data}->{$Object}->{$Include} = $Result;

                        # add specific cache dependencies after exec if available
                        if ( $Self->{IncludeHandler}->{$IncludeHandler}->can('GetCacheDependencies') ) {
                            foreach my $CacheDep ( keys %{$Self->{IncludeHandler}->{$IncludeHandler}->GetCacheDependencies()} ) {
                                $Self->{CacheDependencies}->{$CacheDep} = 1;
                            }
                        }
                    }
                }
            }

            if ( $Kernel::OM->Get('Kernel::Config')->Get('Cache::Debug') ) {
                $Kernel::OM->Get('Kernel::System::Cache')->_Debug($Self->{LevelIndent}."    type $Self->{OperationConfig}->{CacheType} has dependencies to: ".join(',', keys %{$Self->{CacheDependencies}}));
            }
        }
    }

    return 1;
}

sub _ApplyExpand {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData(\%Param) || !IsHashRefWithData($Param{Data}) ) {
        # nothing to do
        return;
    }    

    if ( $ENV{'REQUEST_METHOD'} ne 'GET' || !$Self->{OperationConfig}->{ObjectID} || !$Self->{RequestData}->{$Self->{OperationConfig}->{ObjectID}} ) {
        # no GET request or no ObjectID configured or given
        return;
    }

    my $GenericExpands = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::GenericExpand');

    if ( IsHashRefWithData($GenericExpands) ) {
        foreach my $Object ( keys %{$Param{Data}} ) {
            foreach my $AttributeToExpand ( keys %{$Self->{Expand}} ) {
                next if !$GenericExpands->{$Object.'.'.$AttributeToExpand} && !$GenericExpands->{$AttributeToExpand};

                my @ItemList;
                if ( IsArrayRefWithData($Param{Data}->{$Object}) ) {
                    @ItemList = @{$Param{Data}->{$Object}};
                }
                else {
                    @ItemList = ( $Param{Data}->{$Object} );
                }

                foreach my $ItemData ( @ItemList ) {
                    my $Result = $Self->_ExpandObject(
                        AttributeToExpand => $AttributeToExpand,
                        ExpanderConfig    => $GenericExpands->{$Object.'.'.$AttributeToExpand} || $GenericExpands->{$AttributeToExpand},
                        Data              => $ItemData
                    );

                    if ( IsHashRefWithData($Result) && !$Result->{Success} ) {
                        return $Result;
                    }
                }
            }            
        }
    }

    return 1;
}

sub _ActivatePermissionFilters {
    my ( $Self, %Param ) = @_;

    $Self->{PermissionFilters} ||= [];

    use Data::Dumper;
    $Self->_PermissionDebug("activating permission filters: ".Dumper($Self->{PermissionFilters}));
    foreach my $Filter ( @{$Self->{PermissionFilters}} ) {
        # prepare filter definition
        my %FilterDef = (
            Field    => $Filter->{Field},
            Operator => $Filter->{Operator},
            Value    => $Filter->{Value},
            Not      => $Filter->{Not},
        );
        # init filter and search if not done already
        $Self->{Filter}->{$Filter->{Object}}->{AND} ||= [];
        $Self->{Search}->{$Filter->{Object}}->{AND} ||= [];

        # add definition to filters
        push(@{$Self->{Filter}->{$Filter->{Object}}->{AND}}, \%FilterDef);
        push(@{$Self->{Search}->{$Filter->{Object}}->{AND}}, \%FilterDef); 
    }

    $Self->_PermissionDebug("filter after activation of permission filters: ".Dumper($Self->{Filter}));
    $Self->_PermissionDebug("search after activation of permission filters: ".Dumper($Self->{Search}));

    return 1;
}

sub _ExpandObject {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(AttributeToExpand ExpanderConfig Data)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => '_ExpandObject.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }

    my @Data;
    if ( IsArrayRefWithData($Param{Data}->{$Param{AttributeToExpand}}) ) {
        @Data = @{$Param{Data}->{$Param{AttributeToExpand}}};
    }
    elsif ( IsHashRefWithData($Param{Data}->{$Param{AttributeToExpand}}) ) {
        # hashref isn't possible
        return $Self->_Error(
            Code    => 'BadRequest',
            Message => "Expanding a hash is not possible!",
        );
    }
    elsif ( IsStringWithData($Param{Data}->{$Param{AttributeToExpand}}) ) {
        # convert scalar into our data array for further use
        @Data = ( $Param{Data}->{$Param{AttributeToExpand}} );
    }
    else {
        # no data available to expand
        return 1;
    }

    # get primary key for get operation
    my $OperationConfig = $Kernel::OM->Get('Kernel::Config')->Get('API::Operation::Module')->{$Param{ExpanderConfig}->{Operation}};
    if ( !IsHashRefWithData($OperationConfig) ) {
        return $Self->_Error(
            Code    => 'Operation.InternalError',
            Message => "No config for expand operation found!",
        );        
    }
    if ( !$OperationConfig->{ObjectID} ) {
        return $Self->_Error(
            Code    => 'Operation.InternalError',
            Message => "No ObjectID for expand operation configured!",
        );        
    }

    # add primary ObjectID to params
    my %ExecData = (
        "$OperationConfig->{ObjectID}" => join(',', sort @Data)
    );

    if ( $Param{ExpanderConfig}->{AddParams} ) {
        my @AddParams = split(/\s*,\s*/, $Param{ExpanderConfig}->{AddParams});
        foreach my $AddParam ( @AddParams ) {
            my ($TargetAttr, $SourceAttr) = split(/=/, $AddParam);
            # if we don't have a special source attribute, target and source attribute are the same
            if ( !$SourceAttr ) {
                $SourceAttr = $TargetAttr;
            }
            $ExecData{$TargetAttr} = $Param{Data}->{$SourceAttr},
        }
    }

    my $Result = $Self->ExecOperation(
        OperationType => $Param{ExpanderConfig}->{Operation},
        Data          => \%ExecData,
    );
    if ( !IsHashRefWithData($Result) || !$Result->{Success} ) {
        return $Result;
    }

    # extract the relevant data from result
    my $ResultData = $Result->{Data}->{((keys %{$Result->{Data}})[0])};

    if ( ref($Param{Data}->{$Param{AttributeToExpand}}) eq 'ARRAY' ) {
        if ( IsArrayRefWithData($ResultData) ) {
            $Param{Data}->{$Param{AttributeToExpand}} = $ResultData;
        }
        else {
            $Param{Data}->{$Param{AttributeToExpand}} = [ $ResultData ];
        }
    }
    else {
        $Param{Data}->{$Param{AttributeToExpand}} = $ResultData;
    }

    return $Self->_Success();
}

sub _SetParameter {
    my ( $Self, %Param ) = @_;
    
    # check needed stuff
    for my $Needed (qw(Data Attribute)) {
        if ( !$Param{$Needed} ) {
            return $Self->_Error(
                Code    => '_SetParameter.MissingParameter',
                Message => "$Needed parameter is missing!",
            );
        }
    }
    
    my $Value;
    if ( exists($Param{Value}) ) {
        $Value = $Param{Value};
    };
    
    if ($Param{Attribute} =~ /::/) {
        my ($SubKey, $Rest) = split(/::/, $Param{Attribute});
        $Self->_SetParameter(
            Data      => $Param{Data}->{$SubKey},
            Attribute => $Rest,
            Value     => $Param{Value}
        );    
    }
    else {
        $Param{Data}->{$Param{Attribute}} = $Value;
    }
    
    return 1;
}

sub _Trim {
    my ( $Self, %Param ) = @_;

    return if ( !$Param{Data} );

    # remove leading and trailing spaces
    if ( ref($Param{Data}) eq 'HASH' ) {
        foreach my $Attribute ( sort keys %{$Param{Data}} ) {
            $Param{Data}->{$Attribute} = $Self->_Trim(
                Data => $Param{Data}->{$Attribute}
            );
        }
    }
    elsif ( ref($Param{Data}) eq 'ARRAY' ) {
        my $Index = 0;
        foreach my $Attribute ( @{$Param{Data}} ) {
            $Param{Data}->[$Index++] = $Self->_Trim(
                Data => $Attribute
            );
        }
    }
    else {
        #remove leading spaces
        $Param{Data} =~ s{\A\s+}{};

        #remove trailing spaces
        $Param{Data} =~ s{\s+\z}{};
    }

    return $Param{Data};
}

sub _GetCacheKey {
    my ( $Self, %Param ) = @_;

    # generate key without offset
    my %RequestData = %{$Self->{RequestData}};
    delete $RequestData{offset};

    my @CacheKeyParts = qw(limit include expand);
    if ( IsArrayRefWithData($Self->{CacheKeyExtensions}) ) {
        @CacheKeyParts = (
            @CacheKeyParts,
            @{$Self->{CacheKeyExtensions}}
        )
    }

    # sort some things to make sure you always get the same cache key independent of the given order 
    foreach my $What (@CacheKeyParts) {
        next if !$What || !$RequestData{$What};

        my @Parts = split(/,/, $RequestData{$What});
        $RequestData{$What} = join(',', sort @Parts);
    }

    # add UserID to CacheKey if not explicitly disabled
    if ( !$Self->{OperationConfig}->{DisableUserBasedCaching} ) {
        $RequestData{UserID} = $Self->{Authorization}->{UserID};
    }

    my $CacheKey = $Self->{WebserviceID}.'::'.$Self->{OperationType}.'::'.$Kernel::OM->Get('Kernel::System::Main')->Dump(
        \%RequestData,
        'ascii+noindent'
    );

    return $CacheKey;
}

sub _CacheRequest {
    my ( $Self, %Param ) = @_;

    if ( $Param{Data} ) {
        my $CacheKey = $Self->_GetCacheKey();
        my @CacheDependencies;
        if ( IsHashRefWithData($Self->{CacheDependencies}) ) {
            @CacheDependencies = keys %{$Self->{CacheDependencies}};
        }
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type       => $Self->{OperationConfig}->{CacheType},
            Depends    => \@CacheDependencies,
            Category   => 'API',
            Key        => $CacheKey,
            Value      => $Param{Data},
            TTL        => 60 * 60 * 24 * 7,                      # 7 days
        );
    }

    return 1;
}

sub _Debug {
    my ( $Self, $Indent, $Message ) = @_;
    
    return if ( !$Kernel::OM->Get('Kernel::Config')->Get('API::Debug') );

    $Indent ||= '';

    printf STDERR "%10s %s%s: %s\n", "[API]", $Indent, $Self->{OperationConfig}->{Name}, "$Message";
}

sub _PermissionDebug {
    my ( $Self, $Message ) = @_;

    return if ( !$Kernel::OM->Get('Kernel::Config')->Get('Permission::Debug') );

    printf STDERR "%10s %s\n", "[Permission]", $Message;
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
