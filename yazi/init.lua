---@diagnostic disable: undefined-global

-- Draw a full bar around window
function Manager:render(area)
  self.area = area

  local chunks = ui.Layout()
    :direction(ui.Layout.HORIZONTAL)
    :constraints({
      ui.Constraint.Ratio(MANAGER.ratio.parent, MANAGER.ratio.all),
      ui.Constraint.Ratio(MANAGER.ratio.current, MANAGER.ratio.all),
      ui.Constraint.Ratio(MANAGER.ratio.preview, MANAGER.ratio.all),
    })
    :split(area)

  local bar = function(c, x, y)
    x, y = math.max(0, x), math.max(0, y)
    return ui.Bar(ui.Rect({ x = x, y = y, w = ya.clamp(0, area.w - x, 1), h = math.min(1, area.h) }), ui.Bar.TOP)
      :symbol(c)
  end

  return ya.flat({
    -- Borders
    ui.Border(area, ui.Border.ALL):type(ui.Border.ROUNDED),
    ui.Bar(chunks[1], ui.Bar.RIGHT),
    ui.Bar(chunks[3], ui.Bar.LEFT),

    bar("┬", chunks[1].right - 1, chunks[1].y),
    bar("┴", chunks[1].right - 1, chunks[1].bottom - 1),
    bar("┬", chunks[2].right, chunks[2].y),
    bar("┴", chunks[2].right, chunks[1].bottom - 1),

    -- Parent
    Parent:render(chunks[1]:padding(ui.Padding.xy(1))),
    -- Current
    Current:render(chunks[2]:padding(ui.Padding.y(1))),
    -- Preview
    Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
  })
end

-- Show user and hostname in top bar
function Header:host()
  if ya.target_family() ~= "unix" then
    return ui.Line({})
  end
  return ui.Line({ ui.Span(ya.user_name() .. "@" .. ya.host_name()):fg("lightgreen"):bold(true), ui.Span(":") })
end

function Header:render(area)
  self.area = area

  local right = ui.Line({ self:count(), self:tabs() })
  local left = ui.Line({
    self:host(),
    self:cwd(math.max(0, area.w - right:width())):fg("blue"),
    ui.Span("/"):fg("blue"):bold(true),
    ui.Span(tostring(cx.active.current.hovered.name)):fg("white"):bold(true),
  })
  return {
    ui.Paragraph(area, { left }),
    ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
  }
end

-- Show symlink path in status bar
function Status:name()
  local h = cx.active.current.hovered
  if not h then
    return ui.Span("")
  end

  local linked = ""
  if h.link_to ~= nil then
    linked = " -> " .. tostring(h.link_to)
  end
  return ui.Span(" " .. h.name .. linked)
end

-- Remove file size from status bar
function Status:render(area)
  self.area = area

  local left = ui.Line({ self:mode(), self:name() })
  local right = ui.Line({ self:permissions(), self:position() })
  return {
    ui.Paragraph(area, { left }),
    ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
    table.unpack(Progress:render(area, right:width())),
  }
end
