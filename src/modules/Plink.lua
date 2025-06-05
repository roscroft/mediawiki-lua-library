local p = {}
require("Module:Mw html extension")

local function plink(link, pic, txt, size)
	local sizetxt = size and ('|' .. size .. 'px') or ''
	local linktxt = #txt ~= 0 and ('[[' .. link .. '|' .. txt .. ']]') or ''

	return string.format(
		'<span class="pic-link inventory-image">[[File:%s.png|link=%s%s|alt=%s.png: RS3 Inventory image of %s]]</span>%s',
		pic, link, sizetxt, pic, link, linktxt)
end

function p.main(frame)
	local args = frame:getParent().args
	local link = args[1] or ''
	local pic = args.pic or link
	local txt = args.txt or link
	return plink(link, pic, txt, args.size)
end

function p._plink(link, args)
	local args = args or {}
	local link = link or args.link or ''
	local pic = args.pic or link
	local txt = args.txt or link
	return plink(link, pic, txt, args.size)
end

function p._plinkp(link, args)
	local args = args or {}
	local link = link or args.link or ''
	local pic = args.pic or link
	return plink(link, pic, '', args.size)
end

function p._plinkt(link, args)
	local args = args or {}
	local link = link or args.link or ""
	local pic = args.pic or link
	local border = args.border and args.border:lower() or ""
	local ret = mw.html.create()
		:td()
		:addClass("plinkt-image")
		:addClassIf(border == "no", "no-border")
		:attr("rowspan", args.rowspan)
		:node(
			mw.html.create("span")
			:addClass("inventory-image")
			:wikitext(
				string.format(
					"[[File:%s.%s|link=%s%s|alt=RuneScape inventory image of %s]]",
					pic,
					args.gif and "gif" or "png",
					link:lower() == "no" and "" or link,
					args.size and ("|" .. args.size .. "px") or "",
					link
				)
			)
		)
		:td()
		:addClass("plinkt-link")
		:addClassIf(border == "no", "no-border")
		:cssIf(args.nowrap and args.nowrap:lower() == "yes", "white-space", "nowrap")
		:cssIf(args.width, "width", (args.width or "") .. "px")
		:css("text-style", args["text-style"])
		:attr("rowspan", args.rowspan)
		:IF(link:lower() == "no")
		:wikitext(args.txt or link)
		:ELSE()
		:wikitext(string.format("[[%s|%s]]", link, args.txt or link))
		:END()

	return tostring(ret:allDone())
end

-- legacy interface
p._main = p.plink

return p
