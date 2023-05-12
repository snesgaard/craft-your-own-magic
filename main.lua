nw = require "nodeworks"
painter = require "painter"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end
end

