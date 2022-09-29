(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using OscarsExplorer
const UserApp = OscarsExplorer
OscarsExplorer.main()
