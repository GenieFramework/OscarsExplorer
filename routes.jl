using Genie
using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using OscarsExplorer.Oscars

if Genie.Configuration.isprod()
  Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StipplePlotly], host = "https://cdn.statically.io/gh/GenieFramework")
end

Page("/", view = "views/hello.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> init_from_storage(Oscar, debounce = 30) |> Oscars.handlers,
          context = @__MODULE__)