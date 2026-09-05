vim.filetype.add({
  pattern = {
    ["makefile*"] =  "make",
    ["%.mk$"] = "make",
    ["%.make$"] = "make",
    ["%.vuerc$"] = "json",
    ["%.bashrc.*"] = "bash",
    ["%.profile.*"] = "bash",
    ["%.i$"] = "cpp",
    ["%.cl$"] = "opencl"
  },
  extension = {
    inc = "cpp",
    def = "cpp",
    td = "tablegen",
    ast = "clangast",
    ll = "llvmir",
    cl = "opencl"
  }
})
