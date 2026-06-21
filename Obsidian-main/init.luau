local HatsuTypes = require("./hatsu/Hatsu.d")

return {
    Library = (require("./hatsu/Hatsu") :: any) :: HatsuTypes.Library,
    Types = require("./hatsu/Hatsu.d"),
    SaveManager = require("./hatsu/addons/SaveManager"),
    ThemeManager = require("./hatsu/addons/ThemeManager")
}
