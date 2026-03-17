--- === hs.styledtext ===
---
--- This module adds support for controlling the style of the text in Hammerspoon.
---
--- More detailed documentation is being worked on and will be provided in the Hammerspoon Wiki at https://github.com/Hammerspoon/hammerspoon/wiki.  The documentation here is a condensed version provided for use within the Hammerspoon Dash docset and the inline help provided by the `help` console command within Hammerspoon.
---
--- The following list of attributes key-value pairs are recognized by this module and can be adjusted, set, or removed for objects by the various methods provided by this module.  The list of attributes is provided here for reference; anywhere in the documentation you see a reference to the `attributes key-value pairs`, refer back to here for specifics:
---
--- * `font`               - A table containing the font name and size, specified by the keys `name` and `size`.  Default is the System Font at 27 points for `hs.drawing` text objects; otherwise the default is Helvetica at 12 points.  You may also specify this as a string, which will be taken as the font named in the string at the default size, when setting this attribute.
--- * `color`              - A table indicating the color of the text as described in `hs.drawing.color`.  Default is white for hs.drawing text objects; otherwise the default is black.
--- * `backgroundColor`    - Default nil, no background color (transparent).
--- * `underlineColor`     - Default nil, same as `color`.
--- * `strikethroughColor` - Default nil, same as `color`.
--- * `strokeColor`        - Default nil, same as `color`.
--- * `strokeWidth`        - Default 0, no stroke; positive, stroke alone; negative, stroke and fill (a typical value for outlined text would be 3.0)
--- * `paragraphStyle`     - A table containing the paragraph style.  This table may contain any number of the following keys:
---     * `alignment`                     - A string indicating the texts alignment.  The string may contain a value of "left", "right", "center", "justified", or "natural". Default is "natural".
---     * `lineBreak`                     - A string indicating how text that doesn't fit into the drawingObjects rectangle should be handled.  The string may be one of "wordWrap", "charWrap", "clip", "truncateHead", "truncateTail", or "truncateMiddle".  Default is "wordWrap".
---     * `baseWritingDirection`          - A string indicating the base writing direction for the lines of text.  The string may be one of "natural", "leftToRight", or "rightToLeft".  Default is "natural".
---     * `tabStops`                      - An array of defined tab stops.  Default is an array of 12 left justified tab stops 28 points apart.  Each element of the array may contain the following keys:
---         * `location`                      - A floating point number indicating the number of points the tab stap is located from the line's starting margin (see baseWritingDirection).
---         * `tabStopType`                   - A string indicating the type of the tab stop: "left", "right", "center", or "decimal"
---     * `defaultTabInterval`            - A positive floating point number specifying the default tab stop distance in points after the last assigned stop in the tabStops field.
---     * `firstLineHeadIndent`           - A positive floating point number specifying the distance, in points, from the leading margin of a frame to the beginning of the paragraph's first line.  Default 0.0.
---     * `headIndent`                    - A positive floating point number specifying the distance, in points, from the leading margin of a text container to the beginning of lines other than the first.  Default 0.0.
---     * `tailIndent`                    - A floating point number specifying the distance, in points, from the margin of a frame to the end of lines. If positive, this value is the distance from the leading margin (for example, the left margin in left-to-right text). If 0 or negative, it's the distance from the trailing margin.  Default 0.0.
---     * `maximumLineHeight`             - A positive floating point number specifying the maximum height that any line in the frame will occupy, regardless of the font size. Glyphs exceeding this height will overlap neighboring lines. A maximum height of 0 implies no line height limit. Default 0.0.
---     * `minimumLineHeight`             - A positive floating point number specifying the minimum height that any line in the frame will occupy, regardless of the font size.  Default 0.0.
---     * `lineSpacing`                   - A positive floating point number specifying the space in points added between lines within the paragraph (commonly known as leading). Default 0.0.
---     * `paragraphSpacing`              - A positive floating point number specifying the space added at the end of the paragraph to separate it from the following paragraph.  Default 0.0.
---     * `paragraphSpacingBefore`        - A positive floating point number specifying the distance between the paragraph's top and the beginning of its text content.  Default 0.0.
---     * `lineHeightMultiple`            - A positive floating point number specifying the line height multiple. The natural line height of the receiver is multiplied by this factor (if not 0) before being constrained by minimum and maximum line height.  Default 0.0.
---     * `hyphenationFactor`             - The hyphenation factor, a value ranging from 0.0 to 1.0 that controls when hyphenation is attempted. By default, the value is 0.0, meaning hyphenation is off. A factor of 1.0 causes hyphenation to be attempted always.
---     * `tighteningFactorForTruncation` - A floating point number.  When the line break mode specifies truncation, the system attempts to tighten inter character spacing as an alternative to truncation, provided that the ratio of the text width to the line fragment width does not exceed 1.0 + the value of tighteningFactorForTruncation. Otherwise the text is truncated at a location determined by the line break mode. The default value is 0.05.
---     * `allowsTighteningForTruncation` - A boolean indicating whether the system may tighten inter-character spacing before truncating text. Only available in macOS 10.11 or newer. Default true.
---     * `headerLevel`                   - An integer number from 0 to 6 inclusive which specifies whether the paragraph is to be treated as a header, and at what level, for purposes of HTML generation.  Defaults to 0.
--- * `superscript`        - An integer indicating if the text is to be displayed as a superscript (positive) or a subscript (negative) or normal (0).
--- * `ligature`           - An integer. Default 1, standard ligatures; 0, no ligatures; 2, all ligatures.
--- * `strikethroughStyle` - An integer representing the strike-through line style.  See `hs.styledtext.lineStyles`, `hs.styledtext.linePatterns` and `hs.styledtext.lineAppliesTo`.
--- * `underlineStyle`     - An integer representing the underline style.  See `hs.styledtext.lineStyles`, `hs.styledtext.linePatterns` and `hs.styledtext.lineAppliesTo`.
--- * `baselineOffset`     - A floating point value, as points offset from baseline. Default 0.0.
--- * `kerning`            - A floating point value, as points by which to modify default kerning.  Default nil to use default kerning specified in font file; 0.0, kerning off; non-zero, points by which to modify default kerning.
--- * `obliqueness`        - A floating point value, as skew to be applied to glyphs.  Default 0.0, no skew.
--- * `expansion`          - A floating point value, as log of expansion factor to be applied to glyphs.  Default 0.0, no expansion.
--- * `shadow`             - Default nil, indicating no drop shadow.  A table describing the drop shadow effect for the text.  The table may contain any of the following keys:
---     * `offset`             - A table with `h` and `w` keys (a size structure) which specify horizontal and vertical offsets respectively for the shadow.  Positive values always extend down and to the right from the user's perspective.
---     * `blurRadius`         - A floating point value specifying the shadow's blur radius.  A value of 0 indicates no blur, while larger values produce correspondingly larger blurring. The default value is 0.
---     * `color`              - The default shadow color is black with an alpha of 1/3. If you set this property to nil, the shadow is not drawn.
---
--- To make the `hs.styledtext` objects easier to use, in addition to the module specific functions and methods defined, some of the Lua String library has been reproduced to perform similar functions on these objects.  See the help section for each method for more information on their use:
---
--- * `hs.styledtext:byte`
--- * `hs.styledtext:find`
--- * `hs.styledtext:gmatch`
--- * `hs.styledtext:len`
--- * `hs.styledtext:lower`
--- * `hs.styledtext:match`
--- * `hs.styledtext:rep`
--- * `hs.styledtext:sub`
--- * `hs.styledtext:upper`
---
--- In addition, the following metamethods have been included:
---
--- * concat:
---     * `string`..`object` yields the string values concatenated
---     * `object`..`string` yields a new `hs.styledtext` object with `string` appended
---     * two `hs.styledtext` objects yields a new `hs.styledtext` object containing the concatenation of the two objects
--- * len:     #object yields the length of the text contained in the object
--- * eq:      object ==/~= object yields a boolean indicating if the text of the two objects is equal or not.  Use `hs.styledtext:isIdentical` if you need to compare attributes as well.
--- * lt, le:  allows &lt;, &gt;, &lt;=, and &gt;= comparisons between objects and strings in which the text of an object is compared with the text of another or a Lua string.
---
--- Note that due to differences in the way Lua determines when to use metamethods for equality comparisons versus relative-position comparisons, ==/~= cannot compare an object to a Lua string (it will always return false because the types are different).  You must use object:getString() ==/~= `string`.  (see `hs.styledtext:getString`)

