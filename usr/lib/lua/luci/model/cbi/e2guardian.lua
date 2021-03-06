--[[

LuCI E2Guardian module

Copyright (C) 2015, Itus Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Author: Marko Ratkaj <marko.ratkaj@sartura.hr>
	Luka Perkov <luka.perkov@sartura.hr>
--------------------------------------------------------------------------------
Modified by Radrunnere42
Date 25 Nov 2016
Changes - Added two new tabs, Blocked filters and Web Filter count. The first now shows blocked domains making it
          easier to see why web sites are not working. The second tab show the amount of ips that are in each selected
					web filter. The logs tab now only shows queried domains.
Files changed/added - /etc/itus/web-filter-counter.sh
                      /tmp/web_filter_counter.log
											/etc/itus/lists/log-gen.sh

Files called - /etc/init.d/dnsmasq restart
               /etc/itus/lists/log-gen.sh
							 /tmp/dns.log
							 /tmp/dns_stopped.log
							 /tmp/web_filter_counter.log
							 /etc/itus/lists/white.list
							 /etc/itus/lists/black.list
							 /etc/itus/web-filter-counter.sh
					     /www/block/index.html
--------------------------------------------------------------------------------
]]--

local fs = require "nixio.fs"
local sys = require "luci.sys"
require "ubus"

m = Map("e2guardian", translate("Web Filter"), translate("Changes may take up to 60 seconds to take effect. Web access may be interrupted during this time."))
m.on_after_commit = function() luci.sys.call("/etc/init.d/dnsmasq restart ") end

m.on_init = function()
	luci.sys.call("sh /etc/itus/lists/log-gen.sh ")
end

s = m:section(TypedSection, "e2guardian")
s.anonymous = true
s.addremove = false

s:tab("tab_basic",		translate("Basic Settings"))
s:tab("tab_white",		translate("White List"))
s:tab("tab_black",		translate("Black List"))
s:tab("tab_logs",			translate("Logs"))
s:tab("tab_filters",	translate("Blocked Filters"))
s:tab("tab_counter",	translate("Web Filter Count"))
s:tab("tab_block",		translate("Block Page"))


----------------- Basic Settings Tab -----------------------


local dummy1, ads, malicious, drugs, religion, gambling, porn, spyware, redirector, downloads, violence, tracker

dummy1 = s:taboption("tab_basic", DummyValue, "dummy1", translate("<b>Content filtering: </b>"))

ads = s:taboption("tab_basic", Flag, "content_ads", translate("Ads"))
ads.default=ads.enabled
ads.rmempty = false

malicious = s:taboption("tab_basic", Flag, "content_malicious", translate("Malicious"))
malicious.default=malicious.disabled
malicious.rmempty = false

drugs = s:taboption("tab_basic",  Flag, "content_drugs", translate("Drugs"))
drugs.default=drugs.disabled
drugs.rmempty = false

religion = s:taboption("tab_basic", Flag, "content_religion", translate("Religion"))
religion.default=religion.disabled
religion.rmempty = false

gamble = s:taboption("tab_basic", Flag, "content_gamble", translate("Gamble"))
gamble.default=gamble.disabled
gamble.rmempty = false

porn = s:taboption("tab_basic", Flag, "content_porn", translate("Porn"))
porn.default=porn.disabled
porn.rmempty = false

spyware = s:taboption("tab_basic", Flag, "content_spyware", translate("Spyware"))
spyware.default=spyware.disabled
spyware.rmempty = false

redirector = s:taboption("tab_basic", Flag, "content_redirector", translate("Redirector"))
redirector.default=redirector.disabled
redirector.rmempty = false

downloads = s:taboption("tab_basic", Flag, "content_downloads", translate("Downloads"))
downloads.default=downloads.disabled
downloads.rmempty = false

violence = s:taboption("tab_basic", Flag, "content_violence", translate("Violence"))
violence.default=violence.disabled
violence.rmempty = false

