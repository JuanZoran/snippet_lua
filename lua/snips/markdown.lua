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
local snips = new()

for _, value in ipairs(filetypes) do
    -- TODO :
    snips:add(s('_' .. value, fmt(([[
    ```%s
    {}
    ```
    ]]):format(value), i(1))))
end

snips:add(hida('cc', '```\n$1\n```'))

snips:add(s({
    trig = 'h(%d)',
    regTrig = true,
    hidden = true,
}, f(function(_, parent)
    ---@diagnostic disable-next-line: param-type-mismatch
    return ('#'):rep(tostring(parent.snippet.captures[1])) .. ' '
end)))


snips:add(pos('i', '*<++>*'))
snips:add(pos('b', '**<++>**'))
snips:add(pos('c', '`<++>`'))


snips:add(parse('link', '[${1:desc}](${0:url})'))
snips:add(parse('img', '![${1:desc}](${0:url})'))

return snips