local module = require("hs.libstyledtext")
require("hs.drawing.color") -- make sure that the conversion helpers required to support color are loaded

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

-- tweak the hs.styledtext object metatable with things easier to do in lua...
local objectMetatable = hs.getObjectMetatable("hs.styledtext")

--- hs.styledtext:byte([starts], [ends]) -> integer, ...
--- Method
--- Returns the internal numerical representation of the characters in the `hs.styledtext` object specified by the given indices.  Mimics the Lua `string.byte` function.
---
--- Parameters:
---  * starts - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the substring to return numerical values for.  Defaults to 1, the beginning of the objects text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
---  * ends   - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to return numerical values for.  Defaults to the value of `starts`.  If this number is negative, it is counted backwards from the end of the object's text.
---
--- Returns:
---  * a list of integers representing the internal numeric representation of the characters in the `hs.styledtext` object specified by the given indices.
---
--- Notes:
---  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function.
objectMetatable.byte   = function(self, ...) return self:getString():byte(...) end

--- hs.styledtext:find(pattern, [init, [plain]]) -> start, end, ... | nil
--- Method
--- Returns the indices of the first occurrence of the specified pattern in the text of the `hs.styledtext` object.  Mimics the Lua `string.find` function.
---
--- Parameters:
---  * pattern  - a string containing the pattern to locate.  See the Lua manual, section 6.4.1 (`help.lua._man._6_4_1`) for more details.
---  * init     - an optional integer specifying the location within the text to start the pattern search
---  * plain    - an optional boolean specifying whether or not to treat the pattern as plain text (i.e. an exact match).  Defaults to false.  If you wish to specify this argument, you must also specify init.
---
--- Returns:
---  * if a match is found, `start` and `end` will be the indices where the pattern was first located.  If captures were specified in the pattern, they will also be returned as additional arguments after `start` and `end`.  If the pattern was not found in the text, then this method returns nil.
---
--- Notes:
---  * Any captures returned are returned as Lua Strings, not as `hs.styledtext` objects.
objectMetatable.find   = function(self, ...) return self:getString():find(...) end

