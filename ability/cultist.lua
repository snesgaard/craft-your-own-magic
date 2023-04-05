local attack = {
    name = "Attack",
    type = "attack",
    power = 1,
    target = "single/enemy",
}

local buff = {
    name = "Cultist Power",
    type = "status",
    status = "cultist_power",
    power = 2,
    target = "self",
    exhaust = true,
    innate = true
}

return list(buff, attack)
