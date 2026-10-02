local screen_w = 800
local screen_h = 600

local max_boids = 100
local max_speed = 5.0
local min_speed = 2.0
local max_force = 0.5

local min_dist = 80.0

local ffi = require("ffi")

local function vec2_limit(vec, max)
    local len = rl.Vector2Length(vec)

    if len > max and len > 0 then
        return rl.Vector2Scale(vec, max / len)
    end

    return vec
end

local function boid_new()
    return
    {
        pos = ffi.new("Vector2", rl.GetRandomValue(0, screen_w), rl.GetRandomValue(0, screen_h)),
        vel = ffi.new("Vector2", rl.GetRandomValue(-max_speed, max_speed), rl.GetRandomValue(-max_speed, max_speed))
    }
end

local function separation(boid, boids)
    local steer = rl.Vector2Zero()
    local count = 0

    for i = 1, #boids do
        local dist = rl.Vector2Distance(boid.pos, boids[i].pos)

        if dist > 0 and dist < min_dist then
            local diff = rl.Vector2Subtract(boid.pos, boids[i].pos)
            diff = rl.Vector2Normalize(diff)
            diff = rl.Vector2Scale(diff, 1.0 / dist)
            steer = rl.Vector2Add(steer, diff)
            count = count + 1
        end
    end

    if count > 0 then
        steer = rl.Vector2Scale(steer, 1.0 / count)
        if rl.Vector2Length(steer) > 0 then
            steer = rl.Vector2Scale(rl.Vector2Normalize(steer), max_speed)
            steer = rl.Vector2Subtract(steer, boid.vel)
        end
    end

    return steer 
end

local function alignment(boid, boids)
    local sum = rl.Vector2Zero()
    local count = 0

    for i = 1, #boids do
        local dist = rl.Vector2Distance(boid.pos, boids[i].pos)

        if dist > 0 and dist < min_dist then
            sum = rl.Vector2Add(sum, boids[i].vel)
            count = count + 1
        end
    end

    if count > 0 then
        sum = rl.Vector2Scale(sum, 1.0 / count)
        sum = rl.Vector2Normalize(sum)
        sum = rl.Vector2Scale(sum, max_speed)
        local steer = rl.Vector2Subtract(sum, boid.vel)
        steer = vec2_limit(steer, max_force)
        return steer
    end

    return rl.Vector2Zero()
end

local function cohesion(boid, boids)
    local sum = rl.Vector2Zero()
    local count = 0

    for i = 1, #boids do
        local dist = rl.Vector2Distance(boid.pos, boids[i].pos)

        if dist > 0 and dist < min_dist then
            sum = rl.Vector2Add(sum, boids[i].pos)
            count = count + 1
        end
    end

    if count > 0 then
        sum = rl.Vector2Scale(sum, 1.0 / count)
        sum = rl.Vector2Subtract(sum, boid.pos)
        sum = rl.Vector2Normalize(sum)
        sum = rl.Vector2Scale(sum, max_speed)
        local steer = rl.Vector2Subtract(sum, boid.vel)
        steer = vec2_limit(steer, max_force)
        return steer
    end

    return rl.Vector2Zero()
end

local function boid_update(boid, boids)
    local sep = separation(boid, boids)
    local ali = alignment(boid, boids)
    local coh = cohesion(boid, boids)

    sep = rl.Vector2Scale(sep, 0.08)

    boid.vel = rl.Vector2Add(boid.vel, sep)
    boid.vel = rl.Vector2Add(boid.vel, ali)
    boid.vel = rl.Vector2Add(boid.vel, coh)

    if rl.Vector2Length(boid.vel) > max_speed then
        boid.vel = rl.Vector2Scale(rl.Vector2Normalize(boid.vel), max_speed)
    end

    if rl.Vector2Length(boid.vel) < min_speed then
        boid.vel = rl.Vector2Scale(rl.Vector2Normalize(boid.vel), min_speed)
    end

    boid.pos = rl.Vector2Add(boid.pos, boid.vel)

    if boid.pos.x < 0 then
        boid.pos.x = screen_w
    end

    if boid.pos.x > screen_w then
        boid.pos.x = 0
    end

    if boid.pos.y < 0 then
        boid.pos.y = screen_h
    end

    if boid.pos.y > screen_h then
        boid.pos.y = 0
    end
end

local function boid_draw(boid)
    rl.DrawRectangle(boid.pos.x, boid.pos.y, 4, 4, rl.WHITE)
end

rl.InitWindow(screen_w, screen_h, "boids")
rl.SetTargetFPS(60)

local boids = {}

for i = 1, max_boids do
    table.insert(boids, boid_new())
end

while not rl.WindowShouldClose() do
    for i = 1, max_boids do
        boid_update(boids[i], boids)
    end

    rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for i = 1, max_boids do
            boid_draw(boids[i])
        end

    rl.EndDrawing()
end

rl.CloseWindow()