--- hs.styledtext:match(pattern, [init]) -> match ... | nil
--- Method
--- Returns the first occurrence of the captures in the specified pattern (or the complete pattern, if no captures are specified) in the text of the `hs.styledtext` object.  Mimics the Lua `string.match` function.
---
--- Parameters:
---  * pattern  - a string containing the pattern to locate.  See the Lua manual, section 6.4.1 (`help.lua._man._6_4_1`) for more details.
---  * init     - an optional integer specifying the location within the text to start the pattern search
---
--- Returns:
---  * if a match is found, the captures in the specified pattern (or the complete pattern, if no captures are specified).  If the pattern was not found in the text, then this method returns nil.
---
--- Notes:
---  * Any captures (or the entire pattern) returned are returned as Lua Strings, not as `hs.styledtext` objects.
objectMetatable.match  = function(self, ...) return self:getString():match(...) end

--- hs.styledtext:gmatch(pattern) -> iterator-function
--- Method
--- Returns an iterator function which will return the captures (or the entire pattern) of the next match of the specified pattern in the text of the `hs.styledtext` object each time it is called.  Mimics the Lua `string.gmatch` function.
---
--- Parameters:
---  * pattern  - a string containing the pattern to locate.  See the Lua manual, section 6.4.1 (`help.lua._man._6_4_1`) for more details.
---
--- Returns:
---  * an iterator function which will return the captures (or the entire pattern) of the next match of the specified pattern in the text of the `hs.styledtext` object each time it is called.
---
--- Notes:
---  * Any captures (or the entire pattern) returned by the iterator are returned as Lua Strings, not as `hs.styledtext` objects.
objectMetatable.gmatch = function(self, ...) return self:getString():gmatch(...) end


