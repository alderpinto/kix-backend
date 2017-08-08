# Change log of KIX
* Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de/
* $Id$

#17.1.1 (2017/08/??)
 * (2017/08/04) - Bugfix: T2017062790001069 (DB migration script exits with error if some object already exists) (rbo)
 * (2017/08/02) - Bugfix: T2017062690000802 (some log messages when migrating from OTRS to KIX and using PostgreSQL) (rbo)
 * (2017/08/02) - Bugfix: T2017071390000718 (UserIsGroup array not filled if swicht button used) (ddoerffel)
 * (2017/08/02) - Bugfix: T2017051890000561 (database tables missing after migrating from plain OTRS - added more information to MIGRATING_OTRS.md) (rbo)
 * (2017/08/02) - Bugfix: T2017062990000842 ('modernize' causes unwanted focus on first select in CI link graph linking dialogs) (rkaiser)
 * (2017/08/02) - Bugfix: T2016122190003121 (OTRS-Bug: Missing header and footer after file upload in CustomerTicketProcess) (ddoerffel)
 * (2017/08/01) - Bugfix: T2016121290000597 (OTRS-Bug: Moving ticket to disabled queue causes corrupted layout) (ddoerffel)
 * (2017/08/01) - Bugfix: T2016120590000511 (misspelling in config item attribute) (ddoerffel)
 * (2017/08/01) - Bugfix: T2015111290000653 (pending time should be shown below ticket state in ticket info sidebar) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017071290001022 (SysConfigLog causes internal server error) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017051890001079 (Usability-CR: make process information sidebar translatable) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017060790001123 (SysConfig group names adapted) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017032090001103 (OTRS-Bug: AdminCustomerCompany allows only one customer company backend) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017032090001103 (OTRS-Bug: In agent ticket search, profile field is not modernise) (ddoerffel)
 * (2017/08/01) - Bugfix: T2016121290000364 (OTRS-Bug: Notifications tag CUSTOMER_FROM gets replaced by CUSTOMER_REALNAME) (ddoerffel)
 * (2017/08/01) - Bugfix: T2016053090000647 (log error if no queues selected in myQueues) (ddoerffel)
 * (2017/08/01) - Bugfix: T2017042590000899 (double items in link object dialog) (ddoerffel)
 * (2017/07/28) - Bugfix: T2017032090001176 (fixed glitch in maximized ckeditor) (uboehm)
 * (2017/07/27) - Bugfix: T2017071290001031 (fixed userinfo styling error in mobile frontend) (uboehm)
 * (2017/07/20) - Bugfix: T2017072090003471 (missing functionality to update DB structures and data during updates) (rbo)
 * (2017/07/18) - Bugfix: T2017071090001384 (fixed double encoding of sidebar search parameters) (millinger)
 * (2017/07/11) - Bugfix: T2017052290000615 (ticket merge possible if full ticketnumber is used although corresponding ticket should not be merged with) (rkaiser)
 * (2017/07/07) - Bugfix: T2017063090000741 (wrong numbers in config item overview if also postproductive CIs should be shown) (rkaiser)
 * (2017/07/07) - Bugfix: T2017032890001429 (fixed modernized offset for responsive view) (uboehm)
 * (2017/07/07) - Bugfix: T2017060790000919 (removed comments from class definitions) (ddoerffel)

