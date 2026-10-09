-- Lossless trim in mpv, as LosslessCut does it: c marks where the cut starts, c again where it
-- ends, and ffmpeg copies that part (no re-encoding, so it takes a second) beside the video as
-- <name>-cut-<start>-<end>.<ext>. Shift+c forgets the start. Without re-encoding a cut can only
-- start on a keyframe: it may begin up to a few seconds before the mark.
local mp = require("mp")
local utils = require("mp.utils")

local start = nil

local function stamp(t)
	t = math.floor(t)
	return string.format("%02d.%02d.%02d", math.floor(t / 3600), math.floor(t % 3600 / 60), t % 60)
end

local function say(text)
	mp.osd_message(text, 3)
	mp.msg.info(text)
end

local function cut()
	local now = mp.get_property_number("time-pos")
	local path = mp.get_property("path")
	if not now or not path or path:find("^%a+://") then
		return say("cut: only a file on disk can be cut")
	end
	if not start then
		start = now
		return say("cut from " .. stamp(start) .. ": c again where it ends")
	end
	local from, to = math.min(start, now), math.max(start, now)
	start = nil
	if to - from < 0.5 then
		return say("cut: too short")
	end
	local dir, file = utils.split_path(path)
	local name, ext = file:match("^(.*)(%.[^.]+)$")
	name, ext = name or file, ext or ".mkv"
	local out = utils.join_path(dir, string.format("%s-cut-%s-%s%s", name, stamp(from), stamp(to), ext))
	say("cutting " .. stamp(from) .. " to " .. stamp(to) .. "…")
	mp.command_native_async({
		name = "subprocess",
		capture_stderr = true,
		args = {
			"ffmpeg", "-hide_banner", "-loglevel", "error", "-n",
			"-ss", tostring(from), "-to", tostring(to), "-i", path,
			"-map", "0", "-c", "copy", "-avoid_negative_ts", "make_zero", out,
		},
	}, function(_, result)
		if result and result.status == 0 then
			say("saved " .. select(2, utils.split_path(out)))
		else
			say("cut failed: " .. ((result and result.stderr) or "ffmpeg didn't run"))
		end
	end)
end

mp.add_key_binding("c", "cut", cut)
mp.add_key_binding("C", "cut-forget", function()
	start = nil
	say("cut: start forgotten")
end)
