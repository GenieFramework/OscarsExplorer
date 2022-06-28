(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using OscarStats
const UserApp = OscarStats
OscarStats.main()
