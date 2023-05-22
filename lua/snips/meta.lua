---@meta
---@version luajit

---@class snippetNode


-- # 节点引用
-- 节点引用用于在luasnip的各个部分引用其他节点。
-- 例如，函数节点、动态节点或lambda中的argnodes就是节点引用。
-- 这些引用可以是以下几种：
-- - `number` : 节点的跳转索引。
-- 这将相对于传递此节点的父节点进行解析。
-- （所以，只有具有相同父节点的节点才能被引用。这非常容易理解，但也有限制）
-- - `absolute_indexer` : 节点的绝对位置。
-- 如果被引用的节点不在与传递节点引用的同一个片段/片段节点中，这将非常方便（更多内容在
--[绝对索引器](https://chat.openai.com/?model=gpt-4#absolute-indexer)中）。
-- - `node` : 就是节点。不鼓励使用这个，因为它可能导致微妙的错误（例如，如果这里传递的节点在闭包中捕获
-- 因此并未与片段中的其余表一起复制；在提交8bfbd61中就有关于这个的大评论）。
---@alias nodeRef number|snippetNode


-- 定义片段的最直接方法是 `s` ：
-- ```lua
-- s({trig="trigger"}, {})
-- ```
-- 这里描述的 `opts` -表格也可以传递给例如 `snippetNode` -- 和 `indentSnippetNode` 。
-- 也可以从 `opts` 中设置 `condition` 和 `show_condition` （在 `context` -表格的文档中描述）。然而，它们不应该被
---@param context s_content|string 传递字符串等同于传递一个节点或节点列表。构成片段的节点。
---@param nodes snippetNode|snippetNode[] 
---@param opts? s_opts
function s(context, nodes, opts)
end

--   ```lua
--   {
--   	trig = context
--   }
--   ```
---@class s_content
---@field trig string 默认为纯文本。必须给出的唯一条目。
---@field name string 可以被例如 `nvim-compe` 用来识别片段。
---@field dscr string 片段的描述，\n-分隔或多行表格。
---@field wordTrig boolean 如果为真，只有当光标前的词（ `[%w_]+` ）完全匹配触发器时，片段才会展开。默认为真。
---@field regTrig boolean 触发器是否应被解释为lua模式。默认为假。
---@field docstring string 片段的文本表示，如 `dscr` 所指定。覆盖从json加载的docstrings。
---@field docTrig string 对于使用lua模式触发的片段：定义在生成docstring时使用的触发器。
---@field hidden boolean 完成引擎的提示。如果设置，片段在查询片段时不应显示。
---@field priority number 正数，片段的优先级，默认为1000。优先级高的片段将在优先级较低的片段之前匹配到触发器。多个片段的优先级也可以在 `add_snippets` 中设置。
---@field snippetType string 应该是 `snippet` 或 `autosnippet` （注意：使用单数形式），决定这个片段是否需要通过 `ls.expand()` 触发，或者是否自动触发（如果你想使用这个功能，不要忘记设置 `ls.config.setup({ enable_autosnippets = true })` ）。如果未设置，取决于如何添加片段，片段将是哪种类型。
---`@param`: `line_to_cursor`  `string` 光标位置之前的行。
---`@param`: `matched_trigger`  `string` 完全匹配的触发器（可以从 `line_to_cursor` 中检索，但我们已经有了这个信息:D）
---`@param`: captures table 如果触发器是模式，这个列表包含捕获组。再次，可以从 `line_to_cursor` 计算，但我们已经做过了。
---@field condition fun(line_to_cursor:string, matched_trigger: string, captures: string): boolean
--- `@param` : line_to_cursor string, 光标位置之前的行。
-- 这个函数被完成引擎（应该是）评估，表示是否应该将片段包含在当前的完成候选项中。
-- 默认为返回 `true` 的函数。
-- 这与 `condition` 不同，因为 `condition` 是由LuaSnip在片段扩展时评估的（因此可以访问匹配的触发器和
-- 捕获），而 `show_condition` 是（应该是）在扫描可用片段候选项时由完成引擎评估的。
---@field show_condition fun(line_to_cursor): boolean

---@class s_opts
-- `callbacks` 应该如下设置：
-- 例如：要在片段的_第二_节点进入时打印文本，
--     ```lua
--     {
--     	-- position of the node, not the jump-index!!
--     	-- s("trig", {t"first node", t"second node", i(1, "third node")}).
--     	[2] = {
--     		[events.enter] = function(node, _event_args) print("2!") end
--     	}
--     }
--     ```
-- 要为片段自己的事件注册回调，可以使用键 `[-1]` 。
---@field callbacks table 包含在进入/离开此片段的节点时被调用的函数。
---@field child_ext_opts table 控制应用于此片段的子节点的 `ext_opts` 。在[ext_opts](https://chat.openai.com/?model=gpt-4#ext_opts)部分有更多关于这些的信息。

---@param text string|string[]
---@param node_opts? table
---@return snippetNode
-- 最简单的节点类型；只是文本。
--
-- ```lua
-- s("trigger", { t("Wow! Text!") })
--
-- ```
--
-- 这个片段扩展为
--
-- ```
-- Wow! Text!⎵
--
-- ```
--
-- 其中 ⎵ 是光标。
--
-- 可以通过传递行的表格而不是字符串来定义多行字符串：
--
-- ```lua
-- s("trigger", {
-- 	t({"Wow! Text!", "And another line."})
-- })
-- ```
function t(text, node_opts)
end

---@param jump_index number @这决定了何时跳转到此节点（见[基础-跳转索引](https://chat.openai.com/?model=gpt-4#jump-index)）。
---@param text string|string[]? @单个字符串仅用于一行，具有>1项的列表用于多行。这个文本将在跳入 `insertNode` 时被SELECT选中。
---@param node_opts? table @在[节点]中有说明。
---@return snippetNode
--
-- 这些节点包含可编辑文本，可以被跳转到和跳转出（例如传统的占位符和标签停止，如 textmate-snippets 中的 `$1` ）。
-- 这个功能最好通过示例来展示：
-- ```lua
-- s("trigger", {
--      t({"After expanding, the cursor is here ->"}), i(1),
--      t({"", "After jumping forward once, cursor is here ->"}), i(2),
--      t({"", "After jumping once more, the snippet is exited there ->"}), i(0),
-- })
-- ```
--
-- 插入节点的访问顺序是 `1,2,3,..,n,0` .
-- (跳转索引为 0 的也 _必须_ 属于一个 `insertNode` ！)
-- 所以，插入节点跳转的顺序如下：
--
-- 1. 扩展后，光标位于插入节点 1，
-- 2. 向前跳转一次后，光标位于插入节点 2，
-- 3. 再向前跳转一次，光标位于插入节点 0。
--
-- 如果在一个片段中找不到第 0 个插入节点，会在所有其他节点之后自动插入一个。
--
-- 跳转顺序不必遵循节点的 "文本" 顺序：
-- ```lua
-- s("trigger", {
-- 	t({"After jumping forward once, cursor is here ->"}), i(2),
-- 	t({"", "After expanding, the cursor is here ->"}), i(1),
-- 	t({"", "After jumping once more, the snippet is exited there ->"}), i(0),
-- })
-- ```
--
-- 上述片段的行为如下：
--
-- 1. 扩展后，我们将位于插入节点 1。
-- 2. 向前跳转后，我们将位于插入节点 2。
-- 3. 再向前跳转一次，我们将位于插入节点 0。
--
-- **重要** （因为 Luasnip 在这里与其他片段引擎有所不同）的细节是，在嵌套片段中，跳转索引从 1 重新开始：
-- ```lua
-- s("trigger", {
-- 	i(1, "First jump"),
-- 	t(" :: "),
-- 	sn(2, {
-- 		i(1, "Second jump"),
-- 		t" : ",
-- 		i(2, "Third jump")
-- 	})
-- })
-- ```
-- 与例如 textmate 语法相比，其中 tabstops 是全局的片段：
-- `snippet -- ${1:First jump} :: ${2: ${3:Third jump} : ${4:Fourth jump}} --` -- (当然这并不是完全相同的片段，但是尽可能接近)
-- (重启规则只在用 lua 定义片段时适用，以上的 textmate 片段在解析时会正确展开)。
-- 如果 `jump_index` 是 `0` ，替换它的 `text` 将使其离开 `insertNode` -- (关于原因，请参阅 Luasnip#110)。
function i(jump_index, text, node_opts)
end


---@param fn fun(argnode_text: string[][], parent: snippetNode, user_args1: any, ...: any) : string|string[]
---@param argnodes_text? node_reference[] 当前包含在 argnodes 中的文本
---@param argnode_references? node_reference[] argnodes 的节点引用
---@return snippetNode
-- `argnodes_text` 在函数评估期间：
--- `fun(argnode_text: string[][], parent: Node, user_args1: any, ...: any) : string|string[]` --- `@param`  `argnode_text`  `string[][]` 包含在 argnodes 中的当前文本
--- (例如 `{{line1}, {line1, line2}}` )。片段缩进将从所有后续行中删除。
---
--- `@param`  `parent`  `functionNode` 的直接父级。
--- 这里包含它是因为它可以方便地访问可能在 functionNodes 中有用的一些信息（参见[Snippets-Data](https://chat.openai.com/?model=gpt-4#data)中的一些示例）。
--- 许多片段只是将周围的片段作为 `parent` 访问，但是如果 `functionNode` 嵌套在 `snippetNode` 中，
--- 那么直接的父级是 `snippetNode` ，而不是周围的片段（只有周围的片段包含像 `env` 或 `captures` 这样的数据）。
---
---
--- `@param` user_args 在 `opts` 中传入的 `user_args` 。注意可能有多个 user_args
--- (例如 `user_args1, ..., user_argsn` )。
---
--- `fn` 应返回一个字符串，将按原样插入，或者一个多行字符串的字符串表，
--- 其中所有后续行将以片段的缩进为前缀。
-- ```lua
-- local function fn(
--   args,     -- text from i(2) in this example i.e. { { "456" } }
--   parent,   -- parent snippet or parent node
--   user_args -- user_args from opts.user_args
-- )
--    return '[' .. args[1][1] .. user_args .. ']'
-- end
--
-- s("trig", {
--   i(1), t '<-i(1) ',
--   f(fn,  -- callback (args, parent, user_args) -> string
--     {2}, -- node indice(s) whose text is passed to fn, i.e. i(2)
--     { user_args = { "user_args_value" }} -- opts
--   ),
--   t ' i(2)->', i(2), t '<-i(2) i(0)->', i(0)
-- })
-- ```
--
-- **示例** :
--
-- - 使用 functionNode 从正则触发器获取捕获：
--
--   ```lua
--   s({trig = "b(%d)", regTrig = true},
--   	f(function(args, snip) return
--   		"Captured Text: " .. snip.captures[1] .. "." end, {})
--   )
--   ```
--
--   ```lua
--   s("trig", {
--   	i(1, "text_of_first"),
--   	i(2, {"first_line_of_second", "second_line_of_second"}),
--   	f(function(args, snip)
--   		--here
--   	-- order is 2,1, not 1,2!!
--   	end, {2, 1} )})
--   ```
-- 在 `--here` ， `args` 将如下所示 (假设在扩展后没有改变文本)：
--   ```lua
--   args = {
--   	{"first_line_of_second", "second_line_of_second"},
--   	{"text_of_first"}
--   }
--   ```
function f(fn, argnodes_text, argnode_references, node_opts)
end

-- SnippetNodes 直接将它们的内容插入到周围的片段中。
-- 对于 `choiceNode` 和 `dynamicNode` 很有用，其中节点在运行时创建并作为 `snippetNode` 插入。
-- 它们的语法类似于 `s` ，然而，其中片段需要一个表来指定何时扩展， `snippetNode` 和 `insertNode` 一样，期望跳跃索引。
--
-- ```lua
--  s("trig", sn(1, {
--  	t("basically just text "),
--  	i(1, "And an insertNode.")
--  }))
-- ```
---@param jump_index number? 由于可以跳到 snippetNodes，因此它们需要一个跳跃索引 (在[Basics-Jump-Index](https://chat.openai.com/?model=gpt-4#jump-index)中的信息)。
-- 注意 `snippetNode` 不接受 `i(0)` ，因此其中的节点的跳跃索引必须在 `1,2,...,n` 中。
---@param nodes snippetNode[]|snippetNode 节点。节点列表将转化为一个 `snippetNode` 。
-- - `node_opts` : `table` : 同样，支持所有节点的常见键（在
--[Node]中记录），还有
-- - `callbacks` ,
-- - `child_ext_opts` 和
-- - `merge_child_ext_opts` ,
---@param node_opts table
---@return snippetNode
function sn(jump_index, nodes, node_opts)
end

--- FIXME :

---@param jump_index number 因为可以跳到 choiceNodes，所以它们需要一个跳跃索引 (在[Basics-Jump-Index](https://chat.openai.com/?model=gpt-4#jump-index)中的信息)。
---@param choices snippetNode[]|snippetNode 选择项。首选项将首先被激活。节点列表将被转化为 `snippetNode` 。
---@param node_opts? table
---@return snippetNode
-- ChoiceNodes 允许在多个节点中进行选择。
--
-- ```lua
--  s("trig", c(1, {
--  	t("Ugh boring, a text node"),
--  	i(nil, "At least I can edit something now..."),
--  	f(function(args) return "Still only counts as text!!" end, {})
--  }))
-- ```
--
-- - `node_opts` : `table` . `choiceNode` 支持在[Node]中描述的所有节点的公共键，以及一个附加键：
--   - `restore_cursor`: `默认为 `false` 。如果设置了它，并且正在编辑的节点也出现在切换到的选项中（如果在两个选择中都有 `restoreNode` ，就可能是这种情况），则相对于该节点恢复光标。
--      默认为 `false` ，因为启用可能会导致性能下降。通过将 `choiceNode` 构造函数包装在另一个函数中，将 `opts.restore_cursor` 设置为 `true` ，然后使用该函数构造 `choiceNode` ，可以覆盖默认值
--     ```lua
--     local function restore_cursor_choice(pos, choices, opts)
--         if opts then
--             opts.restore_cursor = true
--         else
--             opts = {restore_cursor = true}
--         end
--         return c(pos, choices, opts)
--     end
--     ```
--
-- 在 choiceNode 内部，通常期望第一个参数为索引的跳跃节点不需要一个；它们的跳跃索引与 choiceNodes' 相同。
--
-- 因为只有可能（目前）从 choiceNode 内部改变选择，所以请确保所有的选择都有一些光标可以停止的地方！
-- 这意味着在 `sn(nil, {...nodes...})` 中 `nodes` 必须包含例如一个 `i(1)` ，否则 luasnip 将只是 "跳过" 这些节点，使得无法改变选择。
--
-- ```lua
-- c(1, {
-- 	t"some text", -- textNodes are just stopped at.
-- 	i(nil, "some text"), -- likewise.
-- 	sn(nil, {t"some text"}) -- this will not work!
-- 	sn(nil, {i(1), t"some text"}) -- this will.
-- })
-- ```
--
-- choiceNode 的活动选择可以通过调用 `ls.change_choice(1)` (向前) 或 `ls.change_choice(-1)` (向后)，或者通过调用 `ls.set_choice(choice_indx)` 来改变。
--
-- 一个简单的与 choiceNodes 交互的方式是将 `change_choice(1/-1)` 绑定到键：
--
-- 除此之外，还有一个选择器 -- 其中无需循环就可以立即选择任何选项，通过按下对应的数字即可选中。
function c(jump_index, choices, node_opts)
end

-- # DynamicNode
-- 与FunctionNode非常相似，但返回的是SnippetNode而不仅仅是文本，
-- 这使得它们在基于用户输入改变部分片段的情况下非常强大。
---@param jump_index number 正如所有可以跳转的节点，它在跳转列表中的位置([基础-跳跃-索引](#jump-index))。
---当argnodes的文本更改时调用此函数。它应生成并返回（包装在`snippetNode`内）节点，这些节点将被插入到dynamicNode的位置。
---     `@param` `args` `表格 of text` (`{{"node1line1", "node1line2"}, {"node2line1"}}`) 来自`dynamicNode`依赖的节点。
---     `@param` `parent` `dynamicNode`的直接父节点。
---     `@param` `old_state` 用户定义的表格。此表格可以包含任何内容；其预期用途是保存从以前生成的`snippetNode`的信息。如果`dynamicNode`依赖于其他节点，它可能会被重构，这意味着所有用户输入（在`insertNodes`中插入的文本，更改的选择）到之前的`dynamicNode`都将丢失。
--      `old_state`表格必须存储在函数返回的`snippetNode`中（`snippetNode.old_state`）。
--      下面的第二个例子说明了`old_state`的使用。
---     `@param` `user_args` 从`dynamicNode`-opts中传递；可能有多个参数。
---@param func fun(args: table, parent: snippetNode, old_state: table, user_args: table): snippetNode
--   [节点引用](#node-reference) 到`dynamicNode`依赖的节点：如果这些触发了更新
--   （例如，如果其中的文本发生变化），`dynamicNode`的函数将被执行，结果
--   将插入到`dynamicNode`的位置。
--   （在这方面，`dynamicNode`的行为与`functionNode`完全相同）。
---@param node_references? node_reference[]|node_references|nil
---@param opts? table
--
-- **示例**：
--
-- 这个`dynamicNode`插入一个`insertNode`，它复制第一个`insertNode`内的文本。
-- ```lua
-- s("trig", {
--  t"text: ", i(1), t{"", "copy: "},
--  d(2, function(args)
--          -- 返回的snippetNode不需要位置；它被插入
--          -- "在"dynamicNode内部。
--          return sn(nil, {
--              -- 跳跃索引对每个snippetNode都是本地的，所以重新开始为1。
--              i(1, args[1])
--          })
--      end,
--  {1})
-- })
-- ```
--
-- 这个片段使用`old_state`来计数更新的数量。
--
-- 要存储/恢复由`dynamicNode`生成的值或输入到
-- `insert/choiceNode`，考虑使用即将引入的`restoreNode`而不是`old_state`。
--
-- ```lua
-- local function count(_, _, old_state)
--  old_state = old_state or {
--      updates = 0
--  }
--
--  old_state.updates = old_state.updates + 1
--
--  local snip = sn(nil, {
--      t(tostring(old_state.updates))
--  })
--
--  snip.old_state = old_state
--  return snip
-- end
-- ...
--
-- ls.add_snippets("all",
--  s("trig", {
--      i(1, "change to update"),
--      d(2, count, {1})
--  })
-- )
-- ```
-- 就像`functionNode`，`user_args`可以用来重用相似的`dynamicNode`-
--函数。
function d(jump_index, func, node_references, opts)
end


_G.r = require 'luasnip.nodes.restoreNode'.R

_G.events = require 'luasnip.util.events'
_G.ai = require 'luasnip.nodes.absolute_indexer'
_G.fmt = require 'luasnip.extras.fmt'.fmt
_G.fmta = require 'luasnip.extras.fmt'.fmta
_G.conds = require 'luasnip.extras.expand_conditions'
_G.postfix = require 'luasnip.extras.postfix'.postfix
_G.types = require 'luasnip.util.types'
_G.ms = require 'luasnip.nodes.multiSnippet'.new_multisnippet


_G.extras = require 'luasnip.extras'
_G.l = extras.lambda
_G.rep = extras.rep
_G.p = extras.partial
_G.m = extras.match
_G.n = extras.nonempty
_G.dl = extras.dynamic_lambda


---Snippet mete like snippet
---@param trig? string|table -- Trigger string.
---@param pattern string -- Pattern to replace with. $[index] | ${[index]:[default_text]}
---@param opts? table -- Options for snippet.
---@return snippetNode|snippetNode[]
function parse(trig, pattern, opts)
end

-- Custom functions

local mod = require 'snippet_lua'
_G.pos    = mod.pos
_G.dyn    = mod.dyn
_G.opt    = mod.opt
_G.hid    = mod.hid
_G.hida   = mod.hida
_G.new    = mod.new