tracker = s:taboption("tab_basic", Flag, "content_tracker", translate("Tracker"))
tracker.default=tracker.disabled
tracker.rmempty = false


--------------------- WhiteList Tab ------------------------

	config_file0 = s:taboption("tab_white", TextValue, "text6", "")
	config_file0.wrap = "off"
	config_file0.rows = 25
	config_file0.rmempty = false

	function config_file0.cfgvalue()
		local uci = require "luci.model.uci".cursor_state()
		file = "/etc/itus/lists/white.list"

		if file then
			return fs.readfile(file) or ""
		else
			return ""
		end
	end

	function config_file0.write(self, section, value)
		if value then
			local uci = require "luci.model.uci".cursor_state()
			file = "/etc/itus/lists/white.list"
			fs.writefile(file, value:gsub("\r\n", "\n"))
		end
	end

---------------------- Custom Blacklist Tab ------------------------

	config_file2 = s:taboption("tab_black", TextValue, "text7", "")
	config_file2.wrap = "off"
	config_file2.rows = 25
	config_file2.rmempty = false

	function config_file2.cfgvalue()
		local uci = require "luci.model.uci".cursor_state()
		file = "/etc/itus/lists/black.list"
		if file then
			return fs.readfile(file) or ""
		else
			return ""
		end
	end

	function config_file2.write(self, section, value)
		if value then
			local uci = require "luci.model.uci".cursor_state()
			file = "/etc/itus/lists/black.list"
			fs.writefile(file, value:gsub("\r\n", "\n"))
		end
	end

---------------------------- Logs Tab -----------------------------

e2guardian_logfile = s:taboption("tab_logs", TextValue, "lines", "")
e2guardian_logfile.wrap = "off"
e2guardian_logfile.rows = 25
e2guardian_logfile.rmempty = true

function e2guardian_logfile.cfgvalue()
	local uci = require "luci.model.uci".cursor_state()
	file = "/tmp/dns.log"
	if file then
		return fs.readfile(file) or ""
	else
		return "Can't read log file"
	end
end

function e2guardian_logfile.write()
end

---------------------------- filters Tab -----------------------------

filters_logfile = s:taboption("tab_filters", TextValue, "lines", "")
filters_logfile.wrap = "off"
filters_logfile.rows = 25
filters_logfile.rmempty = true

function filters_logfile.cfgvalue()
	local uci = require "luci.model.uci".cursor_state()
		file = "/tmp/dns_stopped.log"
	if file then
		return fs.readfile(file) or ""
	else
		return "Can't read log file"
	end
end

function filters_logfile.write()
end

---------------------------- counter Tab -----------------------------

counter_logfile = s:taboption("tab_counter", TextValue, "lines", "")
counter_logfile.wrap = "off"
counter_logfile.rows = 25
counter_logfile.rmempty = true

function counter_logfile.cfgvalue()
	local uci = require "luci.model.uci".cursor_state()
	sys.call("sh /etc/itus/web-filter-counter.sh &>/dev/null")

	file = "/tmp/web_filter_counter.log"
	if file then
		return fs.readfile(file) or ""
	else
		return "Can't read log file"
	end
end

function counter_logfile.write()
end

---------------------- Custom Block Page ------------------------

config_file4 = s:taboption("tab_block", TextValue, "text9", "")
config_file4.wrap = "off"
config_file4.rows = 25
config_file4.rmempty = false

	function config_file4.cfgvalue()
		local uci = require "luci.model.uci".cursor_state()
		file = "/www/block/index.html"
		if file then
		return fs.readfile(file) or ""
		else
		return ""
		end
end

	function config_file4.write(self, section, value)
		if value then
		local uci = require "luci.model.uci".cursor_state()
		file = "/www/block/index.html"
		fs.writefile(file, value:gsub("\r\n", "\n"))
		end
	end

return m
