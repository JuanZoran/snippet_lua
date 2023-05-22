local snips = new()

-- snips:add('code')
snips:add(s({
    trig = 'h(%d)',
    regTrig = true,
    hidden = true,
}, f(function(_, parent)
    ---@diagnostic disable-next-line: param-type-mismatch
    return ('*'):rep(tostring(parent.snippet.captures[1])) .. ' '
end)))


snips:add(pos('i', '/<++>/'))
snips:add(pos('b', '*<++>*'))
snips:add(pos('u', '_<++>_'))
snips:add(pos('d', '-<++>-'))
-- snips:add(pos('c', '`<++>`'))

-- End Snippets --
return snips
