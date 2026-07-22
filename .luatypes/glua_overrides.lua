---@meta
-- Local annotation overrides for gaps in the provisioned GLua annotations.

-- MatProxyData.bind's second argument is typed as the material NAME string
-- upstream (faithfully scraped from wiki prose), but the engine passes the
-- IMaterial itself - the wiki's own example calls SetVector on it. The ent
-- argument is also nil for world materials. Re-declare with the real types.
-- Fixed on the wiki (2026-07-22); removable once the annotations re-scrape it.
---@diagnostic disable-next-line: duplicate-set-field
---@param matProxyData { name: string, init: (fun(self: table, mat: IMaterial, values: table)), bind: fun(self: table, mat: IMaterial, ent: Entity?) }
function matproxy.Add(matProxyData) end
