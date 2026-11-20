-- Leader должен быть задан до загрузки плагинов
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.mappings")
require("config.langmap").setup()
