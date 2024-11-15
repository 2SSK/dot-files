--- @diagnostic disable: undefined-global, undefined-field
--- @alias Mode Mode Comes from Yazi.
--- @alias Rect Rect Comes from Yazi.
--- @alias Paragraph Paragraph Comes from Yazi.
--- @alias Line Line Comes from Yazi.
--- @alias Span Span Comes from Yazi.
--- @alias Color Color Comes from Yazi.
--- @alias Config Config The config used for setup.
--- @alias Coloreds Coloreds The array returned by colorizer in {{string, Color}, {string, Color} ... } format
--- @alias Side # [ LEFT ... RIGHT ]
--- | `enums.LEFT` # The left side of either the header-line or status-line. [ LEFT ... ]
--- | `enums.RIGHT` # The right side of either the header-line or status-line. [ ... RIGHT]
--- @alias SeparatorType
--- | `enums.OUTER` # Separators on the outer side of sections. [ c o | c o | c o ... ] or [ ... o c | o c | o c ]
--- | `enums.INNER` # Separators on the inner side of sections. [ c i c | c i c | c i c ... ] or [ ... c i c | c i c | c i c ]
--- @alias ComponentType
--- | `enums.A` # Components on the first section. [ A | | ... ] or [ ... | | A ]
--- | `enums.B` # Components on the second section. [ | B | ... ] or [ ... | B | ]
--- | `enums.C` # Components on the third section. [ | | C ... ] or [ ... C | | ]

--==================--
-- Type Declaration --
--==================--

Yatline = {}

local Side = { LEFT = 0, RIGHT = 1 }
local SeparatorType = { OUTER = 0, INNER = 1 }
local ComponentType = { A = 0, B = 1, C = 2 }

--=========================--
-- Variable Initialization --
--=========================--

local section_separator_open
local section_separator_close

local inverse_separator_open
local inverse_separator_close

local part_separator_open
local part_separator_close

local separator_style = { bg = nil, fg = nil }

local style_a
local style_b
local style_c

local style_a_normal_bg
local style_a_select_bg
local style_a_un_set_bg

local permissions_t_fg
local permissions_r_fg
local permissions_w_fg
local permissions_x_fg
local permissions_s_fg

local tab_width

local selected_icon
local copied_icon
local cut_icon

local selected_fg
local copied_fg
local cut_fg

local task_total_icon
local task_succ_icon
local task_fail_icon
local task_found_icon
local task_processed_icon

local task_total_fg
local task_succ_fg
local task_fail_fg
local task_found_fg
local task_processed_fg

local show_background

local section_order = { "section_a", "section_b", "section_c" }

--=================--
-- Component Setup --
--=================--

--- Sets the background of style_a according to the tab's mode.
--- @param mode Mode The mode of the active tab.
--- @see cx.active.mode To get the active tab's mode.
local function set_mode_style(mode)
	if mode.is_select then
		style_a.bg = style_a_select_bg
	elseif mode.is_unset then
		style_a.bg = style_a_un_set_bg
	else
		style_a.bg = style_a_normal_bg
	end
end

--- Sets the style of the component according to the its type.
--- @param component Span Component that will be styled.
--- @param component_type ComponentType Which section component will be in [ a | b | c ].
--- @see Style To see how to style, in Yazi's documentation.
local function set_component_style(component, component_type)
	if component_type == ComponentType.A then
		component:style(style_a):bold()
	elseif component_type == ComponentType.B then
		component:style(style_b)
	else
		component:style(style_c)
	end
end

--- Connects component to a separator.
--- @param component Span Component that will be connected to separator.
--- @param side Side Left or right side of the either header-line or status-line.
--- @param separator_type SeparatorType Where will there be a separator in the section.
--- @return Line line A Line which has component and separator.
local function connect_separator(component, side, separator_type)
	local open, close
	if separator_type == SeparatorType.OUTER and not (separator_style.bg == "reset" and separator_style.fg == "reset") then
		open = ui.Span(section_separator_open)
		close = ui.Span(section_separator_close)

		if separator_style.fg == "reset" then
			if separator_style.bg ~= "reset" and separator_style.bg ~= nil then
				open = ui.Span(inverse_separator_open)
				close = ui.Span(inverse_separator_close)

				separator_style.fg, separator_style.bg = separator_style.bg, separator_style.fg
			else
				return ui.Line { component }
			end
		end
	else
		open = ui.Span(part_separator_open)
		close = ui.Span(part_separator_close)
	end

	open:style(separator_style)
	close:style(separator_style)

	if side == Side.LEFT then
		return ui.Line { component, close }
	else
		return ui.Line { open, component }
	end
