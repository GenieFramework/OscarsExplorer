# Installation

## Instantiate the packages

The Manifest.toml file is committed to the repo to allow replicating the exact branches.

```julia
pkg> instantiate
pkg> update
```

## Running the app

```julia
$ cd to/this/apps/directory
$ julia --project

julia> using Genie
julia> Genie.go()
```

Alternatively you can run `$ ./bin/repl` or `$ ./bin/server` for your OS to start the repl with the app loaded -- or respectively the server.

