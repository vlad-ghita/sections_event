## Sections Event

This extension bundles an event and corresponding form controls for easier & integrated control of your frontend forms in one place.

If you ever had to submit data from Frontend to more than 1 section and those sections are linked together through a SBL/SBL+ field, you had to customize your event.

Using this approach, those relations are handled on-the-fly and no more customizations are required.

## Features:

* __One event to rule them all.__ It takes the form data and dispatches the processing for all sections where it should be. It also takes care of __linking__ the entries to each other.
* __Up to date Form controls.__ More complex fields have arisen lately. @nickdunn's Form Controls have fallen behind. The `Section Form Controls` offer updated and flexible utilities to help with the new fields and challenges.
* __Built in multiple entries support.__ Multiple entries are now supported by default without needing to apply another filter. Using `Section Form Controls`, refactoring the XSLT code to support multiple entries at once becomes a breeze.

## Install

Installation as usual.

## Usage

- attach `Sections` event to your Pages
- copy `/extensions/sections_event/utilities/sform-controls` folder to `/workspace/utilities/sform-controls`
- import `/utilities/sform-controls/sform-controls.xsl` in your `page.xsl`
- add the `sform` namespace to your `page.xsl` (eg: `xmlns:sform="http://xanderadvertising.com/xslt"`)
- start building forms!

## `Section Form Controls` utilities

The utilities are documented and the code is (I hope) self-explanatory.

However, here we go. All utilities use these parameters:

- `handle` - an xPath like string that identifies the field data. Usually it's just the handle of the field.
- `value` - the value to be sent with the form. Varies from controller to controller.
- `attributes` - an XML representing the attributes that will be attached to the controller. For each controller some attributes are calculated automatically.
- `event` - the Sections event
- `section` - handle of the section to where this controller sends it's data
- `position` - index of this entry in a `multiple entries` situation

Here are some examples:

### Example 1. Most basic usage

If you don't specify the section, the `__fields` keyword is used. This is handy if you don't necessarily want to set data for an Entry.

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="attributes">
            <placeholder>Insert title here</placeholder>
        </xsl:with-param>
    </xsl:call-template>

result:

    <input type="text" placeholder="Insert title here" id="sections-__fields-title" name="sections[__fields][title]">

### Example 2. Send data to a `Books` section

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
        <xsl:with-param name="section" select="'books'"/>
    </xsl:call-template>

result:

    <input type="text" value="Encyclopedia" id="sections-books-title" name="sections[books][title]">

### Example 3. Send multiple entries at once #1

    <!-- Book #0 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
    </xsl:call-template>

    <!-- Book #1 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'XSLT Cookbook'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
    </xsl:call-template>

result:

    <input type="text" value="Encyclopedia" id="sections-books-0-title" name="sections[books][0][title]">
    <input type="text" value="XSLT Cookbook" id="sections-books-1-title" name="sections[books][1][title]">

### Example 4. Send multiple entries at once #2 (many to many relation between Books and Authors)

    <!-- Author #0 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'John'"/>
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="0"/>
    </xsl:call-template>

    <!-- Author #1 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'Mary'"/>
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="1"/>
    </xsl:call-template>

    <!-- Author #2 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'name'"/>
        <xsl:with-param name="value" select="'Andrew'"/>
        <xsl:with-param name="section" select="'authors'"/>
        <xsl:with-param name="position" select="2"/>
    </xsl:call-template>

    <!-- Book #0 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'Encyclopedia'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
    </xsl:call-template>

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'authors'"/>
        <xsl:with-param name="value" select="'authors[0], authors[2]'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="0"/>
        <xsl:with-param name="attributes">
            <type>hidden</type>
        </xsl:with-param>
    </xsl:call-template>

    <!-- Book #1 -->
    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'title'"/>
        <xsl:with-param name="value" select="'XSLT Cookbook'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
    </xsl:call-template>

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'authors'"/>
        <xsl:with-param name="value" select="'authors[1]'"/>
        <xsl:with-param name="section" select="'books'"/>
        <xsl:with-param name="position" select="1"/>
        <xsl:with-param name="attributes">
            <type>hidden</type>
        </xsl:with-param>
    </xsl:call-template>

result:

    <input type="text" value="John" id="sections-authors-0-name" name="sections[authors][0][name]">
    <input type="text" value="Mary" id="sections-authors-1-name" name="sections[authors][1][name]">
    <input type="text" value="Andrew" id="sections-authors-2-name" name="sections[authors][2][name]">
    <input type="text" value="Encyclopedia" id="sections-books-0-title" name="sections[books][0][title]">
    <input type="hidden" value="authors[0], authors[2]" id="sections-books-0-authors" name="sections[books][0][authors]">
    <input type="text" value="XSLT Cookbook" id="sections-books-1-title" name="sections[books][1][title]">
    <input type="hidden" value="authors[1]" id="sections-books-1-authors" name="sections[books][1][authors]">

### Example 6. An input related to a Date/Time field

    <xsl:call-template name="sform:input">
        <xsl:with-param name="handle" select="'birthday/start/ '"/>
        <xsl:with-param name="attributes">
            <type>date</type>
            <placeholder>Birthday</placeholder>
        </xsl:with-param>
    </xsl:call-template>
    
result:

    <input type="date" placeholder="Birthday" id="sections-__fields-birthday-start" name="sections[__fields][birthday][start][]">
