-- Focusrite Scarlett 4i4 4th Gen: create the split loopbacks while the card is
-- plugged in. Managed by chezmoi (github.com/eijnar/dotfiles).
--
-- When the card's pro-audio output or input node appears, load one
-- libpipewire-module-loopback per matching entry of the "scarlett-4i4.split"
-- section (wireplumber.conf.d/60-scarlett-4i4-split.conf), with @TARGET@
-- replaced by that node's name. When the node goes away, unload them again.
-- Modeled on WirePlumber's own node/software-dsp.lua.

log = Log.open_topic ("s-custom-scarlett")

local section = Conf.get_section_as_json ("scarlett-4i4.split")
if not section then
  log:warning ("no scarlett-4i4.split section in the config: nothing to do")
  return
end

local config = section:parse (1)
local patterns = {
  output = config["output-node"],
  input = config["input-node"],
}

-- parse (1) returns anything nested deeper as its raw SPA-JSON text, so each
-- level is wrapped in Json.Raw and parsed one level at a time.
local function parse1 (raw)
  return Json.Raw (raw):parse (1)
end

-- { attach = "output"|"input", args = "<loopback args with @TARGET@>" }
local loopbacks = {}
for _, entry in ipairs (config["loopbacks"] and parse1 (config["loopbacks"]) or {}) do
  local e = parse1 (entry)
  if (e.attach == "output" or e.attach == "input") and type (e.args) == "string" then
    loopbacks[#loopbacks + 1] = { attach = e.attach, args = e.args }
  else
    log:warning ("skipping a loopback entry without attach = output|input and args")
  end
end

-- node id -> list of LocalModule objects; dropping the list unloads them
local active = {}

local function attach_side (name)
  for side, pattern in pairs (patterns) do
    if pattern and name:match (pattern) then
      return side
    end
  end
  return nil
end

SimpleEventHook {
  name = "custom/scarlett-4i4-split/create",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
    },
  },
  execute = function (event)
    local node = event:get_subject ()
    local name = node.properties["node.name"] or ""
    local side = attach_side (name)
    if not side or active[node.id] then
      return
    end

    local modules = {}
    for _, lb in ipairs (loopbacks) do
      if lb.attach == side then
        -- plain replacement: node names contain no pattern characters to escape
        local args = lb.args:gsub ("@TARGET@", (name:gsub ("%%", "%%%%")))
        modules[#modules + 1] = LocalModule ("libpipewire-module-loopback", args, {})
      end
    end
    active[node.id] = modules
    log:info (string.format ("%s appeared: created %d %s split(s)", name, #modules, side))
  end
}:register ()

SimpleEventHook {
  name = "custom/scarlett-4i4-split/remove",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-removed" },
    },
  },
  execute = function (event)
    local node = event:get_subject ()
    local modules = active[node.id]
    if not modules then
      return
    end
    active[node.id] = nil
    modules = nil
    collectgarbage ()   -- unload the loopbacks now, not at some later GC run
    log:info (string.format ("node %d went away: removed its splits", node.id))
  end
}:register ()
