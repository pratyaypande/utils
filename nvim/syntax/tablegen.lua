-- Syntax highlighting for LLVM TableGen (.td) files.
--
-- Neovim runs this automatically for every buffer whose filetype is
-- "tablegen" (set for *.td by after/ftdetect/custom_filetypes.lua).
-- Everything is defined with :syntax commands driven from Lua, and colors
-- are linked to standard highlight groups so they follow the active
-- colorscheme (gruvbox, here).
--
-- Reference: https://llvm.org/docs/TableGen/ProgRef.html

-- Guard: don't redefine syntax if it's already loaded for this buffer.
if vim.b.current_syntax then
  return
end

-- Small helper so the rules below read cleanly.
local function syn(cmd)
  vim.cmd("syntax " .. cmd)
end

-- A couple of buffer-local options that make .td editing nicer.
vim.bo.commentstring = "// %s"
vim.bo.comments = "s1:/*,mb:*,ex:*/,://"

-- ---------------------------------------------------------------------------
-- Comments
-- ---------------------------------------------------------------------------
syn([[keyword tgTodo contained TODO FIXME XXX NOTE]])
syn([[match tgComment "//.*$" contains=tgTodo,@Spell]])
syn([[region tgComment start="/\*" end="\*/" contains=tgTodo,@Spell]])

-- ---------------------------------------------------------------------------
-- Preprocessor directives (#define, #ifdef, #ifndef, #else, #endif, include)
-- ---------------------------------------------------------------------------
syn([[match tgPreProc "^\s*#\s*\(define\|ifdef\|ifndef\|else\|endif\)\>"]])
syn([[keyword tgInclude include]])

-- ---------------------------------------------------------------------------
-- Top-level / structural keywords
-- ---------------------------------------------------------------------------
syn([[keyword tgKeyword class def defm defset defvar multiclass let in]])
syn([[keyword tgKeyword foreach if then else assert field dump]])

-- ---------------------------------------------------------------------------
-- Built-in types
-- ---------------------------------------------------------------------------
syn([[keyword tgType bit bits int string list dag code]])

-- ---------------------------------------------------------------------------
-- Boolean / literal constants
-- ---------------------------------------------------------------------------
syn([[keyword tgBoolean true false]])

-- ---------------------------------------------------------------------------
-- Bang operators (!add, !eq, !foreach, !cast, ...). Match any !word so new
-- operators added by LLVM are still highlighted.
-- ---------------------------------------------------------------------------
syn([[match tgBangOperator "!\a\+"]])

-- Paste/anchor operator used in names, e.g. NAME#suffix
syn([[match tgOperator "#"]])

-- ---------------------------------------------------------------------------
-- Numbers
-- ---------------------------------------------------------------------------
syn([[match tgNumber "\<\d\+\>"]])
syn([[match tgNumber "\<0x\x\+\>"]])
syn([[match tgNumber "\<0b[01]\+\>"]])
syn([[match tgNumber "[-+]\?\<\d\+\>"]])

-- ---------------------------------------------------------------------------
-- Strings and code blocks
-- ---------------------------------------------------------------------------
syn([[region tgString start=+"+ skip=+\\"+ end=+"+ contains=@Spell]])
-- [{ ... }] code literals
syn([[region tgCodeBlock start=+\[{+ end=+}\]+]])

-- ---------------------------------------------------------------------------
-- Variable substitution inside strings/names: $var and ${var}
-- ---------------------------------------------------------------------------
syn([[match tgVariable "\$\w\+"]])
syn([[match tgVariable "\${\w\+}"]])

-- ---------------------------------------------------------------------------
-- Class / def / multiclass names (the identifier right after the keyword)
-- ---------------------------------------------------------------------------
syn([[match tgDefName "\%(\<\%(class\|def\|defm\|multiclass\|defset\|defvar\)\s\+\)\@<=\w\+"]])

-- ---------------------------------------------------------------------------
-- Highlight links -> standard groups (colorscheme-agnostic)
-- ---------------------------------------------------------------------------
local links = {
  tgComment      = "Comment",
  tgTodo         = "Todo",
  tgPreProc      = "PreProc",
  tgInclude      = "Include",
  tgKeyword      = "Keyword",
  tgType         = "Type",
  tgBoolean      = "Boolean",
  tgBangOperator = "Function",
  tgOperator     = "Operator",
  tgNumber       = "Number",
  tgString       = "String",
  tgCodeBlock    = "String",
  tgVariable     = "Identifier",
  tgDefName      = "Structure",
}

for from, to in pairs(links) do
  vim.cmd(string.format("highlight default link %s %s", from, to))
end

vim.b.current_syntax = "tablegen"
