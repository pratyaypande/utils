-- Syntax highlighting for LLVM IR (.ll) files.
--
-- These are the textual IR modules produced by e.g.:
--     clang -S -emit-llvm foo.c -o foo.ll
--     opt -S ...
-- mapped to filetype "llvmir" by after/ftdetect/custom_filetypes.lua.
--
-- Everything is defined with :syntax commands driven from Lua, and colors
-- are linked to standard highlight groups so they follow the active
-- colorscheme (gruvbox, here). Sigil-prefixed identifiers keep their sigil
-- highlighted with the name so @foo, %bb, !dbg and #0 read as one token.
--
-- Reference: https://llvm.org/docs/LangRef.html
--
-- Example line this highlights:
--   %add = add nsw i32 %a, %b, !dbg !12

if vim.b.current_syntax then
  return
end

local function syn(cmd)
  vim.cmd("syntax " .. cmd)
end

vim.bo.commentstring = "; %s"
vim.bo.comments = ":;"

-- ---------------------------------------------------------------------------
-- Comments: ';' to end of line.
-- ---------------------------------------------------------------------------
syn([[keyword llvmTodo contained TODO FIXME XXX NOTE]])
syn([[match llvmComment ";.*$" contains=llvmTodo,@Spell]])

-- ---------------------------------------------------------------------------
-- Identifiers, keeping the sigil attached to the name.
--   @global   %local   these may be named (@foo) or numbered (@0), and named
--   ones can be quoted (@"has spaces").
-- ---------------------------------------------------------------------------
syn([[match llvmGlobal "@[-a-zA-Z$._][-a-zA-Z$._0-9]*"]])
syn([[match llvmGlobal "@\d\+\>"]])
syn([[match llvmGlobal +@"[^"]*"+]])
syn([[match llvmLocal "%[-a-zA-Z$._][-a-zA-Z$._0-9]*"]])
syn([[match llvmLocal "%\d\+\>"]])
syn([[match llvmLocal +%"[^"]*"+]])

-- Attribute groups: #0, #1 (referenced on functions/calls, defined by
-- "attributes #0 = { ... }").
syn([[match llvmAttrGroup "#\d\+\>"]])

-- Metadata references and named metadata: !12, !dbg, !llvm.loop, !{...}.
-- Kept dim -- metadata is mostly debug/annotation noise while reading IR.
syn([[match llvmMetadata "![-a-zA-Z$._][-a-zA-Z$._0-9]*"]])
syn([[match llvmMetadata "!\d\+\>"]])

-- Labels: a basic-block name at the start of a line ending in ':'.
syn([[match llvmLabel "^[-a-zA-Z$._0-9]\+:"]])

-- ---------------------------------------------------------------------------
-- Types
--   iN integer types (i1, i8, i32, i128, ...), floats, and structural types.
-- ---------------------------------------------------------------------------
syn([[match llvmType "\<i\d\+\>"]])
syn([[keyword llvmType void half bfloat float double fp128 x86_fp80 ppc_fp128]])
syn([[keyword llvmType x86_amx x86_mmx label metadata token ptr opaque]])

-- ---------------------------------------------------------------------------
-- Top-level / structural keywords
-- ---------------------------------------------------------------------------
syn([[keyword llvmKeyword define declare global constant type source_filename]])
syn([[keyword llvmKeyword target datalayout triple module asm attributes]])
syn([[keyword llvmKeyword to align section comdat alias ifunc gc prefix prologue]])
syn([[keyword llvmKeyword personality within uselistorder uselistorder_bb]])
syn([[keyword llvmKeyword blockaddress addrspace unwind]])

-- ---------------------------------------------------------------------------
-- Instructions (opcodes)
-- ---------------------------------------------------------------------------
-- Terminators
syn([[keyword llvmInstruction ret br switch indirectbr invoke callbr resume]])
syn([[keyword llvmInstruction catchswitch catchret cleanupret unreachable]])
-- Unary / binary / bitwise
syn([[keyword llvmInstruction fneg add fadd sub fsub mul fmul udiv sdiv fdiv]])
syn([[keyword llvmInstruction urem srem frem shl lshr ashr and or xor]])
-- Vector / aggregate
syn([[keyword llvmInstruction extractelement insertelement shufflevector]])
syn([[keyword llvmInstruction extractvalue insertvalue]])
-- Memory
syn([[keyword llvmInstruction alloca load store fence cmpxchg atomicrmw]])
syn([[keyword llvmInstruction getelementptr]])
-- Conversion
syn([[keyword llvmInstruction trunc zext sext fptrunc fpext fptoui fptosi]])
syn([[keyword llvmInstruction uitofp sitofp ptrtoint inttoptr bitcast]])
syn([[keyword llvmInstruction addrspacecast]])
-- Other
syn([[keyword llvmInstruction icmp fcmp phi select freeze call va_arg]])
syn([[keyword llvmInstruction landingpad catchpad cleanuppad]])

-- ---------------------------------------------------------------------------
-- Instruction modifiers / flags that decorate opcodes.
-- ---------------------------------------------------------------------------
syn([[keyword llvmModifier nsw nuw exact nnan ninf nsz arcp contract]])
syn([[keyword llvmModifier afn reassoc fast volatile inbounds inrange]])
syn([[keyword llvmModifier atomic acquire release acq_rel seq_cst monotonic]])
syn([[keyword llvmModifier unordered syncscope tail musttail notail]])
-- icmp / fcmp predicates
syn([[keyword llvmModifier eq ne ugt uge ult ule sgt sge slt sle]])
syn([[keyword llvmModifier oeq ogt oge olt ole one ord ueq une uno]])
-- atomicrmw sub-operations
syn([[keyword llvmModifier xchg nand max min umax umin fmax fmin]])

-- ---------------------------------------------------------------------------
-- Linkage, visibility, calling conventions and parameter/function attributes.
-- ---------------------------------------------------------------------------
syn([[keyword llvmAttribute private internal available_externally linkonce]])
syn([[keyword llvmAttribute linkonce_odr weak weak_odr appending common]])
syn([[keyword llvmAttribute extern_weak external hidden protected default]])
syn([[keyword llvmAttribute dso_local dso_preemptable local_unnamed_addr]])
syn([[keyword llvmAttribute unnamed_addr thread_local dllimport dllexport]])
syn([[keyword llvmAttribute ccc fastcc coldcc cc anyregcc preserve_mostcc]])
syn([[keyword llvmAttribute preserve_allcc swiftcc tailcc cxx_fast_tlscc]])
syn([[keyword llvmAttribute zeroext signext inreg byval byref sret elementtype]])
syn([[keyword llvmAttribute noalias nocapture nofree nest returned nonnull]])
syn([[keyword llvmAttribute dereferenceable dereferenceable_or_null swiftself]])
syn([[keyword llvmAttribute swifterror immarg preallocated alignstack allocalign]])
syn([[keyword llvmAttribute noundef readnone readonly writeonly]])
syn([[keyword llvmAttribute argmemonly inaccessiblememonly]])
syn([[keyword llvmAttribute nounwind noreturn norecurse noinline alwaysinline]])
syn([[keyword llvmAttribute optnone optsize minsize uwtable willreturn]])
syn([[keyword llvmAttribute speculatable cold hot mustprogress norecurse]])
syn([[keyword llvmAttribute sanitize_address sanitize_memory sanitize_thread]])
syn([[keyword llvmAttribute ssp sspstrong sspreq safestack shadowcallstack]])
syn([[keyword llvmAttribute nobuiltin builtin convergent naked nonlazybind]])
syn([[keyword llvmAttribute returns_twice noimplicitfloat jumptable]])

-- ---------------------------------------------------------------------------
-- Literal constants
-- ---------------------------------------------------------------------------
syn([[keyword llvmConstant true false null none undef poison zeroinitializer]])

-- ---------------------------------------------------------------------------
-- Numbers: decimals, hex (incl. floating hex 0xK.../0xL...), floats.
-- ---------------------------------------------------------------------------
syn([[match llvmNumber "\<[-+]\?\d\+\>"]])
syn([[match llvmNumber "\<[-+]\?\d\+\.\d*\%([eE][-+]\?\d\+\)\?\>"]])
syn([[match llvmNumber "\<0x[KLMHR]\?\x\+\>"]])

-- ---------------------------------------------------------------------------
-- Strings, incl. the c"..." character-array form.
-- ---------------------------------------------------------------------------
syn([[region llvmString start=+c\?"+ skip=+\\"+ end=+"+ contains=@Spell]])

-- ---------------------------------------------------------------------------
-- Highlight links -> standard groups (colorscheme-agnostic)
-- ---------------------------------------------------------------------------
local links = {
  llvmComment     = "Comment",
  llvmTodo        = "Todo",
  llvmMetadata    = "Comment",   -- metadata kept dim
  llvmGlobal      = "Identifier",
  llvmLocal       = "Identifier",
  llvmAttrGroup   = "PreProc",
  llvmLabel       = "Label",
  llvmType        = "Type",
  llvmKeyword     = "Keyword",
  llvmInstruction = "Statement",
  llvmModifier    = "Operator",
  llvmAttribute   = "StorageClass",
  llvmConstant    = "Constant",
  llvmNumber      = "Number",
  llvmString      = "String",
}

for from, to in pairs(links) do
  vim.cmd(string.format("highlight default link %s %s", from, to))
end

vim.b.current_syntax = "llvmir"