end

--==================--
-- Helper Functions --
--==================--

--- Gets the file name from given file extension.
--- @param file_name string The name of a file whose extension will be taken.
--- @return string file_extension Extension of a file.
local function get_file_extension(file_name)
	local extension = file_name:match("^.+%.(.+)$")

	if extension == nil or extension == "" then
		return "null"
	else
		return extension
	end
end

--- Reverse the order of given array
--- @param array Line Array which wants to be reversed.
--- @return table reversed Reversed ordered given array.
local function reverse_order(array)
	local reversed = {}
	for i = #array, 1, -1 do
		table.insert(reversed, array[i])
	end

	return reversed
end

--========================--
-- Component String Group --
--========================--

Yatline.string = {}
Yatline.string.get = {}
Yatline.string.has_separator = true

--- Creates a component from given string according to other parameters.
--- @param string string The text which will be shown inside of the component.
--- @param component_type ComponentType Which section component will be in [ a | b | c ].
--- @return Line line Customized Line which follows desired style of the parameters.
--- @see set_mode_style To know how mode style selected.
--- @see set_component_style To know how component style applied.
function Yatline.string.create(string, component_type)
	local span = ui.Span(" " .. string .. " ")
	set_mode_style(cx.active.mode)
	set_component_style(span, component_type)

	return ui.Line{span}
end

--- Gets the hovered file's name of the current active tab.
--- @return string name Current active tab's hovered file's name.
function Yatline.string.get:hovered_name()
	local hovered = cx.active.current.hovered
	if hovered then
		return hovered.name
	else
		return ""
	end
end

--- Gets the hovered file's path of the current active tab.
--- @return string path Current active tab's hovered file's path.
function Yatline.string.get:hovered_path()
	local hovered = cx.active.current.hovered
	if hovered then
		return ya.readable_path(tostring(hovered.url))
	else
		return ""
	end
end

--- Gets the hovered file's size of the current active tab.
--- @return string size Current active tab's hovered file's size.
function Yatline.string.get:hovered_size()
	local hovered = cx.active.current.hovered
	if hovered then
		return ya.readable_size(hovered:size() or hovered.cha.length)
	else
		return ""
	end
end

--- Gets the hovered file's path of the current active tab.
--- @return string mime Current active tab's hovered file's path.
function Yatline.string.get:hovered_mime()
	local hovered = cx.active.current.hovered
	if hovered then
		return hovered:mime()
	else
		return ""
	end
end

--- Gets the hovered file's extension of the current active tab.
--- @param show_icon boolean Whether or not an icon will be shown.
--- @return string file_extension Current active tab's hovered file's extension.
function Yatline.string.get:hovered_file_extension(show_icon)
	local hovered = cx.active.current.hovered

	if hovered then
		local cha = hovered.cha

		local name
		if cha.is_dir then
			name = "dir"
		else
			name = get_file_extension(hovered.url:name())
		end

		if show_icon then
			local icon = hovered:icon().text
			return icon .. " " .. name
		else
			return name
		end
	else
		return ""
	end
end

--- Gets the path of the current active tab.
--- @return string path Current active tab's path.
function Yatline.string.get:tab_path()
	local cwd = cx.active.current.cwd
	local filter = cx.active.current.files.filter

	local search = cwd.is_search and string.format(" (search: %s", cwd:frag()) or ""

	local suffix
	if not filter then
		suffix = search == "" and search or search .. ")"
	elseif search == "" then
		suffix = string.format(" (filter: %s)", tostring(filter))
	else
		suffix = string.format("%s, filter: %s)", search, tostring(filter))
	end

	return ya.readable_path(tostring(cx.active.current.cwd)) .. suffix
end

--- Gets the mode of active tab.
--- @return string mode Active tab's mode.
function Yatline.string.get:tab_mode()
	local mode = tostring(cx.active.mode):upper()
	if mode == "UNSET" then
		mode = "UN-SET"
	end

	return mode
end