#17.1.0 (2017/06/24)
 * (2017/06/21) - Bugfix: T2017052990003305 (show pin for fixed value only on selections or multiselections) (ddoerffel)
 * (2017/06/20) - Bugfix: T2017060890000793 (PostMaster ExtendedFollowUp overwrites existing reference) (millinger)
 * (2017/06/20) - Bugfix: T2017061290000892 (article move does not work) (ddoerffel)
 * (2017/06/20) - CR: T2017021590001188 (added response data for generic interface invoker) (ddoerffel)
 * (2017/06/15) - CR: T2017011290000436 (new article for customer notification events can be marked as seen for all agents by default) (rkaiser)
 * (2017/06/14) - CR: T2017032490000482 (Implemented handling of internal emails and multiple ticket followups) (millinger)
 * (2017/06/14) - Bugfix: T2017061490000727 (AgentTicketEmailOutbound did not check local email without dynamic field) (millinger)
 * (2017/06/12) - CR: T2017051690000949 (Agent-, Customer-, PublicTicketZoom changed html header title) (uboehm)
 * (2017/06/08) - Bugfix: T2014112690000629 (fixed ci image scaling and size) (uboehm)
 * (2017/06/07) - CR: T2017032490000491 (possibility to set caller/callee in AgentTicketPhone(Out/In)bound) (rkaiser)
 * (2017/06/02) - CR: T2017031090000543 (add separated rights management for edit options) (ddoerffel)
 * (2017/06/02) - CR: T2017042090000648 (article edit for all tickets) (ddoerffel)
 * (2017/06/02) - Bugfix: T2017060290000741 (typo in Ticket::Frontend::AgentTicketZoomTabArticle###ArticleEmailActions) (ddoerffel)
 * (2017/06/02) - Bugfix: T2017060190000742 (old AgentArticleCopyMove content removed) (ddoerffel)
 * (2017/05/29) - Bugfix: T2017051890000696 (corrected quoting in SidebarTools) (millinger)
 * (2017/05/23) - CR: T2017013190000883 (Implemented handling of DynamicField Attachment for NotificationEvent) (millinger)

#17.0.1 (2017/05/29)
 * (2017/05/23) - Bugfix: T2017051990000685 (<span> added to customer ticket zoom sidebar info for responsible and owner) (ddoerffel)
 * (2017/05/22) - Bugfix: T2017051990001121 (customer portal group changes sort order every time on reload) (ddoerffel)
 * (2017/05/22) - Bugfix: T2017052290001043 (toolbar toggle multiple registered on ticket or config item zoom (using tabs)) (ddoerffel)
 * (2017/05/22) - Bugfix: T2017051990001111 (uninitialized value on selecting value in multiselect input fields using process ticket) (ddoerffel)
 * (2017/05/22) - Bugfix: T2017030190001265 (param 'disabled' sometimes ignored in BuildDateSelection) (ddoerffel)
 * (2017/05/18) - Bugfix: T2017032790000824 (added SessionParam to queue link in AgentTicketZoom) (uboehm)
 * (2017/05/18) - Bugfix: T2017051590000978 (fixed optical glitch in widget header) (uboehm)
 * (2017/05/17) - Bugfix: T2016052790000626 (corrected recipient 'LinkedPerson' to 'LinkedPersonAgent') (millinger)
 * (2017/05/15) - Bugfix: T2017051590000709 (layout adaptations for process management) (ddoerffel)
 * (2017/05/12) - Bugfix: T2017040590001407 (added missing check for MaxArraySize is reached, then input field hide) (fjacquemin)
 * (2017/05/11) - Bugfix: T2017041290001475 (fixed layout glitch in ticket link dialog) (uboehm)
 * (2017/05/11) - Bugfix: T2016121990002448 (article content always shown as html code in faq view) (ddoerffel)
 * (2017/05/11) - Bugfix: T2016040790000559 (translation error "This user is currently offline" removed) (ddoerffel)
 * (2017/05/10) - Bugfix: T2017021590001081 (added AutoToggleSidebars() to GetCustomerInfo()) (uboehm)
 * (2017/05/10) - Bugfix: T2017042490001391 (removed configuration RegistrationUpdateSend) (fjacquemin)
 * (2017/05/10) - Bugfix: T2017041890000741 (fixed SQL-statements in CustomerDashboardRemoteDBAJAXHandler) (fjacquemin)
 * (2017/05/10) - Bugfix: T2017050590000488 (TypeTranslation not working in customer frontend ticket search) (ddoerffel)
 * (2017/05/10) - Bugfix: T2017032190000728 (outout filter for faq options destroys customized form layout) (ddoerffel)
 * (2017/05/10) - Bugfix: T2016110390000623 (customize form not working with date and time fields) (ddoerffel)
 * (2017/05/10) - Bugfix: T2017032190001512 (autosearch does not work in CustomerSearch) (ddoerffel)
 * (2017/05/09) - Bugfix: T2017031490000849 (removed unnecessary "TypeAhead" sysconfig keys and use in output modules) (rkaiser)
 * (2017/05/09) - Bugfix: T2017042690001181 (email header not possible for postmaster filter) (rkaiser)
 * (2017/05/09) - Bugfix: T2017042690001092 (changed checking of element list over console command) (fjacquemin)
 * (2017/05/09) - Bugfix: T2017031390000565 (Added overwriting the FormID of inline images from templates) (fjacquemin)
 * (2017/05/09) - Bugfix: T2017042590001067 (article seen flag not removed on process ticket) (ddoerffel)
 * (2017/05/09) - Bugfix: T2016121690000661 (filter not submitted on queue change in queue tree) (ddoerffel)
 * (2017/05/08) - Bugfix: T2017041890001197 (AgentTicketForward with attachment rejects dynamic fields) (ddoerffel)
 * (2017/05/08) - Bugfix: T2017040590001327 (empty sla selection in customer frontend and wrong selectable services in agent frontend) (rkaiser)
 * (2017/05/08) - Bugfix: T2017042090001085 (fixed a resulting bug because CallingAction was moved) (rkaiser)
 * (2017/05/08) - Bugfix: T2017042590001487 (added FormID as TargetKey for customer LinkedCI) (fjacquemin)
 * (2017/05/08) - CR: T2017011290000418 (article widget expanded even without mandatory note field) (uboehm)
 * (2017/05/05) - Bugfix: T2017041390000661 (log error on customer preferences change) (ddoerffel)
 * (2017/05/05) - Bugfix: T2017041190000683 (dashboard ticket overview without refresh) (ddoerffel)
 * (2017/05/04) - Bugfix: T2016121690000688 (default preferences for ticket view not set) (ddoerffel)
 * (2017/05/04) - Bugfix: T2017032890001287 (added testing the documents on readability at linking) (fjacquemin)
 * (2017/05/04) - Bugfix: T2017032490000857 (added pipe after last actions menu element to prevent sub menu glitches) (uboehm)
 * (2017/05/02) - Bugfix: T2017042790000804 (some KIX --> OTRS replacements missing in generic interface) (rkaiser)
 * (2017/05/02) - Bugfix: T2017041990000963 (added testing of X-KIX-Queue and X-OTRS-Queue placeholders) (fjacquemin)
 * (2017/04/27) - Bugfix: T2017042090001085 (placeholder in customer attributes are not replaced with ticket data in customer info sidebar) (rkaiser)
 * (2017/04/24) - Bugfix: T2017041290001457 (state not shown in preview ticket lists) (ddoerffel)
 * (2017/04/20) - Bugfix: T2017031090000909 (article dynamic fields not considered in search template dashlets) (ddoerffel)
 * (2017/04/12) - Bugfix: T2015112390000507 (datepicker doesnt open after second tab load in agent ticket zoom) (millinger)
 * (2017/04/20) - Bugfix: T2017030690001051 (graph - show notice if too many nodes (>100) are involved to prevent a timeout) (rkaiser)
 * (2017/04/10) - Bugfix: T2017040390000573 (fixed zero-length name for entry on unpack a downloaded zip) (fjacquemin)

#17.0.0 (2017/04/04)
 * first productive release
 * (2017/04/06) - CR: T2016121190001552 (code merge of all packages and changes for KIX 2017 - copyright header) (ddoerffel)
 * (2017/04/03) - Bugfix: T2017011190000509 (fragmentary lists in config item overview if CI attribute 'CIGroupAccess' is used) (rkaiser)

#16.99.81 (2017/04/03)
 * (2017/04/02) - Bug: T2017033190000852 (deep recursion on subroutine if db-connect fails) (ddoerffel)
 * (2017/03/31) - CR: T2016121190001552 (optimized migration scripts from OTRS and KIX 2016) (rbo)
 * (2017/03/30) - Bugfix: T2017033090000738 (dashlet for offline users shows online users too) (ddoerffel)
 * (2017/03/29) - Bugfix: T2017032890001465 (wrong spelled German translation for 'Followed Link-Types') (rkaiser)
 * (2017/03/29) - CR: T2016121190001552 (code merge of all packages and changes for KIX 2017 - normalized comments in database insert) (millinger)
 * (2017/03/29) - Bugfix: T2017030390001234 (depending dynamic fields could not be deleted) (ddoerffel)
 * (2017/03/24) - Bugfix: T2017030690001014 (placeholder for dynamic field values provided key for object references) (millinger)
 * (2017/03/02) - Bugfix: T2017032190000782 (missing translation for "Edit|Copy|Move|Delete Article") (rkaiser)
 * (2017/03/20) - Bugfix: T2017032090001309 (article flag search form field not modernized) (ddoerffel)
 * (2017/03/20) - Bugfix: T2017032090001452 (missing object in customer remote db ajax handler) (ddoerffel)
 * (2017/03/20) - CR: T2016121190001552 (code merge of all packages and changes for KIX 2017) (millinger)
 * (2017/03/20) - CR: T2016121190001552 (added KIX_ placeholders with fallback - missing fallback in ticket templates) (rbo)

#16.99.80 (2017/03/19)
 * (2017/03/17) - Bugfix: T2017031790001119 (dynamic field filter hash could be undefined) (ddoerffel)
 * (2017/03/16) - Bugfix: T2017021790000729 (fixed initial date for pending time) (millinger)
 * (2017/03/16) - Bugfix: T2017031690001166 (moved output filter to correct folder) (millinger)
 * (2017/03/16) - Bugfix: T2017031490001179 (fixed datepicker for AgentStatistics) (millinger)
 * (2017/03/14) - Bugfix: T2017031490001526 (charts not shown in CIC) (ddoerffel)
 * (2017/03/14) - Bugfix: T2016102890001319 (fixed behaviour of text module tree in sidebar) (millinger)
 * (2017/03/13) - Bugfix: T2017013090001044 (malformed url for deleting text module categories and dependings dynamic fields) (millinger)
 * (2017/03/13) - Bugfix: T2016113090000921 (methods TicketCriticalityStringGet and TicketImpactStringGet used obsolete field names) (millinger)
 * (2017/03/13) - Bugfix: T2016020490001227 (generic ticket dashlet shows wrong ticket count for filters with search templates) (millinger)
 * (2017/03/13) - Bugfix: T2016100790000538 (fixed priority colors in customer frontend) (uboehm)
 * (2017/03/10) - Bugfix: T2017021690000589 (if 3rdParty contact should be notified, customer receives linked person notification too) (rbo)
 * (2017/03/10) - Bugfix: T2016052690001761 (virtual queues only working in treeview) (millinger)
 * (2017/03/08) - Bugfix: T2017030290000559 (fixed customer frontend dropdown, hover and focus color) (uboehm)
 * (2017/03/08) - Bugfix: T2017011790000614 (removed copyrights from console command description) (millinger)
 * (2017/03/03) - Bugfix: T2017022790000648 (possible value checks fails without constrictions in search) (millinger)
 * (2017/03/03) - CR: T2016121190001552 (replaced X-OTRS-Headers with X-KIX-Headers with fallback) (rbo)
 * (2017/03/03) - Bugfix: T2017030290001076 (wrong text for ticket pending time search form) (ddoerffel)
 * (2017/03/03) - Bugfix: T2017021790000783 (activate the modernized feature for hidden form elements) (ddoerffel)
 * (2017/03/02) - CR: T2017030290000755 (user preference for position of toolbar - right, left, top) (rbo)
 * (2017/03/02) - Bugfix: T2016102790000714 (fixed color for oldest queue in queue tree) (uboehm)
 * (2017/03/02) - Bugfix: T2017020890000746 (wrong search profile evaluation for virtual queues and dashboard search templates) (ddoerffel)
 * (2017/03/02) - Bugfix: T2017022190001078 (linked object tables not dragable) (ddoerffel)
 * (2017/03/02) - Bugfix: T2017022190000739 (ticket creation in customer frontend not working if customize form is used) (rkaiser)
 * (2017/03/02) - Bugfix: T2017030290000577 (hard coded tab count removed in AgentTicketZoom) (ddoerffel)
 * (2017/03/01) - Bugfix: T2016122190003148 (fix responsive layout) (uboehm)
 * (2017/02/28) - Bugfix: T2017022790001236 (fixed vulnerability "possible cross-site scripting in parameter SelectedTab") (rbo)
 * (2017/02/28) - CR: T2016102690000501 (Updated BPMX files in KIX to the released version 5.0.3) (fjacquemin)
 * (2017/02/24) - CR: T2017022490001394 (better visualization of ticket locked message in case of RequiredLock) (rbo)
 * (2017/02/23) - CR: T2016121190001552 (added KIX_ placeholders with fallback) (rbo)
 * (2017/02/21) - Bugfix: T2017013190001542 (dynamic fields not shown in AgentTicketMove) (ddoerffel)
 * (2017/02/21) - Bugfix: T2017020190001472 (log error if an option in a specific sysconfig group is changed) (rkaiser)
 * (2017/02/21) - Bugfix: T2017021090001026 (dynamic fields not hidden on init in customer frontend) (ddoerffel)
 * (2017/02/20) - Bugfix: T2017020190001409 (hidden dynamic fields not shown again) (ddoerffel)
 * (2017/02/16) - Bugfix: T2017021390000709 (article header reformatted) (uboehm)
 * (2017/02/15) - Bugfix: T2017021490000841 (.MessageBox.Notice reformatted) (uboehm)
 * (2017/02/15) - Bugfix: T2017021090000545 (missing config object in CustomerUser/DB.pm) (ddoerffel)
 * (2017/02/14) - Bugfix: T2017021290000532 (Error log if ItemId is not provided for LayoutCIClassReference-method InputCreate) (millinger)
 * (2017/02/14) - Bugfix: T2017021290000541 (LayoutCIClassReference doesn't provide ItemId for InputCreate on SearchInputCreate) (millinger)
 * (2017/02/07) - Bugfix: T2017020190000821 (missing object in customer remote db ajax handler) (ddoerffel)
 * (2017/02/13) - Bugfix: T2016102090001575 (skins in custom packages are ignored) (rkaiser)
 * (2017/02/10) - CR: T2017020290001194 (changed 'customer user' to 'contact' and only translation for 'owner') (rkaiser)
 * (2017/02/07) - Bugfix: T2017011190000661 (unnecessary requests delay form input for DynamicFieldRemoteDB and DynamicFieldITSMConfigItem) (millinger)
 * (2017/02/07) - Bugfix: T2017013190000712 (missing handling of CustomerIDRaw in Kernel::System::CustomerUser::DB::CustomerSearch) (rkaiser)
 * (2017/01/31) - Bugfix: T2017012490000913 (missing empty state value in AgentTicketPhoneCommon) (ddoerffel)
 * (2017/01/31) - Bugfix: T2017011290000276 (fixed text label in customer user list) (uboehm)
 * (2017/01/31) - Bugfix: T2017013190000678 (when creating tickets in customer frontend only services for primary CustomerID are available in dropdown) (rbo)
 * (2017/01/31) - Bugfix: T2017011990001057 (use of multiple customer ids could result in wrong customer user list in customer information center) (rkaiser)
 * (2017/01/30) - Bugfix: T2017011090001126 (js-error in CI graph if Loader::Enabled::JS is deactivated) (rkaiser)
 * (2017/01/27) - CR: T2016121190001552 (added migration scripts from OTRS and KIX 2016) (rbo)
 * (2017/01/26) - Bugfix: T2017011790001561 (customer frontend fixed formatting) (uboehm)
 * (2017/01/26) - Bugfix: T2017012490000833 (changed functionality in Core.Agent.HidePendingTimeInput) (fjacquemin)
 * (2017/01/24) - CR: T2016021990000594 (changes for windows installations) (rbo)
 * (2017/01/20) - Bugfix: T2017011190000625 (redundant box in new ticket view in customer frontend) (rkaiser)
 * (2017/01/18) - Bugfix: T2017011190000607 (ConfigItemDelete not possible to use from CI zoom mask) (ddoerffel)
 * (2017/01/18) - Bugfix: T2017011390000391 (wrong column title in config item compare mask) (ddoerffel)
 * (2017/01/02) - CR: T2016122890000451 (added customer ticket template portal) (rbo)
 * (2016/12/23) - CR: T2016121990002948 (address address book functionality) (rbo)
 * (2016/12/06) - CR: T2016121190001552 (code merge of all packages and changes for KIX 2017) (ddoerffel)