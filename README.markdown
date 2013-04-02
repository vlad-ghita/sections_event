## Sections Event

This extension bundles an event and corresponding form controls for easier & integrated control of your frontend forms in one place.

If you ever had to submit data from Frontend to more than one section and those sections are linked together through a linking field (eg: SBL/SBL+), you had to customize your event.

Using this approach, you can set those relations right from XSLT and they will be handled on-the-fly thus no more customizations being required.



## Features:

* __One event to rule them all.__ It takes the form data and dispatches the processing for all sections where it should be.
* __On-the-fly Variable replacement.__ Any form value can be used as a variable in another value from your form.
* __Up to date Form controls.__ More complex fields have arisen lately. @nickdunn's Form Controls have fallen behind. The `Section Form Controls` offer updated and flexible utilities to help with the new fields and challenges.
* __Built in multiple entries support.__ Multiple entries are now supported by default without needing to apply another filter. Using `Section Form Controls`, sending multiple entries at once becomes a breeze.



## Install

Installation as usual.



## Usage

- attach `Sections` event to your Pages
- copy `/extensions/sections_event/utilities/sform-controls` folder to `/workspace/utilities/sform-controls`
- import `/utilities/sform-controls/sform-controls.xsl` in your `page.xsl`
- add the `sform` namespace to your `page.xsl` (eg: `xmlns:sform="http://xanderadvertising.com/xslt"`)
- start building forms!



## `Section Form Controls` utilities

These utilities were inspired by @nick-dunn's Form Controls and exist to help with form creation and validation. 

#### Validation

An event in Symphony **typically** returns a status message regarding event success or failure, error & success status for various filters and **only** status errors about the fields in the form. The [sform:validation-interpret](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L50) template tries to identify these elements in your event and return a consistent interpretation report about what's going on. Based on this report, you can output your errors automatically using the `sform:validation-render` template or do whatever you please.

An interpretation report will have 3 group nodes:

- `entry` - status regarding the entry / event that was processed
- `filters` - status about each filter. Filters are determined by those nodes named `filter` which do not have an `type` attribute
- `fields` - status about every field that was found. Fields are all nodes that have an `type` attribute.

Each group contains `items`. An `item` is made of:

