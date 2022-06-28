using GenieDevTools
using Stipple
using GenieAutoReload

if ( Genie.Configuration.isdev() )
  GenieDevTools.register_routes()
  Stipple.deps!(GenieAutoReload, GenieAutoReload.deps)
  autoreload(pwd())
end
