---@meta
---@version luajit

---@class snippetNode


-- # Node Reference
-- Node references are used to refer to other nodes in various parts of luasnip's
-- API.
-- For example, argnodes in functionNode, dynamicNode or lambda are
-- node references.
-- These references can be either of:
--   - `number`: the jump-index of the node.
--   This will be resolved relative to the parent of the node this is passed to.
--   (So, only nodes with the same parent can be referenced. This is very easy to
--   grasp, but also limiting)
--   - `absolute_indexer`: the absolute position of the
--   node. This will come in handy if the node that is being referred to is not in the same
--   snippet/snippetNode as the one the node reference is passed to (More in
--   [Absolute Indexer](#absolute-indexer)).
--   - `node`: just the node. Usage of this is discouraged since it can lead to
--   subtle errors (for example, if the node passed here is captured in a closure
--   and therefore not copied with the remaining tables in the snippet; there's a
--  big comment about just this in commit 8bfbd61).
---@alias node_reference number|snippetNode

-- The most direct way to define snippets is `s`:
-- ```lua
-- s({trig="trigger"}, {})
-- ```
-- The `opts`-table, as described here, can also be passed to e.g. `snippetNode`
-- and `indentSnippetNode`.
-- It is also possible to set `condition` and `show_condition` (described in the
-- documentation of the `context`-table) from `opts`. They should, however, not be
---@param context s_content|string Passing a string is equivalent to passing
---@param nodes snippetNode|snippetNode[] A single node or a list of nodes. The nodes that make up the snippet.
---@param opts? s_opts A table with the following valid keys:
function s(context, nodes, opts)
end

--   ```lua
--   {
--   	trig = context
--   }
--   ```
---@class s_content
---@field trig string plain text by default. The only entry that must be given.
---@field name string can be used by e.g. `nvim-compe` to identify the snippet.
---@field dscr string description of the snippet, \n-separated or table for multiple lines.
---@field wordTrig boolean if true, the snippet is only expanded if the word (`[%w_]+`) before the cursor matches the trigger entirely. True by default.
---@field regTrig boolean whether the trigger should be interpreted as a lua pattern. False by default.
---@field docstring string textual representation of the snippet, specified like `dscr`. Overrides docstrings loaded from json.
---@field docTrig string for snippets triggered using a lua pattern: define the trigger that is used during docstring-generation.
---@field hidden boolean hint for completion-engines. If set, the snippet should not show up when querying snippets.
---@field priority number positive number, Priority of the snippet, 1000 by default. Snippets with high priority will be matched to a trigger before those with a lower one. The priority for multiple snippets can also be set in `add_snippets`.
---@field snippetType string should be either `snippet` or `autosnippet` (ATTENTION: singular form is used), decides whether this snippet has to be triggered by `ls.expand()` or whether is triggered automatically (don't forget to set `ls.config.setup({ enable_autosnippets = true })` if you want to use this feature). If unset it depends on how the snippet is added of which type the snippet will be.
---`@param`: `line_to_cursor` `string` the line up to the cursor.
---`@param`: `matched_trigger` `string` the fully matched trigger (can be retrieved from `line_to_cursor`, but we already have that info here :D)
---`@param`: captures table if the trigger is pattern, this list contains the capture-groups. Again, could be computed from `line_to_cursor`, but we already did so.
---@field condition fun(line_to_cursor:string, matched_trigger: string, captures: string): boolean
---`@param`: line_to_cursor string, the line up to the cursor.
-- This function is (should be) evaluated by completion engines, indicating
-- whether the snippet should be included in current completion candidates.
--    Defaults to a function returning `true`.
--    This is different from `condition` because `condition` is evaluated by
--    LuaSnip on snippet expansion (and thus has access to the matched trigger and
-- captures), while `show_condition` is (should be) evaluated by the
-- completion engines when scanning for available snippet candidates.
---@field show_condition fun(line_to_cursor): boolean

---@class s_opts
-- 	`callbacks` should be set as follows:
-- 	For example: to print text upon entering the _second_ node of a snippet,
--     ```lua
--     {
--     	-- position of the node, not the jump-index!!
--     	-- s("trig", {t"first node", t"second node", i(1, "third node")}).
--     	[2] = {
--     		[events.enter] = function(node, _event_args) print("2!") end
--     	}
--     }
--     ```
--     To register a callback for the snippets' own events, the key `[-1]` may
--     be used.
--     More info on events in [events](#events)
---@field callbacks table Contains functions that are called upon entering/leaving a node of this snippet.
---@field child_ext_opts table Control `ext_opts` applied to the children of this snippet. More info on those in the [ext_opts](#ext_opts)-section.

---@param text string|string[]
---@param node_opts? table
---@return snippetNode
-- The most simple kind of node; just text.
--
-- ```lua
-- s("trigger", { t("Wow! Text!") })
-- ```
--
-- This snippet expands to
--
-- ```
--     Wow! Text!⎵
-- ```
--
-- where ⎵ is the cursor.
-- Multiline strings can be defined by passing a table of lines rather than a
-- string:
--
-- ```lua
-- s("trigger", {
-- 	t({"Wow! Text!", "And another line."})
-- })
-- ```
--
function t(text, node_opts)
end

-- TODO :
-- - `node_opts`: `table`, see [Node](#node)


---@param jump_index number @this determines when this node will be jumped to (see [Basics-Jump-Index](#jump-index)).
---@param text string|string[]? @a single string for just one line, a list with >1 entries for multiple lines. This text will be SELECTed when the `insertNode` is jumped into.
---@param node_opts? table @described in [Node](#node)
---@return snippetNode
-- These Nodes contain editable text and can be jumped to- and from (e.g.
-- traditional placeholders and tabstops, like `$1` in textmate-snippets).
--
-- The functionality is best demonstrated with an example:
--
-- ```lua
-- s("trigger", {
-- 	t({"After expanding, the cursor is here ->"}), i(1),
-- 	t({"", "After jumping forward once, cursor is here ->"}), i(2),
-- 	t({"", "After jumping once more, the snippet is exited there ->"}), i(0),
-- })
-- ```
--
-- The Insert Nodes are visited in order `1,2,3,..,n,0`.
-- (The jump-index 0 also _has_ to belong to an `insertNode`!)
-- So the order of InsertNode-jumps is as follows:
--
-- 1. After expansion, the cursor is at InsertNode 1,
-- 2. after jumping forward once at InsertNode 2,
-- 3. and after jumping forward again at InsertNode 0.
--
-- If no 0-th InsertNode is found in a snippet, one is automatically inserted
-- after all other nodes.
--
-- The jump-order doesn't have to follow the "textual" order of the nodes:
-- ```lua
-- s("trigger", {
-- 	t({"After jumping forward once, cursor is here ->"}), i(2),
-- 	t({"", "After expanding, the cursor is here ->"}), i(1),
-- 	t({"", "After jumping once more, the snippet is exited there ->"}), i(0),
-- })
-- ```
-- The above snippet will behave as follows:
--
-- 1. After expansion, we will be at InsertNode 1.
-- 2. After jumping forward, we will be at InsertNode 2.
-- 3. After jumping forward again, we will be at InsertNode 0.
--
-- An **important** (because here Luasnip differs from other snippet engines) detail
-- is that the jump-indices restart at 1 in nested snippets:
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
--
-- as opposed to e.g. the textmate syntax, where tabstops are snippet-global:
-- ```snippet
-- ${1:First jump} :: ${2: ${3:Third jump} : ${4:Fourth jump}}
-- ```
-- (this is not exactly the same snippet of course, but as close as possible)
-- (the restart-rule only applies when defining snippets in lua, the above
-- textmate-snippet will expand correctly when parsed).
--
-- If the `jump_index` is `0`, replacing its' `text` will leave it outside the
-- `insertNode` (for reasons, check out Luasnip#110).
function i(jump_index, text, node_opts)
end

-- - `argnodes_text` during function evaluation:
---`fun(argnode_text: string[][], parent: Node, user_args1: any, ...: any) : string|string[]`
---     `@param` `argnode_text` `string[][]` the text currently contained in the argnodes
---     (e.g. `{{line1}, {line1, line2}}`). The snippet indent will be removed from
---     all lines following the first.
---
---     `@param` `parent` The immediate parent of the `functionNode`.
---     It is included here as it allows easy access to some information that could
---     be useful in functionNodes (see [Snippets-Data](#data) for some examples).
---     Many snippets access the surrounding snippet just as `parent`, but if the
---     `functionNode` is nested within a `snippetNode`, the immediate parent is a
---     `snippetNode`, not the surrounding snippet (only the surrounding snippet
---     contains data like `env` or `captures`).
---
---     `@param` user_args The `user_args` passed in `opts`. Note that there may be multiple user_args
---     (e.g. `user_args1, ..., user_argsn`).
---
---     `fn` shall return a string, which will be inserted as is, or a table of
---     strings for multiline strings, where all lines following the first will be
---     prefixed with the snippets' indentation.
---@param fn fun(argnode_text: string[][], parent: snippetNode, user_args1: any, ...: any) : string|string[]
---@param argnodes_text? node_reference[] the text currently contained in the argnodes
---@param argnode_references? node_reference[] the node references of the argnodes
---@return snippetNode
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
-- **Examples**:
--
-- - Use captures from the regex trigger using a functionNode:
--
--   ```lua
--   s({trig = "b(%d)", regTrig = true},
--   	f(function(args, snip) return
--   		"Captured Text: " .. snip.captures[1] .. "." end, {})
--   )
--   ```
--
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
--
--   At `--here`, `args` would look as follows (provided no text was changed after
--   expansion):
--   ```lua
--   args = {
--   	{"first_line_of_second", "second_line_of_second"},
--   	{"text_of_first"}
--   }
--   ```
function f(fn, argnodes_text, argnode_references, node_opts)
end

-- SnippetNodes directly insert their contents into the surrounding snippet.
-- This is useful for `choiceNode`s, which only accept one child, or
-- `dynamicNode`s, where nodes are created at runtime and inserted as a
-- `snippetNode`.
--
-- Their syntax is similar to `s`, however, where snippets require a table
-- specifying when to expand, `snippetNode`s, similar to `insertNode`s, expect
-- a jump-index.
--
-- ```lua
--  s("trig", sn(1, {
--  	t("basically just text "),
--  	i(1, "And an insertNode.")
--  }))
-- ```
--   which are further explained in [Snippets](#snippets).
---@param jump_index number? since snippetNodes can be jumped to, they need a jump-index (Info in [Basics-Jump-Index](#jump-index)).
--   Note that `snippetNode`s don't accept an `i(0)`, so the jump-indices of the nodes
--   inside them have to be in `1,2,...,n`.
---@param nodes snippetNode[]|snippetNode the nodes. A list of nodes will be turned into a `snippetNode`.
-- - `node_opts`: `table`: again, the keys common to all nodes (documented in
--   [Node](#node)) are supported, but also
--   - `callbacks`,
--   - `child_ext_opts` and
--   - `merge_child_ext_opts`,
---@param node_opts table
---@return snippetNode
function sn(jump_index, nodes, node_opts)
end

--- FIXME :

---@param jump_index number since choiceNodes can be jumped to, they need a jump-index (Info in [Basics-Jump-Index](#jump-index)).
---@param choices snippetNode[]|snippetNode the choices. The first will be initialliy active. A list of nodes will be turned into a `snippetNode`.
---@param node_opts? table
---@return snippetNode
-- ChoiceNodes allow choosing between multiple nodes.
--
-- ```lua
--  s("trig", c(1, {
--  	t("Ugh boring, a text node"),
--  	i(nil, "At least I can edit something now..."),
--  	f(function(args) return "Still only counts as text!!" end, {})
--  }))
-- ```
--
-- - `node_opts`: `table`. `choiceNode` supports the keys common to all nodes
--   described in [Node](#node), and one additional key:
--   - `restore_cursor`: `false` by default. If it is set, and the node that was
--     being edited also appears in the switched to choice (can be the case if a
--     `restoreNode` is present in both choice) the cursor is restored relative to
--     that node.
--     The default is `false` as enabling might lead to decreased performance. It's
--     possible to override the default by wrapping the `choiceNode` constructor
--     in another function that sets `opts.restore_cursor` to `true` and then using
--     that to construct `choiceNode`s:
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
-- Jumpable nodes that normally expect an index as their first parameter don't
-- need one inside a choiceNode; their jump-index is the same as the choiceNodes'.
--
-- As it is only possible (for now) to change choices from within the choiceNode,
-- make sure that all of the choices have some place for the cursor to stop at!
--
-- This means that in `sn(nil, {...nodes...})` `nodes` has to contain e.g. an
-- `i(1)`, otherwise luasnip will just "jump through" the nodes, making it
-- impossible to change the choice.
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
-- The active choice for a choiceNode can be changed by either calling one of
-- `ls.change_choice(1)` (forwards) or `ls.change_choice(-1)` (backwards), or by
-- calling `ls.set_choice(choice_indx)`.
--
-- One way to easily interact with choiceNodes is binding `change_choice(1/-1)` to
-- keys:
--
-- Apart from this, there is also a picker (see [select_choice](#select_choice)
-- where no cycling is necessary and any choice can be selected right away, via
-- `vim.ui.select`.
function c(jump_index, choices, node_opts)
end

-- # DynamicNode
-- Very similar to functionNode, but returns a snippetNode instead of just text,
-- which makes them very powerful as parts of the snippet can be changed based on
-- user input.
---@param jump_index number just like all jumpable nodes, its' position in the jump-list ([Basics-Jump-Index](#jump-index)).
---This function is called when the argnodes' text changes. It should generate and return (wrapped inside a `snippetNode`) nodes, which will be inserted at the dynamicNode's place.
---     `@param` `args` `table of text` (`{{"node1line1", "node1line2"}, {"node2line1"}}`) from nodes the `dynamicNode` depends on.
---     `@param` `parent` the immediate parent of the `dynamicNode`.
---     `@param` `old_state` a user-defined table. This table may contain anything; its intended usage is to preserve information from the previously generated `snippetNode`. If the `dynamicNode` depends on other nodes, it may be reconstructed, which means all user input (text inserted in `insertNodes`, changed choices) to the previous `dynamicNode` is lost.
--      The `old_state` table must be stored in `snippetNode` returned by
--      the function (`snippetNode.old_state`).
--      The second example below illustrates the usage of `old_state`.
---     `@param` `user_args` passed through from `dynamicNode`-opts; may have more than one argument.
---@param func fun(args: table, parent: snippetNode, old_state: table, user_args: table): snippetNode
--   [Node References](#node-reference) to the nodes the dynamicNode depends on: if any
--   of these trigger an update (for example, if the text inside them
--   changes), the `dynamicNode`s' function will be executed, and the result
--   inserted at the `dynamicNode`s place.
--   (`dynamicNode` behaves exactly the same as `functionNode` in this regard).
---@param node_references? node_reference[]|node_references|nil
---@param opts? table
---@return snippetNode
--
-- **Examples**:
--
-- This `dynamicNode` inserts an `insertNode` which copies the text inside the
-- first `insertNode`.
-- ```lua
-- s("trig", {
-- 	t"text: ", i(1), t{"", "copy: "},
-- 	d(2, function(args)
-- 			-- the returned snippetNode doesn't need a position; it's inserted
-- 			-- "inside" the dynamicNode.
-- 			return sn(nil, {
-- 				-- jump-indices are local to each snippetNode, so restart at 1.
-- 				i(1, args[1])
-- 			})
-- 		end,
-- 	{1})
-- })
-- ```
--
-- This snippet makes use of `old_state` to count the number of updates.
--
-- To store/restore values generated by the `dynamicNode` or entered into
-- `insert/choiceNode`, consider using the shortly-introduced `restoreNode` instead
-- of `old_state`.
--
-- ```lua
-- local function count(_, _, old_state)
-- 	old_state = old_state or {
-- 		updates = 0
-- 	}
--
-- 	old_state.updates = old_state.updates + 1
--
-- 	local snip = sn(nil, {
-- 		t(tostring(old_state.updates))
-- 	})
--
-- 	snip.old_state = old_state
-- 	return snip
-- end
-- ...
--
-- ls.add_snippets("all",
-- 	s("trig", {
-- 		i(1, "change to update"),
-- 		d(2, count, {1})
-- 	})
-- )
-- ```
-- As with `functionNode`, `user_args` can be used to reuse similar `dynamicNode`-
-- functions.
function d(jump_index, func, node_references, opts)
end

-- INFO :RestoreNode

---@param jump_index number when to jump to this node.
---@param key string `restoreNode`s with the same key share their content.
--   Can either be a single node, or a table of nodes (both of which will be
--   wrapped inside a `snippetNode`, except if the single node already is a
--   `snippetNode`).  
--   The content for a given key may be defined multiple times, but if the
--   contents differ, it's undefined which will actually be used.  
--   If a key's content is defined in a `dynamicNode`, it will not be initially
--   used for `restoreNodes` outside that `dynamicNode`. A way around this
--   limitation is defining the content in the `restoreNode` outside the
--   `dynamicNode`.
---@param nodes snippetNode[]|snippetNode
-- This node can store and restore a snippetNode as is. This includes changed
-- choices and changed text. Its' usage is best demonstrated by an example:
--
-- ```lua
-- s("paren_change", {
-- 	c(1, {
-- 		sn(nil, { t("("), r(1, "user_text"), t(")") }),
-- 		sn(nil, { t("["), r(1, "user_text"), t("]") }),
-- 		sn(nil, { t("{"), r(1, "user_text"), t("}") }),
-- 	}),
-- }, {
-- 	stored = {
-- 		-- key passed to restoreNodes.
-- 		["user_text"] = i(1, "default_text")
-- 	}
-- })
-- ```
--
-- The content for a key may also be defined in the `opts`-parameter of the
-- snippet-constructor, as seen in the example above. The `stored`-table accepts
-- the same values as the `nodes`-parameter passed to `r`.
-- If no content is defined for a key, it defaults to the empty `insertNode`.
--
-- An important-to-know limitation of `restoreNode` is that, for a given key, only
-- one may be visible at a time
--
-- The `restoreNode` is especially useful for storing input across updates of a
-- `dynamicNode`. Consider this:
--
-- ```lua
-- local function simple_restore(args, _)
-- 	return sn(nil, {i(1, args[1]), i(2, "user_text")})
-- end
--
-- s("rest", {
-- 	i(1, "preset"), t{"",""},
-- 	d(2, simple_restore, 1)
-- }),
-- ```
--
-- Every time the `i(1)` in the outer snippet is changed, the text inside the
-- `dynamicNode` is reset to `"user_text"`. This can be prevented by using a
-- `restoreNode`:
--
-- ```lua
-- local function simple_restore(args, _)
-- 	return sn(nil, {i(1, args[1]), r(2, "dyn", i(nil, "user_text"))})
-- end
--
-- s("rest", {
-- 	i(1, "preset"), t{"",""},
-- 	d(2, simple_restore, 1)
-- }),
-- ```
-- Now the entered text is stored.
--
-- `restoreNode`s indent is not influenced by `indentSnippetNodes` right now. If
-- that really bothers you feel free to open an issue.
function r(jump_index, key, nodes)
end


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
