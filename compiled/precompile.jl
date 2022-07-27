using Genie
Genie.loadapp(pwd())

include("packages.jl")

const HTTP = Genie.Renderer.HTTP
const PORT = 50515

function precompile()
  @info "Hitting routes"

  try
    @info "Starting server"
    up(PORT)
  catch
  end

  try
    @info "Making requests"
    HTTP.request("GET", "http://localhost:$PORT")
  catch
  end

  try
    @info "Stopping server"
    Genie.Server.down!()
  catch
  end
end

precompile()