package.path=os.getenv('HOME')..'/.config/awesome/?.lua;'..os.getenv('HOME')..'/.config/awesome/?/init.lua;'..package.path
require('luarocks.loader')
require('moonscript')
--require('config')
require('moonscript.base').dofile(os.getenv('HOME')..'/.config/awesome/main.moon')
