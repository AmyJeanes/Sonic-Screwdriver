---@meta

-- The glua-api-snippets stub declares only the 3-arg `table.insert(tbl, position, value)`
-- form, so calls like `table.insert(t, x)` against a narrowly-typed `t` mis-resolve and
-- treat `x` as the position. Add the 2-arg append-only overload.
---@diagnostic disable-next-line: duplicate-set-field
---@overload fun(tbl: table, value: any): integer
---@param tbl table
---@param position integer
---@param value any
---@return integer
function table.insert(tbl, position, value) end

-- The glua-api-snippets stub for `Panel:Add` is generic-on-string-class-name:
-- `function Panel:Add(object)` with `@param object \`T\`` and `@return \`T\``. That
-- matches the "create panel by class name" form, but not the "parent an existing
-- Panel" form documented on the same wiki page (https://wiki.facepunch.com/gmod/Panel:Add).
-- Widen `object` to `Panel|string|table` so passing a Panel instance to a container's
-- `:Add` doesn't trip generic-constraint-mismatch. (We lose the generic-T inference
-- on the string-classname form, but no Sonic-Screwdriver call site relies on it.)
---@class Panel
---@field Add fun(self: Panel, object: Panel|string|table): Panel
