log = Log.open_topic ("s-steamos-arm-sink-rank")

SimpleEventHook {
  name = "steamos-arm/default-sink-rank",
  after = { "default-nodes/find-selected-default-node",
            "default-nodes/find-stored-default-node",
            "default-nodes/find-echo-cancel-default-node" },
  before = { "default-nodes/find-best-default-node" },
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-default-node" },
      Constraint { "default-node.type", "=", "audio.sink" },
    },
  },
  execute = function (event)
    if (event:get_data ("selected-node-priority") or 0) >= 25000 then
      return
    end

    local nodes = event:get_data ("available-nodes")
    nodes = nodes and nodes:parse ()
    if not nodes then
      return
    end

    local selected = event:get_data ("selected-node")
    local best, best_rank = nil, 0
    for _, props in ipairs (nodes) do
      local rank = tonumber (props ["steamos-arm.sink-rank"]) or 0
      local name = props ["node.name"]
      if rank > best_rank or (rank == best_rank and rank > 0 and name == selected) then
        best, best_rank = name, rank
      end
    end

    if best then
      log:debug ("ranked default sink " .. best .. " (" .. best_rank .. ")")
      event:set_data ("selected-node-priority", 20000 + best_rank)
      event:set_data ("selected-node", best)
    end
  end
}:register ()
