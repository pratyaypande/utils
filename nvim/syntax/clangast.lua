-- Syntax highlighting for Clang AST dumps.
--
-- These are the textual dumps produced by:
--     clang -Xclang -ast-dump -fsyntax-only foo.cpp
-- saved to a *.ast file (mapped to filetype "clangast" by
-- after/ftdetect/custom_filetypes.lua).
--
-- Colors are linked to standard highlight groups so they follow the active
-- colorscheme (gruvbox, here). The design keeps *metadata* (tree glyphs, hex
-- node addresses, source locations) dim, so the node kinds and types pop.
--
-- Example line this highlights:
--   | `-DeclRefExpr 0x55.. <col:13> 'int' lvalue ParmVar 0x55.. 'a' 'int'

if vim.b.current_syntax then
  return
end

local function syn(cmd)
  vim.cmd("syntax " .. cmd)
end

-- ---------------------------------------------------------------------------
-- Tree drawing glyphs at the start of each line: "| | `-", "|-", etc.
-- Matches the leading run of space / '|' / '-' / '`'.
-- ---------------------------------------------------------------------------
syn([[match astTree "^[-| `]*"]])

-- ---------------------------------------------------------------------------
-- Hex node addresses (0x55f8...) -- pure noise, kept dim.
-- ---------------------------------------------------------------------------
syn([[match astAddress "\<0x\x\+\>"]])

-- ---------------------------------------------------------------------------
-- Quoted types / spellings: 'int', 'char *', 'int (int, int)'
-- A region so its contents aren't re-highlighted by the node/keyword rules.
-- ---------------------------------------------------------------------------
syn([[region astQuoted start=+'+ end=+'+ oneline]])

-- ---------------------------------------------------------------------------
-- Source locations
--   <line:2:1, line:5:1>, <col:9, col:13>, <<invalid sloc>>, </path:1:1, col:3>
-- and bare forms: col:8   line:2:5
-- ---------------------------------------------------------------------------
syn([[match astLoc "<[^>]*>>\?"]])
syn([[match astLoc "\<\%(line\|col\):\d\+\%(:\d\+\)\?"]])

-- Cast kinds like <LValueToRValue>, <IntegralCast> (single CamelCase word).
-- Defined AFTER astLoc so it wins for the <Word> case.
syn([[match astCast "<\u\w*>"]])

-- ---------------------------------------------------------------------------
-- Node kinds. A generic CamelCase fallback is defined first; the suffix-based
-- rules below override it (later-defined items win at the same position).
-- ---------------------------------------------------------------------------
syn([[match astNode     "\<\u\w*\>"]])
syn([[match astExpr     "\<\u\w*Expr\>"]])
syn([[match astStmt     "\<\u\w*Stmt\>"]])
syn([[match astDecl     "\<\u\w*Decl\>"]])
syn([[match astTypeNode "\<\u\w*Type\>"]])
syn([[match astOperator "\<\u\w*Operator\>"]])
syn([[match astLiteral  "\<\u\w*Literal\>"]])
syn([[match astAttrNode "\<\u\w*Attr\>"]])
syn([[match astComment  "\<\u\w*Comment\>"]])

-- Suffix-less structural nodes that don't fit the CamelCase-suffix rules:
--   * DefinitionData sub-records (special member functions on a class)
--   * template / ctor / name-qualifier helper nodes
--   * bare reference-target kinds inside DeclRefExpr (ParmVar, Var, ...)
syn([[keyword astDecl DefinitionData DefaultConstructor CopyConstructor MoveConstructor]])
syn([[keyword astDecl CopyAssignment MoveAssignment Destructor CXXRecord]])
syn([[keyword astDecl CXXCtorInitializer TemplateArgument NestedNameSpecifier Overrides]])
syn([[keyword astDecl ParmVar Var Function Field Enum EnumConstant]])

-- ---------------------------------------------------------------------------
-- Lowercase attributes / qualifiers that annotate nodes.
-- ---------------------------------------------------------------------------
-- C++ access specifiers appearing in base-class lists: "public Base"
syn([[keyword astAttr public private protected]])
syn([[keyword astAttr implicit used referenced definition canonical sugar]])
syn([[keyword astAttr cinit callinit listinit nrvo elidable inline]])
syn([[keyword astAttr constexpr consteval virtual explicit static extern]])
syn([[keyword astAttr mutable lvalue rvalue xvalue prvalue dependent]])
syn([[keyword astAttr struct class union enum trivial literal aggregate pod]])

-- ---------------------------------------------------------------------------
-- Highlight links -> standard groups (colorscheme-agnostic)
-- ---------------------------------------------------------------------------
local links = {
  -- metadata: kept dim
  astTree     = "Comment",
  astAddress  = "Comment",
  astLoc      = "Comment",
  astComment  = "SpecialComment",

  -- the interesting bits
  astQuoted   = "String",
  astCast     = "PreProc",
  astNode     = "Identifier",
  astExpr     = "Identifier",
  astDecl     = "Function",
  astStmt     = "Statement",
  astTypeNode = "Type",
  astOperator = "Operator",
  astLiteral  = "Constant",
  astAttrNode = "PreProc",
  astAttr     = "Keyword",
}

for from, to in pairs(links) do
  vim.cmd(string.format("highlight default link %s %s", from, to))
end

vim.b.current_syntax = "clangast"