--- Gets the number of files in the current active tab.
--- @return string num_files Number of files in the current active tab.
function Yatline.string.get:tab_num_files()
	return tostring(#cx.active.current.files)
end

--- Gets the cursor position in the current active tab.
--- @return string cursor_position Current active tab's cursor position.
function Yatline.string.get:cursor_position()
	local cursor = cx.active.current.cursor
	local length = #cx.active.current.files

	if length ~= 0 then
		return string.format(" %2d/%-2d", cursor + 1, length)
	else
		return "0"
	end
end

--- Gets the cursor position as percentage which is according to the number of files inside of current active tab.
--- @return string percentage Percentage of current active tab's cursor position and number of percentages.
function Yatline.string.get:cursor_percentage()
	local percentage = 0
	local cursor = cx.active.current.cursor
	local length = #cx.active.current.files
	if cursor ~= 0 and length ~= 0 then
		percentage = math.floor((cursor + 1) * 100 / length)
	end

	if percentage == 0 then
		return " Top "
	elseif percentage == 100 then
		return " Bot "
	else
		return string.format("%3d%% ", percentage)
	end
end

--- Gets the local date or time values.
--- @param format string Format for giving desired date or time values.
--- @return string date Date or time values.
--- @see os.date To see how format works.
function Yatline.string.get:date(format)
	return tostring(os.date(format))
end

--======================--
-- Component Line Group --
--======================--

Yatline.line = {}
Yatline.line.get = {}
Yatline.line.has_separator = false

--- To follow component group naming and functions, returns the given line without any changes.
--- @param line Line The line already pre-defined.
--- @param component_type ComponentType Which section component will be in [ a | b | c ]. Will not be used.
--- @return Line line The given line as an input.
function Yatline.line.create(line, component_type)
	return line
end

--- Creates and returns line component for tabs.
--- @param side Side Left or right side of the either header-line or status-line.
--- @return Line line Customized Line which contains tabs.
--- @see set_mode_style To know how mode style selected.
--- @see set_component_style To know how component style applied.
--- @see connect_separator To know how component and separator connected.
function Yatline.line.get:tabs(side)
	local tabs = #cx.tabs
	local lines = {}

	local in_side
	if side == "left" then
		in_side = Side.LEFT
	else
		in_side = Side.RIGHT
	end

	for i = 1, tabs do
		local text = i
		if tab_width > 2 then
			text = ya.truncate(text .. " " .. cx.tabs[i]:name(), { max = tab_width })
		end

		separator_style = { bg = nil, fg = nil }
		if i == cx.tabs.idx then
			local span = ui.Span(" " .. text .. " ")
			set_mode_style(cx.tabs[i].mode)
			set_component_style(span, ComponentType.A)

			if style_a.bg ~= "reset" or show_background then
				separator_style.fg = style_a.bg
				if show_background then
					separator_style.bg = style_c.bg
				end

				lines[#lines + 1] = connect_separator(span, in_side, SeparatorType.OUTER)
			else
				separator_style.fg = style_a.fg

				lines[#lines + 1] = connect_separator(span, in_side, SeparatorType.INNER)
			end
		else
			local span = ui.Span(" " .. text .. " ")
			if show_background then
				set_component_style(span, ComponentType.C)
			else
				span:style({ fg = style_c.fg })
			end

			if i == cx.tabs.idx - 1 then
				set_mode_style(cx.tabs[i + 1].mode)

				local open, close
				if style_a.bg ~= "reset" or ( show_background and style_c.bg ~= "reset" ) then
					if not show_background or ( show_background and style_c.bg == "reset" ) then
						separator_style.fg = style_a.bg
						if show_background then
							separator_style.bg = style_c.bg
						end

						open = ui.Span(inverse_separator_open)
						close = ui.Span(inverse_separator_close)
					else
						separator_style.bg = style_a.bg
						if show_background then
							separator_style.fg = style_c.bg
						end

						open = ui.Span(section_separator_open)
						close = ui.Span(section_separator_close)
					end
				else
					separator_style.fg = style_c.fg

					open = ui.Span(part_separator_open)
					close = ui.Span(part_separator_close)
				end

				open:style(separator_style)
				close:style(separator_style)

				if in_side == Side.LEFT then
					lines[#lines + 1] = ui.Line { span, close }
				else
					lines[#lines + 1] = ui.Line { open, span }
				end
			else
				separator_style.fg = style_c.fg
				if show_background then
					separator_style.bg = style_c.bg
				end

				lines[#lines + 1] = connect_separator(span, in_side, SeparatorType.INNER)
			end
		end
	end

	if in_side == Side.RIGHT then
		local lines_in_right = {}
		for i = #lines, 1, -1 do
			lines_in_right[#lines_in_right + 1] = lines[i]
		end

		return ui.Line(lines_in_right)
	else
		return ui.Line(lines)
	end
end

--==========================--
-- Component Coloreds Group --
--==========================--

Yatline.coloreds = {}
Yatline.coloreds.get = {}
Yatline.coloreds.has_separator = true

--- Creates a component from given Coloreds according to other parameters.
--- The component it created, can contain multiple strings with different foreground color.
--- @param coloreds Coloreds The array which contains an array which contains text which will be shown inside of the component and its foreground color.
--- @param component_type ComponentType Which section component will be in [ a | b | c ].
--- @return Line line Customized Line which follows desired style of the parameters.
--- @see set_mode_style To know how mode style selected.
--- @see set_component_style To know how component style applied.
function Yatline.coloreds.create(coloreds, component_type)
	set_mode_style(cx.active.mode)

	local spans = {}
	for i, colored in ipairs(coloreds) do
		local span = ui.Span(colored[1])
		set_component_style(span, component_type)
		span:fg(colored[2])

		spans[i] = span
	end

	return ui.Line(spans)
end

--- Gets the hovered file's permissions of the current active tab.
--- @return Coloreds coloreds Current active tab's hovered file's permissions
function Yatline.coloreds.get:permissions()
	local hovered = cx.active.current.hovered

	if hovered then
		local perm = hovered.cha:permissions()

		local coloreds = {}
		coloreds[1] = { " ", "black" }

		for i = 1, #perm do
			local c = perm:sub(i, i)

			local fg = permissions_t_fg
			if c == "-" then
				fg = permissions_s_fg
			elseif c == "r" then
				fg = permissions_r_fg
			elseif c == "w" then
				fg = permissions_w_fg
			elseif c == "x" or c == "s" or c == "S" or c == "t" or c == "T" then
				fg = permissions_x_fg
			end

			coloreds[i + 1] = { c, fg }
		end

		coloreds[#perm + 2] = { " ", "black" }

		return coloreds
	else
		return ""
	end
end

--- Gets the number of selected and yanked files of the active tab.
--- @return Coloreds coloreds Active tab's number of selected and yanked files.
function Yatline.coloreds.get:count()
	local num_yanked = #cx.yanked
	local num_selected = #cx.active.selected

	local yanked_fg, yanked_icon
	if cx.yanked.is_cut then
		yanked_fg = cut_fg
		yanked_icon = cut_icon
	else
		yanked_fg = copied_fg
		yanked_icon = copied_icon
	end

	local coloreds = {
		{ string.format(" %s %d ", selected_icon, num_selected), selected_fg },
		{ string.format(" %s %d ", yanked_icon, num_yanked),     yanked_fg }
	}

	return coloreds
end

--- Gets the number of task states.
--- @return Coloreds coloreds Number of task states.
function Yatline.coloreds.get:task_states()
	local tasks = cx.tasks.progress

	local coloreds = {
		{ string.format(" %s %d ", task_total_icon, tasks.total), task_total_fg },
		{ string.format(" %s %d ", task_succ_icon, tasks.succ),   task_succ_fg },
		{ string.format(" %s %d ", task_fail_icon, tasks.fail),   task_fail_fg }
	}

	return coloreds
end

--- Gets the number of task workloads.
--- @return Coloreds coloreds Number of task workloads.
function Yatline.coloreds.get:task_workload()
	local tasks = cx.tasks.progress

	local coloreds = {
		{ string.format(" %s %d ", task_found_icon, tasks.found),         task_found_fg },
		{ string.format(" %s %d ", task_processed_icon, tasks.processed), task_processed_fg },
	}

	return coloreds
end

--- Gets colored which contains string based component's string and desired foreground color.
--- @param component_name string String based component's name.
--- @param fg Color Desired foreground color.
--- @param params? table Array of parameters of string based component. It is optional.
--- @return Coloreds coloreds Array of solely array of string based component's string and desired foreground color.
function Yatline.coloreds.get:string_based_component(component_name, fg, params)
	local getter = Yatline.string.get[component_name]

	if getter then
		local output
		if params then
			output = getter(Yatline.string.get, table.unpack(params))
		else
			output = getter()
		end


		if output ~= nil and output ~= "" then
			return { { " " .. output .. " ", fg } }
		else
			return ""
		end
	else
		return ""
	end
end

--===============--
-- Configuration --
--===============--

--- Configure separators if it is need to be added to the components.
--- Connects them with each component.
--- @param section_components table Array of components in one of the sections.
--- @param component_type ComponentType Which section component will be in [ a | b | c ].
--- @param in_side Side Left or right side of the either header-line or status-line.
--- @param num_section_b_components integer Number of components in section-b.
--- @param num_section_c_components integer Number of components in section-c.
--- @return table section_line_components Array of line components whether or not connected with separators.
--- @see connect_separator To know how component and separator connected.
local function config_components_separators(section_components, component_type, in_side, num_section_b_components, num_section_c_components)
	local num_section_components = #section_components
	local section_line_components = {}
	for i, component in ipairs(section_components) do
		if component[2] == true then
			separator_style = { bg = nil, fg = nil }

			local separator_type
			if i ~= num_section_components then
				if component_type == ComponentType.A then
					separator_style = style_a
				elseif component_type == ComponentType.B then
					separator_style = style_b
				else
					separator_style = style_c
				end

				separator_type = SeparatorType.INNER
			else
				if component_type == ComponentType.A then
					separator_style.fg = style_a.bg
				elseif component_type == ComponentType.B then
					separator_style.fg = style_b.bg
				else
					separator_style.fg = style_c.bg
				end

				if component_type == ComponentType.A and num_section_b_components ~= 0 then
					separator_style.bg = style_b.bg
				else
					if num_section_c_components == 0 or component_type == ComponentType.C then
						if show_background then
							separator_style.bg = style_c.bg
						end
					else
							separator_style.bg = style_c.bg
					end
				end

				separator_type = SeparatorType.OUTER
			end

			section_line_components[i] = connect_separator(component[1], in_side, separator_type)
		else
			if in_side == Side.LEFT then
				section_line_components[i] = component[1]
			else
				section_line_components[i] = component[1]
			end
		end
	end

	return section_line_components
end

--- Leads the given parameters to the other functions.
--- @param section_a_components table Components array whose components are in section-a of either side.
--- @param section_b_components table Components array whose components are in section-b of either side.
--- @param section_c_components table Components array whose components are in section-c of either side.
--- @param in_side Side Left or right side of the either header-line or status-line.
--- @return table section_a_line_components Array of components whose components are connected to separator and are in section-a of either side.
--- @return table section_b_line_components Array of components whose components are connected to separator and are in section-b of either side.
--- @return table section_c_line_components Array of components whose components are connected to separator and are in section-c of either side.
--- @see config_components_separators To know how separators are configured.
local function config_components(section_a_components, section_b_components, section_c_components, in_side)
	local num_section_b_components = #section_b_components
	local num_section_c_components = #section_c_components

	local section_a_line_components = config_components_separators(section_a_components, ComponentType.A, in_side, num_section_b_components, num_section_c_components)
	local section_b_line_components = config_components_separators(section_b_components, ComponentType.B, in_side, num_section_b_components, num_section_c_components)
	local section_c_line_components = config_components_separators(section_c_components, ComponentType.C, in_side, num_section_b_components, num_section_c_components)

	return section_a_line_components, section_b_line_components, section_c_line_components
end

--- Automatically creates and configures either left or right side according to their config.
--- @param side Config Configuration of either left or right side.
--- @return table section_a_components Components array whose components are in section-a of either side.
--- @return table section_b_components Components array whose components are in section-b of either side.
--- @return table section_c_components Components array whose components are in section-c of either side.
local function config_side(side)
	local section_a_components = {}
	local section_b_components = {}
	local section_c_components = {}

	for _, section in ipairs(section_order) do
		local components = side[section]

		local in_section, section_components
		if section == "section_a" then
			in_section = ComponentType.A
			section_components = section_a_components
		elseif section == "section_b" then
			in_section = ComponentType.B
			section_components = section_b_components
		else
			in_section = ComponentType.C
			section_components = section_c_components
		end

		for _, component in ipairs(components) do
			local component_group = Yatline[component.type]

			if component_group then
				if component.custom then
					section_components[#section_components + 1] = { component_group.create(component.name, in_section), component_group.has_separator }
				else
					local getter = component_group.get[component.name]

					if getter then
						local output
						if component.params then
							output = getter(component_group.get, table.unpack(component.params))
						else
							output = getter()
						end

						if output ~= nil and output ~= "" then
							section_components[#section_components + 1] = { component_group.create(output, in_section), component_group.has_separator }
						end
					end
				end
			end
		end
	end

	return section_a_components, section_b_components, section_c_components
end

--- Automatically creates and configures either header-line or status-line.
--- @param side Config Configuration of either left or right side.
--- @return table left_components Components array whose components are in left side of the line.
--- @return table right_components Components array whose components are in right side of the line.
--- @see config_side To know how components are gotten from side's config.
--- @see config_components To know how components are configured.
local function config_line(side, in_side)
	local section_a_components, section_b_components, section_c_components = config_side(side)

	local section_a_line_components, section_b_line_components, section_c_line_components = config_components(section_a_components, section_b_components, section_c_components, in_side)

	if in_side == Side.RIGHT then
		section_a_line_components = reverse_order(section_a_line_components)
		section_b_line_components = reverse_order(section_b_line_components)
		section_c_line_components = reverse_order(section_c_line_components)
	end

	local section_a_line = ui.Line(section_a_line_components)
	local section_b_line = ui.Line(section_b_line_components)
	local section_c_line = ui.Line(section_c_line_components)

	if  in_side == Side.LEFT then
		return ui.Line {section_a_line, section_b_line, section_c_line}
	else
		return ui.Line {section_c_line, section_b_line, section_a_line}
	end
end

--- Checks if either header-line or status-line contains components.
--- @param line Config Configuration of either header-line or status-line.
--- @return boolean show_line Returns yes if it contains components, otherwise returns no.
local function show_line(line)
	local total_components = 0

	for _, side in pairs(line) do
		for _, section in pairs(side) do
			total_components = total_components + #section
		end
	end

	return total_components ~= 0
end

--- Creates and configures paragraph which is used as left or right of either
--- header-line or status-line.
--- @param area Rect The area where paragraph will be placed in.
--- @param line? Line The line which used in paragraph. It is optional.
--- @return Paragraph paragraph Configured parapgraph.
local function config_paragraph(area, line)
	local line_array = { line } or {}
	if show_background then
		return ui.Paragraph(area, line_array):style(style_c)
	else
		return ui.Paragraph(area, line_array)
	end
end

return {
	setup = function(_, config)
		config = config or {}

		tab_width = config.tab_width or 20

		local component_positions = config.component_positions or { "header", "tab", "status" }

		show_background = config.show_background or false

		local display_header_line = config.display_header_line
		if display_header_line == nil then
			display_header_line = true
		end

		local display_status_line = config.display_status_line
		if display_status_line == nil then
			display_status_line = true
		end

		local header_line = config.header_line or { left = { section_a = {}, section_b = {}, section_c = {} }, right = { section_a = {}, section_b = {}, section_c = {} } }
		local status_line = config.status_line or { left = { section_a = {}, section_b = {}, section_c = {} }, right = { section_a = {}, section_b = {}, section_c = {} } }

		if config.theme then
			config = config.theme
		end

		if config.section_separator then
			section_separator_open = config.section_separator.open
			section_separator_close = config.section_separator.close
		else
			section_separator_open = ""
			section_separator_close = ""
		end

		if config.inverse_separator then
			inverse_separator_open = config.inverse_separator.open
			inverse_separator_close = config.inverse_separator.close
		else
			inverse_separator_open = ""
			inverse_separator_close = ""
		end

		if config.part_separator then
			part_separator_open = config.part_separator.open
			part_separator_close = config.part_separator.close
		else
			part_separator_open = ""
			part_separator_close = ""
		end

		if config.style_a then
			style_a = { bg = config.style_a.bg_mode.normal, fg = config.style_a.fg }

			style_a_normal_bg = config.style_a.bg_mode.normal
			style_a_select_bg = config.style_a.bg_mode.select
			style_a_un_set_bg = config.style_a.bg_mode.un_set
		else
			style_a = { bg = "white", fg = "black" }

			style_a_normal_bg = "white"
			style_a_select_bg = "brightyellow"
			style_a_un_set_bg = "brightred"
		end

		style_b = config.style_b or { bg = "brightblack", fg =  "brightwhite" }
		style_c = config.style_c or { bg = "black", fg =  "brightwhite" }

		permissions_t_fg = config.permissions_t_fg or "green"
		permissions_r_fg = config.permissions_r_fg or "yellow"
		permissions_w_fg = config.permissions_w_fg or "red"
		permissions_x_fg = config.permissions_x_fg or "cyan"
		permissions_s_fg = config.permissions_s_fg or "white"

		if config.selected then
			selected_fg = config.selected.fg
			selected_icon = config.selected.icon
		else
			selected_fg = "yellow"
			selected_icon = "󰻭"
		end

		if config.copied then
			copied_fg = config.copied.fg
			copied_icon = config.copied.icon
		else
			copied_fg = "green"
			copied_icon = ""
		end

		if config.cut then
			cut_icon = config.cut.icon
			cut_fg = config.cut.fg
		else
			cut_icon = ""
			cut_fg = "red"
		end

		if config.total then
			task_total_icon = config.total.icon
			task_total_fg = config.total.fg
		else
			task_total_icon = "󰮍"
			task_total_fg = "yellow"
		end

		if config.succ then
			task_succ_icon = config.succ.icon
			task_succ_fg = config.succ.fg
		else
			task_succ_icon = ""
			task_succ_fg = "green"
		end

		if config.fail then
			task_fail_icon = config.fail.icon
			task_fail_fg = config.fail.fg
		else
			task_fail_icon = ""
			task_fail_fg = "red"
		end

		if config.found then
			task_found_icon = config.found.icon
			task_found_fg = config.found.fg
		else
			task_found_icon = "󰮕"
			task_found_fg = "blue"
		end

		if config.processed then
			task_processed_icon = config.processed.icon
			task_processed_fg = config.processed.fg
		else
			task_processed_icon = "󰐍"
			task_processed_fg = "green"
		end

		Progress.partial_render = function(self)
			local progress = cx.tasks.progress
			if progress.total == 0 then
				return { config_paragraph(self._area) }
			end

			local gauge = ui.Gauge(self._area)
			if progress.fail == 0 then
				gauge = gauge:gauge_style(THEME.status.progress_normal)
			else
				gauge = gauge:gauge_style(THEME.status.progress_error)
			end

			local percent = 99
			if progress.found ~= 0 then
				percent = math.min(99, ya.round(progress.processed * 100 / progress.found))
			end

			local left = progress.total - progress.succ
			return {
				gauge
				:percent(percent)
				:label(ui.Span(string.format("%3d%%, %d left", percent, left)):style(THEME.status.progress_label)),
			}
		end

		if display_header_line then
			if show_line(header_line) then
				Header.render = function(self)
					local left_line = config_line(header_line.left, Side.LEFT)
					local right_line = config_line(header_line.right, Side.RIGHT)

					return {
						config_paragraph(self._area, left_line),
						ui.Paragraph(self._area, { right_line }):align(ui.Paragraph.RIGHT)
					}
				end

				Header.children_add = function() return {} end
				Header.children_remove = function() return {} end
			end
		else
			Header.render = function() return {} end
		end

		if display_status_line then
			if show_line(status_line) then
				Status.render = function(self)
					local left_line = config_line(status_line.left, Side.LEFT)
					local right_line = config_line(status_line.right, Side.RIGHT)

					return {
						config_paragraph(self._area, left_line),
						ui.Paragraph(self._area, { right_line }):align(ui.Paragraph.RIGHT),
						table.unpack(Progress:render(self._area, right_line:width())),
					}
				end

				Status.children_add = function() return {} end
				Status.children_remove = function() return {} end
			end
		else
			Status.render = function() return {} end
		end

		Root.layout = function(self)
			local constraints = {}
			for _, component in ipairs(component_positions) do
				if (component == "header" and display_header_line) or (component == "status" and display_status_line) then
					table.insert(constraints, ui.Constraint.Length(1))
				elseif component == "tab" then
					table.insert(constraints, ui.Constraint.Fill(1))
				end
			end

			self._chunks = ui.Layout():direction(ui.Layout.VERTICAL):constraints(constraints):split(self._area)
		end

		Root.build = function(self)
			local childrens = {}

			local i = 1
			for _, component in ipairs(component_positions) do
				if component == "header" and display_header_line then
					table.insert(childrens, Header:new(self._chunks[i], cx.active))
					i = i + 1
				elseif component == "tab" then
					table.insert(childrens, Tab:new(self._chunks[i], cx.active))
					i = i + 1
				elseif component == "status" and display_status_line then
					table.insert(childrens, Status:new(self._chunks[i], cx.active))
					i = i + 1
				end
			end

			self._children = childrens
		end
	end,
}
