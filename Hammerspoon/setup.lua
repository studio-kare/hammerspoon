local modpath, frameworkspath, prettypath, fullpath, configdir, docstringspath, hasinitfile, autoload_extensions = ...

local userruntime = os.getenv("HOME") .. "/.local/share/hammerspoon/site"

local paths = {
  configdir .. "/?.lua",
  configdir .. "/?/init.lua",
  configdir .. "/Spoons/?.spoon/init.lua",
  package.path,
  modpath .. "/?.lua",
  modpath .. "/?/init.lua",
  userruntime .. "/?.lua",
  userruntime .. "/?/init.lua",
  userruntime .. "/Spoons/?.spoon/init.lua",
}

local cpaths = {
  configdir .. "/?.dylib",
  configdir .. "/?.so",
  package.cpath,
  frameworkspath .. "/?.dylib",
  userruntime .. "/lib/?.dylib",
  userruntime .. "/lib/?.so",
}

package.path = table.concat(paths, ";")
package.cpath = table.concat(cpaths, ";")

print("-- package.path: " .. package.path)
print("-- package.cpath: " .. package.cpath)

local preload = function(m) return function() return require(m) end end
package.preload['hs.application.watcher']   = preload 'hs.libapplicationwatcher'
package.preload['hs.drawing.color']         = preload 'hs.drawing_color'
package.preload['hs.fs.volume']             = preload 'hs.libfsvolume'
package.preload['hs.fs.xattr']              = preload 'hs.libfsxattr'
package.preload['hs.host.locale']           = preload 'hs.host_locale'
package.preload['hs.screen.watcher']        = preload 'hs.libscreenwatcher'
package.preload['hs.uielement.watcher']     = preload 'hs.libuielementwatcher'

return require'hs._coresetup'.setup(...)