--- hs.styledtext:rep(n, [separator]) -> styledText object
--- Method
--- Returns an `hs.styledtext` object which contains `n` repetitions of the `hs.styledtext` object, optionally with `separator` between each repetition.  Mimics the Lua `string.rep` function.
---
--- Parameters:
---  * n         - the number of times to repeat the `hs.styledtext` object.
---  * separator - an optional string or `hs.styledtext` object to insert between repetitions.
---
--- Returns:
---  * an `hs.styledtext` object which contains `n` repetitions of the object, including `separator` between repetitions, if it is specified.
objectMetatable.rep    = function(self, n, sep)
    if n < 1 then return module.new("") end
    local i, result = 1, self:copy()
    while (i < n) do
        if sep then result = result:replaceSubstring(sep, #result + 1, 0) end
        result = result..self
        i = i + 1
    end
    return result
end

-- string.format   is hs.styletext.new(string.format(...)) sufficient?
-- string.reverse  reversing styles, attachment anchors, etc. do not present an obvious solution...
-- string.gsub     replaces substrings internally... no obvious simple solution that maintains/supports styles...
-- string.char     hs.styledtext.new(string.char(...)) is more clear as to what's intended
-- string.dump     makes no sense in the context of styled strings
-- string.pack     makes no sense in the context of styled strings
-- string.packsize makes no sense in the context of styled strings
-- string.unpack   makes no sense in the context of styled strings

-- font stuff documented in internal.m
module.fontTraits    = ls.makeConstantsTable(module.fontTraits)
module.linePatterns  = ls.makeConstantsTable(module.linePatterns)
module.lineStyles    = ls.makeConstantsTable(module.lineStyles)
module.lineAppliesTo = ls.makeConstantsTable(module.lineAppliesTo)

module.fontNames = function(...)
    local results = module._fontNames(...)
    return results and ls.makeConstantsTable(results) or nil
end

module.fontFamilies = function(...)
    local results = module._fontFamilies(...)
    return results and ls.makeConstantsTable(results) or nil
end

module.fontNamesWithTraits = function(...)
    local results = module._fontNamesWithTraits(...)
    return results and ls.makeConstantsTable(results) or nil
end

--- hs.styledtext.fontsForFamily(familyName) -> table
--- Function
--- Returns an array containing fonts available for the specified font family or nil if no fonts for the specified family are present.
---
--- Parameters:
---  * `familyName` - a string specifying the font family to return available fonts for. The strings should be one of the values returned by the [hs.styledtext.fontFamilies](#fontFamilies) function.
---
--- Returns:
---  * a table containing an array of available fonts for the specified family. Each array entry will be a table, also as an array, in the following order:
---    * a string specifying the font name which can be used in the `hs.drawing:setTextFont(fontname)` method.
---    * a string specifying the basic style of the font (e.g. Bold, Italic, Roman, etc.)
---    * a table containing one or more strings specifying common names for the weight of the font. ISO equivalent names are preceded with "ISO:". Possible values are:
---             `{ "ultralight" }`
---             `{ "thin", "ISO:ultralight" }`
---             `{ "light", "extralight", "ISO:extralight" }`
---             `{ "book", "ISO:light" }`
---             `{ "regular", "plain", "display", "roman", "ISO:semilight" }`
---             `{ "medium", "ISO:medium" }`
---             `{ "demi", "demibold" }`
---             `{ "semi", "semibold", "ISO:semibold" }`
---             `{ "bold", "ISO:bold" }`
---             `{ "extra", "extrabold", "ISO:extrabold" }`
---             `{ "heavy", "heavyface" }`
---             `{ "black", "super", "ISO:ultrabold" }`
---             `{ "ultra", "ultrablack", "fat" }`
---             `{ "extrablack", "obese", "nord" }`
---    * a table specifying zero or more traits for the font as defined in the [hs.styledtext.fontTraits](#fontTraits) table. A field with the key `_numeric` is also set which specified the numeric value corresponding to the traits for easy use with the [hs.styledtext.convertFont](#convertFont) function.
module.fontsForFamily = function(...)
    local results = module._fontsForFamily(...)
    if results then
        local fontWeights = {
            { "ultralight" },
            { "thin", "ISO:ultralight" },
            { "light", "extralight", "ISO:extralight" },
            { "book", "ISO:light" },
            { "regular", "plain", "display", "roman", "ISO:semilight" },
            { "medium", "ISO:medium" },
            { "demi", "demibold" },
            { "semi", "semibold", "ISO:semibold" },
            { "bold", "ISO:bold" },
            { "extra", "extrabold", "ISO:extrabold" },
            { "heavy", "heavyface" },
            { "black", "super", "ISO:ultrabold" },
            { "ultra", "ultrablack", "fat" },
            { "extrablack", "obese", "nord" }
        }
        for _,v in ipairs(results) do
            v[3] = fontWeights[v[3]] or string.format("** unrecognized font weight: %d", v[3])
            local style, styleTable = v[4], { _numeric = v[4] }
            for k, v2 in pairs(module.fontTraits) do
                if style & v2 == v2 then
                    table.insert(styleTable, k)
                    style = style - v2
                end
            end
            if style ~= 0 then
                table.insert(styleTable, string.format("** unrecognized font trait flags: %d", style))
            end
            v[4] = styleTable
        end
        return ls.makeConstantsTable(results)
    else
        return nil
    end
end

module.fontInfo = function(...)
    local _tableWrapper = function(results)
        local __tableWrapperFunction
        __tableWrapperFunction = function(_)
            local result = ""
            local width = 0
            local fnutils = require("hs.fnutils")
            for k,_ in pairs(_) do width = width < #k and #k or width end
            for k,v in fnutils.sortByKeys(_) do
                result = result..string.format("%-"..tostring(width).."s ", k)
                if type(v) == "table" then
                    result = result..__tableWrapperFunction(v):gsub("[ \n]", {[" "] = "=", ["\n"] = " "}).."\n"
                else
                    result = result..tostring(v).."\n"
                end
            end
            return result
        end

        return setmetatable(results, { __tostring=__tableWrapperFunction })
    end

    return _tableWrapper(module._fontInfo(...))
end

--- hs.styledtext.ansi(string, [attributes]) -> styledText object
--- Constructor
--- Create an `hs.styledtext` object from the string provided, converting ANSI SGR color and some font sequences into the appropriate attributes.  Attributes to apply to the resulting string may also be optionally provided.
---
--- Parameters:
---  * string     - The string containing the text with ANSI SGR sequences to be converted.
---  * attributes - an optional table containing attribute key-value pairs to apply to the entire `hs.styledtext` object to be returned.
---
--- Returns:
---  * an `hs.styledtext` object
---
--- Notes:
---  * Because a font is required for the SGR sequences indicating Bold and Italic, the base font is determined using the following logic:
--- *  * if no `attributes` table is provided, the font is assumed to be the default for `hs.drawing` as returned by the `hs.drawing.defaultTextStyle` function
--- *  * if an `attributes` table is provided and it defines a `font` attribute, this font is used.
--- *  * if an `attributes` table is provided, but it does not provide a `font` attribute, the NSAttributedString default of Helvetica at 12 points is used.
---  * As the most common use of this constructor is likely to be from the output of a terminal shell command, you will most likely want to specify a fixed-pitch (monospace) font.  You can get a list of installed fixed-pitch fonts by typing `hs.styledtext.fontNamesWithTraits(hs.styledtext.fontTraits.fixedPitchFont)` into the Hammerspoon console.
---
---  * See the module description documentation (`help.hs.styledtext`) for a description of the attributes table format which can be provided for the optional second argument.
---
-- Return Module Object --------------------------------------------------

module = setmetatable(module, {
    __index = function(self, _)
        if _ == "defaultFonts" then
            local results = self._defaultFonts()
            for k, v in pairs(results) do
                results[k] = setmetatable(v, { __tostring = function(_)
                       return "{ name = ".._.name..", size = "..tostring(_.size).." }"
                   end
                })
            end
            return setmetatable(results, { __tostring = function(_)
                    local result = ""
                    local width = 0
                    local fnutils = require("hs.fnutils")
                    for k,_ in pairs(_) do width = width < #k and #k or width end
                    for k,v in fnutils.sortByKeys(_) do
                        result = result..string.format("%-"..tostring(width).."s %s\n", k, tostring(v))
                    end
                    return result
                end
            })

        else
            return rawget(self, _)
        end
    end,
    __call = function(self, ...) -- luacheck: ignore
        return module.new(...)
    end
})

return module
