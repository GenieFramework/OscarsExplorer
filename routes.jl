# using Revise
using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using OscarStats.Oscars

Page("/", view = "views/hello.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> Stipple.init(Oscar, debounce = 30) |> Oscars.handlers,
          context = @__MODULE__)

route("err") do
  throw("moo")
end