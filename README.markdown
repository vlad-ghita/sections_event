# Sections Event

This extension bundles an event and corresponding form controls for easier & integrated control of your frontend forms in one place.

If you ever had to submit data from Frontend to more than one section and those sections are linked together through a linking field (eg: SBL/SBL+), you had to customize your event.

Using this approach, you can set those relations right from XSLT and they will be handled on-the-fly thus no more customizations being required.

As of version 2.0, the event supports Create, Edit and Delete actions on entry data. Permissions are handled in-house (@see Managing permissions).



## Change log

For change log see [extension.meta.xml](https://github.com/vlad-ghita/sections_event/blob/master/extension.meta.xml), the `<releases>` node.



## Features:

* __One event to rule them all.__ It takes form data and dispatches the processing for all sections where it should be.
* __On-the-fly variable replacement.__ Any form value can be used as a variable in another value from your form.
* __Up to date form controls.__ More complex fields have arisen lately. `SForm Controls` offer updated and flexible utilities to help with the new fields and challenges.
* __Built in multiple entries support.__ Multiple entries are now supported by default without needing to apply another filter. Using `Section Form Controls`, sending multiple entries at once becomes a breeze.
* __Action permissions.__ Permissions at Section level and Field level based on Member Roles.



## Installation

### Requirements

- PHP 5.3.
- [EXSL Function Manager](http://symphonyextensions.com/extensions/exsl_function_manager/) extension, at least v0.6.
- [Members](http://symphonyextensions.com/extensions/members/) extension, at least v1.2.

Installation as usual.



## Managing permissions

- in administration, navigate to `System -> Section permissions`.
- click the role you want to set permissions for.
- set permissions for each section and for each field in section

### Permissions in XSLT

In order to get permission information in XSLT, you must include the `permissions.xsl` utility found in `utilities` folder.

Here's an example of a full XSL Page for checking permissions:

    <?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:utils="http://exslt.org/utils"
            extension-element-prefixes="utils">
        <!-- Include the "utils" namespace -->

        <!-- Make sure you added `SE : Permissions` data source to your page -->

        <!-- Import `permissions.xsl` utility. Mine resides in utilities folder -->
        <xsl:import href="../utilities/permissions.xsl"/>


        <xsl:output method="xml"
                doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
                doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
                omit-xml-declaration="yes"
                encoding="UTF-8"
                indent="yes"/>



        <xsl:template match="/">
            <xsl:variable name="actions" select="/data/se-permissions/actions"/>

            <!-- Returns 1 if current member can Create entries in Section with ID = 1 -->
            <!-- Returns 0 otherwise -->
            <xsl:value-of select="utils:permCheck('section', 1, $actions/create)"/>

            <xsl:if test="utils:permCheck('field', 72, $actions/view) = 1">
                <p>If current member can View the field with ID = 72, this message is displayed.</p>
            </xsl:if>

            <xsl:if test="utils:permCheck('section', 3, $actions/delete) = 0">
                <p>You are not allowed to delete entries in Section #3.</p>
            </xsl:if>

            <!-- Returns the permission level set for current logged in Role for this Resource for this action -->
            <!--
                0 = NONE
                1 = OWN
                2 = ALL
            -->
            <xsl:value-of select="utils:permGetLevel('section', 3, $actions/edit)"/>
        </xsl:template>


    </xsl:stylesheet>



## Using `Sections` event

- attach `Sections` event to your Pages
- copy `/extensions/sections_event/utilities/sform-controls` folder to `/workspace/utilities/sform-controls`
- import `/utilities/sform-controls/sform-controls.xsl` in your `page.xsl`
- add the `sform` namespace to your `page.xsl` (eg: `xmlns:sform="http://xanderadvertising.com/xslt"`)
- start building forms!
- see example #5 for XSLT copy+paste code in a Page

### Adding filters with the event

**Q:** Ok. So this event will take care of all my section data coming from frontend. What about ETM and other extensions that need filters to function correctly?

**R:** Create a custom event and add your filters where you want them.

Here's an example. You have a `Contact messages` section and an ETM template with handle `new-message-to-admin`. Also, you want to filter data for XSS, right? This is an event that does just that:

    <?php

        require_once(TOOLKIT.'/class.event.php');

        Final Class EventAdd_My_Filters extends Event
        {

            public static function about(){
                return array(
                    'name' => 'Add my filters !!!',
                );
            }

			// we don't want the editor to scramble with this one
            public static function allowEditorToParse(){
                return false;
            }

			// make sure this event runs before Sections Event
            public function priority(){
                return self::kHIGH;
            }

            public function load(){
                // if Sections Event is not triggered, return
                if( !isset($_REQUEST['action']['sections']) ){
                    return;
                }

                // add desired filters
                $_REQUEST['sections']['contact-messages']['__filters'] = array(
                    'xss-fail',
                    // Email Template manager requires the `etm-` prefix in front of template handle
                    'etm-new-message-to-admin'
                );
            }

        }

Copy this code to `/workspace/events/event.add_my_filters.php` file, add Event to Contact Page and ... hmmm, dance!

### For developers

ETM and XSS work b/c I add the glue code in this extension. If you need other extensions to be supported, please ask those developers to support SectionsEvent delegates as well.



## SForm utilities

### Validation

An event in Symphony typically returns a status message regarding event success or failure, error & success status for various filters and only status errors about the fields in the form. The [sform:validation-interpret](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L50) template tries to identify these elements in your event and return a consistent interpretation report about what's going on. Based on this report, you can output your errors automatically using the `sform:validation-render` template or do whatever you please.

Since v2.0, there are two templates for interpreting event results:

- `sform:formi` - must be used for `Sections` event.
- `sform:validation-interpret` - should be used for any other event. This helps with other custom events like the ones from `Members` extension.

Both templates return an interpretation report with same structure.

An interpretation report will have 3 group nodes:

- `entry` - status regarding the entry / event that was processed
- `filters` - status about each filter. Filters are determined by those nodes named `filter` which do not have an `type` attribute
- `fields` - status about every field that was found. Fields are all nodes that have an `type` attribute.

Each group contains `items`. An `item` is made of:

- `handle` attribute - acts as Unique Identifier.
- `status` attribute - informs about the status of this item. It can have two values at the moment: [`$sform:STATUS_SUCCESS`](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L13) and [`$sform:STATUS_ERROR`](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L14).
- `msg` child - contains a user friendly message.
- `original` child - contains the original Symphony data from which this `item` was determined

Here's an example of an event interpretation:

    <entry cnt-success="0" cnt-error="1">
        <item handle="member-login-info" status="error">
            <msg>
                There were errors trying to log you in.
            </msg>
            <original>
                <member-login-info logged-in="no" result="error"></member-login-info>
            </original>
        </item>
    </entry>
    <filters cnt-success="0" cnt-error="1">
		<item handle="etm-members-generate-recovery-code" status="error">
			<msg>
				There was a	problem	sending	your email.	Please inform us at
				<a href="mailto:secretariat@xanderadvertising.com">secretariat@xanderadvertising.com</a>.
			</msg>
			<original>
				<filter	name="etm-members-generate-recovery-code" status="failed">mail() [
					<a href="function.mail">function.mail</a>]:	Failed to connect to mailserver	at "dev_xander" port 25, verify your "SMTP" and "smtp_port" setting in php.ini or use ini_set()
				</filter>
			</original>
		</item>
    </filters>
    <fields cnt-success="0" cnt-error="2">
        <item handle="password" status="error" label="Password">
            <id>
                <prefix>fields</prefix>
                <section></section>
                <position>0</position>
            </id>
            <msg>Password is a required field.</msg>
            <original>
                <password type="missing" message="Password is a required field." label="Password"></password>
            </original>
        </item>
        <item handle="username" status="error" label="Username">
            <id>
                <prefix>fields</prefix>
                <section></section>
                <position>0</position>
            </id>
            <msg>Username is a required field.</msg>
            <original>
                <username type="missing" message="Username is a required field." label="Username"></username>
            </original>
        </item>
    </fields>

### XSL utilities

All utilities use these parameters:

Identification

* `event` (optional, string): The Event powering the form.
* `prefix` (optional, string): The prefix that will hold all form data.
* `section` (optional, string): The section to where data should be sent.
* `position` (optional, string): Index of this entry in a multiple entries situation. Leave empty if not needed.
* `handle` (mandatory, string): Handle of the field.
* `suffix` (optional, string): An xPath like string for more flexibility.

Validation

* `interpretation` (optional, XML): An XML with the validation of the form
* `interpretation-el` (optional, XML): An XML with the validation for this field

Element data

* `value` (optional, string): The value sent when the form is submitted.
* `attributes` (optional, XML): Other attributes for this element.
* `postback-value` (optional, XML): Value to use after form was posted and page reloaded.
* `postback-value-enabled` (optional, boolean): Switcher to enable the display of postback value.



### Examples

#### Example 1. Send data to a `Books` section

    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
    </xsl:call-template>

result:

    <input type="text" value="Encyclopedia" id="sections_books_title" name="sections[books][title]">



#### Example 2. Send multiple entries at once #1

    <!-- Book #0 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
    </xsl:call-template>

    <!-- Book #1 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'XSLT Cookbook'"/>
    </xsl:call-template>

result:

    <input type="text" value="Encyclopedia" id="sections_books_0_title" name="sections[books][0][title]">
    <input type="text" value="XSLT Cookbook" id="sections_books_1_title" name="sections[books][1][title]">



#### Example 3. Send multiple entries at once #2 (one Book is linked to one or more Authors)

    <!-- Author #0 name -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="0"/>
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'John'"/>
    </xsl:call-template>

    <!-- Author #1 name -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="1"/>
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'Mary'"/>
    </xsl:call-template>

    <!-- Author #2 name -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="2"/>
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'Andrew'"/>
    </xsl:call-template>

    <!-- Book #0 title -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
    </xsl:call-template>

	<!-- Book #0 authors -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
        <xsl:with-param name="handle" select="'authors'"/>
        <xsl:with-param name="value">
            <!-- Link to author #1 -->
            <xsl:call-template name="sform:variable">
                <xsl:with-param name="section" select="'authors'"/>
                <xsl:with-param name="position" select="0"/>
                <xsl:with-param name="handle" select="'system:id'"/>
            </xsl:call-template>
            <xsl:text>,</xsl:text>
            <!-- Link to author #3 -->
            <xsl:call-template name="sform:variable">
                <xsl:with-param name="section" select="'authors'"/>
                <xsl:with-param name="position" select="2"/>
                <xsl:with-param name="handle" select="'system:id'"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="attributes">
            <type>hidden</type>
        </xsl:with-param>
    </xsl:call-template>

    <!-- Book #1 title -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'XSLT Cookbook'"/>
    </xsl:call-template>

	<!-- Book #1 authors -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
        <xsl:with-param name="handle" select="'authors'"/>
        <xsl:with-param name="value">
            <!-- Link to author #2. If handle is omitted, it's assumed 'system:id' -->
            <xsl:call-template name="sform:variable">
                <xsl:with-param name="section" select="'authors'"/>
                <xsl:with-param name="position" select="1"/>
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="attributes">
            <type>hidden</type>
        </xsl:with-param>
    </xsl:call-template>

result:

    <input type="text" value="John" id="sections_authors_0_name" name="sections[authors][0][name]">
    <input type="text" value="Mary" id="sections_authors_1_name" name="sections[authors][1][name]">
    <input type="text" value="Andrew" id="sections_authors_2_name" name="sections[authors][2][name]">
    <input type="text" value="Encyclopedia" id="sections_books_0_title" name="sections[books][0][title]">
    <input type="hidden" value="%authors[0][system:id]%,%authors[2][system:id]%" id="sections_books_0_authors" name="sections[books][0][authors]">
    <input type="text" value="XSLT Cookbook" id="sections_books_1_title" name="sections[books][1][title]">
    <input type="hidden" value="%authors[1]%" id="sections_books_1_authors" name="sections[books][1][authors]">



#### Example 4. An `Event date` field (type `DateTime`) in an Events section

    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'events'"/>
        <xsl:with-param name="handle" select="'event-date'"/>
        <xsl:with-param name="suffix" select="'start/ '"/>
        <xsl:with-param name="attributes">
            <type>date</type>
            <placeholder>Event date</placeholder>
        </xsl:with-param>
    </xsl:call-template>
    
result:

    <input type="date" placeholder="Event date" id="sections_events_event-date_start" name="sections[events][event-date][start][]">



#### Example #5. A page containing a complete form with validation

You can copy + paste this code in a Symphony Page and notice the results.

A `News` article with `Title` and `Publish date`. `Publish date` is hidden and will be formed with values from `pseudo-date` and `pseudo-time`.

    <?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:sform="http://xanderadvertising.com/xslt"
            extension-element-prefixes="sform">


        <xsl:import href="../utilities/sform-controls/sform-controls.xsl"/>


        <xsl:output method="xml"
                doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
                doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
                omit-xml-declaration="yes"
                encoding="UTF-8"
                indent="yes"/>


        <xsl:template match="/">
            <html>
                <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                </head>
                <body>
                    <h1>Dare to create a new article</h1>

                    <xsl:variable name="section" select="'news'"/>

                    <form method="post" action="">

                        <!-- Interpret the values from event. It can be customized. See the implementation -->
                        <xsl:variable name="formi">
                            <xsl:call-template name="sform:formi">
                                <xsl:with-param name="section" select="$section"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!-- Render this interpretation as pretty HTML. It can be customized. See the implementation -->
                        <xsl:call-template name="sform:validation-render">
                            <xsl:with-param name="interpretation" select="$formi"/>
                        </xsl:call-template>


                        <!-- As a very important optimization we're passing the $formi variable as a parameter to all utilities -->


                        <!-- Title -->
                        <xsl:call-template name="sform:label">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'title'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value" select="'Title'"/>
                        </xsl:call-template>

                        <xsl:call-template name="sform:input">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'title'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="attributes">
                                <placeholder>insert title</placeholder>
                            </xsl:with-param>
                        </xsl:call-template>


                        <!-- Pseudo Date - This field does not exist. I use it just as a variable for "Publish date" field (see below) -->
                        <xsl:call-template name="sform:label">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'pseudo-date'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value" select="'Date'"/>
                        </xsl:call-template>

                        <xsl:call-template name="sform:input">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'pseudo-date'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value" select="/data/params/today"/>
                            <xsl:with-param name="attributes">
                                <placeholder>dd-mm-yyyy</placeholder>
                            </xsl:with-param>
                        </xsl:call-template>


                        <!-- Pseudo Time - This field does not exist. I use it just as a variable for "Publish date" field (see below) -->
                        <xsl:call-template name="sform:label">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'pseudo-time'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value" select="'Time'"/>
                        </xsl:call-template>

                        <xsl:call-template name="sform:input">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'pseudo-time'"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value" select="/data/params/current-time"/>
                            <xsl:with-param name="attributes">
                                <placeholder>hh:mm</placeholder>
                            </xsl:with-param>
                        </xsl:call-template>


                        <!-- Publish date : Date/time field - Its value will be composed from "Pseudo date" and "Pseudo time" -->
                        <xsl:call-template name="sform:input">
                            <xsl:with-param name="section" select="$section"/>
                            <xsl:with-param name="handle" select="'publish-date'"/>
                            <xsl:with-param name="suffix" select="'start/ '"/>
                            <xsl:with-param name="interpretation" select="$formi"/>
                            <xsl:with-param name="value">
                                <xsl:call-template name="sform:variable">
                                    <xsl:with-param name="section" select="$section"/>
                                    <xsl:with-param name="handle" select="'pseudo-date'"/>
                                </xsl:call-template>
                                <xsl:text>T</xsl:text>
                                <xsl:call-template name="sform:variable">
                                    <xsl:with-param name="section" select="$section"/>
                                    <xsl:with-param name="handle" select="'pseudo-time'"/>
                                </xsl:call-template>
                            </xsl:with-param>
                            <xsl:with-param name="attributes">
                                <type>hidden</type>
                            </xsl:with-param>
                            <xsl:with-param name="postback-value-enabled" select="false()"/>
                        </xsl:call-template>


                        <!-- The redirect will benefit from the replacements as well -->
                        <input type="hidden" name="sections[__redirect]" value="{/data/params/root}/news/%{$section}[system:id]%"/>


                        <!-- Use "action[sections]" to enable the event -->
                        <button type="submit" name="action[sections]">Send</button>
                    </form>
                </body>
            </html>
        </xsl:template>


    </xsl:stylesheet>

result:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        </head>
        <body>
            <h1>Dare to create a new article</h1>
            <form method="post" action="">
                <label for="sections_news_title">Title</label>
                <input name="sections[news][title]" id="sections_news_title" type="text" placeholder="insert title"></input>
                <label for="sections_news_pseudo-date">Date</label>
                <input name="sections[news][pseudo-date]" id="sections_news_pseudo-date" type="text" value="2013-06-13" placeholder="dd-mm-yyyy"></input>
                <label for="sections_news_pseudo-time">Time</label>
                <input name="sections[news][pseudo-time]" id="sections_news_pseudo-time" type="text" value="11:50" placeholder="hh:mm"></input>
                <input name="sections[news][publish-date][start][]" id="sections_news_publish-date_start" type="hidden" value="%news[pseudo-date]%T%news[pseudo-time]%"></input>
                <input type="hidden" name="sections[__redirect]" value="http://127.0.0.1/symphony/news/%news[system:id]%" />
                <button type="submit" name="action[sections]">Send</button>
            </form>
        </body>
    </html>
