-- <nowiki>
-- Removes 'File:' prefix, just in case
-- Replace {{!}} with | instead of preprocessing
-- Turn into a nice wiki file link
local hc = require('Paramtest').has_content
local p = {}
p.main = function(frame)
	local args = frame:getParent().args
	local clean = {
		file = args.file or args[1],
		width = args.width or args[2],
		height = args.height or args[3],
		link = args.link or args[4],
		align = args.align or args[5]
	}
	return p.clean(clean)
end

p.clean = function(args)
	local file = args.file
	if not hc(file) or (file and (file:lower() == 'no' or file == '')) then
		return ''
	end
	
	local height, width = '',''
	if hc(args.height) then
		height = 'x'..args.height
	end
	if hc(args.width) then
		width = args.width
	end
	local size = ''
	if width ~= '' or height ~= '' then
		size = string.format('|%s%spx', width, height)
	end
	
	local link = ''
	if hc(args.link) then
		if args.link == 'no' then
			link = '|link='
		else
			link = '|link='..args.link
		end
	end
	
	local alignment = ''
	local align = args.align
	if align and (align:lower() == 'left' or align:lower() == 'center' or align:lower() == 'right') then
		alignment = string.format('|%s', align)
	end
	
	file = file:gsub('%[',''):gsub('%]',''):gsub('[Ff]ile:',''):gsub('{{!}}','|')

	-- enforce max height and width
	file = mw.text.split(file, '|')

	file = string.format('%s%s%s%s',file[1], size, link, alignment)
	return '[[File:'..file..'|frameless]]'
end

return p
-- </nowiki>
