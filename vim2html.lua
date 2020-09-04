-- basic vimdoc to html 
local buffer = {}

-- remove unwanted characters from hypelink destinations
function escape_id(id)
  -- use unique characters to prevent collisions
  local replaces = {[">"] = "g", ["<"] = "l", ["#"]="h", [":"]="c" }
  return id:gsub("([#<>:])", replaces)
end

local function escape(line)
  local replaces = {[">"] = "&gt;", ["<"] = "&lt;", ["&"]="&amp;"}
  return line:gsub("[<>&]",replaces)
end

-- regex patterns
local non_empty_line = "[%S]"

local listing_start = "&gt;%s*$"
local listing_end = "^%s*&lt;"
local is_tag = "&lt;.+&gt;"

local listing_start_tag = "<section class='listing'>" 
local listing_eng_tag = "</section>"

local link_pat = "(https?:[%S]+[%a%d/])"

local highlight_line = "%~%s*$"
local highlight_start = "<span class='highlight'>"
local highlight_end = "</span>"

local start_listing = false
local inlisting = false

local destinations = {} -- table with links for the current line

for line in io.lines() do
  line = escape(line) -- 
  -- handle listings
  -- listing was started on previous line
  if start_listing then
    -- insert start element only on non empty line
    if line:match(non_empty_line) then
      line = listing_start_tag.. line
      start_listing = false
    end
  elseif line:match(is_tag) then
    -- ignore html tags at end of the line
  elseif line:match(listing_end) then
    -- close section
    buffer[#buffer] = buffer[#buffer] .. listing_eng_tag 
    line = line:gsub(listing_end, "") -- < at beginning of the line is end of listings
    if not line:match(non_empty_line) then
      line = nil -- remove empty line
    end
    inlisting = false
  elseif line:match(listing_start) then
    line = line:gsub(listing_start, "") --  > at the end of line is start of listings.
    start_listing = true
    inlisting = true
  end
  if line and not inlisting then
    -- highlight hyperlinks
    line = line:gsub(link_pat, "<a href='%1'>%1</a>")
    -- save link destinations
    line = line:gsub("%*([%a][%S]+)%*", function(a) 
      -- links will be inserted only on non empty lines
      table.insert(destinations, string.format("<a id='%s'></a>", escape_id(a))) 
      return ""
    end)
    -- insert cross-links
    line = line:gsub("|([%a][%S]+)|", function(a) return string.format("<a href='#%s'>%s</a>", escape_id(a), a) end)
    -- insert link destinations
    if #destinations > 0 then
      if line:match(non_empty_line) then
        line = line .. table.concat(destinations) 
        destinations = {}
      else
        -- delete lines that contain only destinations
        line = nil
      end
    end
    if line and line:match(highlight_line) then
      -- lines that end with ~
      line = line:gsub(highlight_line, "")
      line = highlight_start .. line .. highlight_end
    end
  end
  buffer[#buffer+1] = line
end

print [[<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<style type="text/css">
.listing{background-color:#ddd;margin:0;}
.highlight{color:#0d0;}
.header{color:#d00;}
</style>
</head>
<body>
<pre>
]]
print(table.concat(buffer, "\n"))
print [[</pre>
</body>
</html>
]]

