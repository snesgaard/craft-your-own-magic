local phase = {}

function phase.run(id)
    if not ecs.ensure(phase.run_viewer, id) then return end
    local result_handler = ecs.ensure(phase.run_handler, id)
    local reactions = ecs.ensure(phase.collect_reaction, result_handler)

    for _, react in ipairs(reactions) do
        if not phase.run(react) then return end
    end

    return true
end

function phase.run_action(id)
    local prepare_result = ecs.ensure(phase.run_prepare, id)
    if not prepare_result then return end
    local perform_result = ecs.ensure(phase.run_perform, id)
    if not perform_result then return end

    return true 
end

return phase