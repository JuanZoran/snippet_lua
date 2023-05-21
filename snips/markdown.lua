---@diagnostic disable: undefined-global
-- code snippets
local filetypes = {
    'bash',
    'lua',
    'markdown',
    'cpp',
    'c',
    'json',
    'html',
}
local snips = util.list()

for _, value in ipairs(filetypes) do
    -- TODO :
    snips:add(s(value, fmt(([[
    ```%s
    {}
    ```
    ]]):format(value), i(1))))
end

snips:add(hida('cc', '```\n$1\n```'))

return snips