- `handle` attribute - acts as an ID.
- `status` attribute - informs about the status of this item. It can have 2 values at the moment: [`$sform:STATUS_SUCCESS`](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L13) and [`$sform:STATUS_ERROR`](https://github.com/vlad-ghita/sections_event/blob/master/utilities/sform-controls/sform.validation.xsl#L14).
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
                <position>SFORM_NULL</position>
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
                <position>SFORM_NULL</position>
            </id>
            <msg>Username is a required field.</msg>
            <original>
                <username type="missing" message="Username is a required field." label="Username"></username>
            </original>
        </item>
    </fields>

#### Utilities

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
* `attributes` (optional, node set): Other attributes for this element.
* `postback-value` (optional, node set): Value to use after form was posted and page reloaded.
* `postback-value-enabled` (optional, node set): Switcher to enable the display of postback value.



Here are some examples:

### Example 1. Most basic usage

If you don't specify the section, the `__fields` keyword is used. This is handy if you don't necessarily want to set data for a Symphony Entry.

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="attributes">
            <placeholder>Insert title here</placeholder>
        </xsl:with-param>
    </xsl:call-template>

result:

    <input type="text" placeholder="Insert title here" id="sections___fields_title" name="sections[__fields][title]">



### Example 2. Send data to a `Books` section

    <xsl:call-template name="sform:input">
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
    </xsl:call-template>

result:

    <input type="text" value="Encyclopedia" id="sections_books_title" name="sections[books][title]">



### Example 3. Send multiple entries at once #1

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



### Example 4. Send multiple entries at once #2 (many to many relation between Books and Authors)

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



### Example 5. An input related to a Date/Time field

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'publish-date'"/>
        <xsl:with-param name="suffix" select="'start/ '"/>
        <xsl:with-param name="attributes">
            <type>date</type>
            <placeholder>Publish date</placeholder>
        </xsl:with-param>
    </xsl:call-template>
    
result:

    <input type="date" placeholder="Publish date" id="sections___fields_publish-date_start" name="sections[__fields][publish-date][start][]">



### Example #6. A complete form with validation

A `News` article with `Title` and `Publish date`. `Publish date` is hidden and will be formed with values from `pseudo-date` and `pseudo-time`.

    <xsl:variable name="section" select="'news'"/>
    
    <form method="post" action="">

        <!-- Interpret the values from event. It can be customized. See the implementation -->
        <xsl:variable name="interpretation">
            <xsl:call-template name="sform:validation-interpret">
                <xsl:with-param name="section" select="$section"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Render this interpretation as pretty HTML. It can be customized. See the implementation -->
        <xsl:call-template name="sform:validation-render">
            <xsl:with-param name="interpretation" select="$interpretation"/>
        </xsl:call-template>

		<!-- As a very important optimization we're passing the $interpretation variable as a parameter to all utilities -->


        <!-- Title -->
        <xsl:call-template name="sform:label">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'title'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="value" select="'Title'"/>
        </xsl:call-template>

        <xsl:call-template name="sform:input">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'title'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="attributes">
                <placeholder>insert title</placeholder>
            </xsl:with-param>
        </xsl:call-template>


        <!-- Pseudo Date - This field does not exist. I use it just as a variable for Publish date field (see below) -->
        <xsl:call-template name="sform:label">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'pseudo-date'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="value" select="'Date'"/>
        </xsl:call-template>

        <xsl:call-template name="sform:input">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'pseudo-date'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="value" select="/data/params/today"/>
            <xsl:with-param name="attributes">
                <placeholder>dd-mm-yyyy</placeholder>
            </xsl:with-param>
        </xsl:call-template>

        <!-- Pseudo Time - This field does not exist. I use it just as a variable for Publish date field (see below) -->
        <xsl:call-template name="sform:label">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'pseudo-time'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="value" select="'Time'"/>
        </xsl:call-template>

        <xsl:call-template name="sform:input">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'pseudo-time'"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
            <xsl:with-param name="value" select="/data/params/current-time"/>
            <xsl:with-param name="attributes">
                <placeholder>hh:mm</placeholder>
            </xsl:with-param>
        </xsl:call-template>

        <!-- Publish date : Date/time field - It's value will be composed from "Pseudo date" and "Pseudo time" -->
        <xsl:call-template name="sform:input">
            <xsl:with-param name="section" select="$section"/>
            <xsl:with-param name="handle" select="'publish-date'"/>
            <xsl:with-param name="suffix" select="'start/ '"/>
            <xsl:with-param name="interpretation" select="$interpretation"/>
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

        <button type="submit" name="action[sections]">Send</button>
    </form>

result:

    <form method="post" action="">
        <label for="sections_news_title">Title</label>
        <input type="text" placeholder="insert title" id="sections_news_title" name="sections[news][title]">
        <label for="sections_news_pseudo-date">Date</label>
        <input type="text" placeholder="dd-mm-yyyy" value="2013-01-26" id="sections_news_pseudo-date" name="sections[news][pseudo-date]">
        <label for="sections_news_pseudo-time">Time</label>
        <input type="text" placeholder="hh:mm" value="20:15" id="sections_news_pseudo-time" name="sections[news][pseudo-time]">
        <input type="hidden" value="%news[pseudo-date]%T%news[pseudo-time]%" id="sections_news_publish-date_start" name="sections[news][publish-date][start][]">
        <input type="hidden" name="sections[__redirect]" value="http://www.example.com/news/%{$section}[system:id]%">
        <button name="action[sections]" type="submit">Send</button>
    </form>
