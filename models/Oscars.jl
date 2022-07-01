module Oscars

using Stipple
using StippleUI
using StipplePlotly
using SQLite
using DataFrames

const ALL = "All"
const db = SQLite.DB(joinpath("data", "oscars.db"))

register_mixin(@__MODULE__)

# construct a range between the minimum and maximum number of oscars
const oscars_range = begin
  result = DBInterface.execute(db, "select min(Oscars) as min_oscars, max(Oscars) as max_oscars from movies") |> DataFrame
  UnitRange(result[!,:min_oscars][1], result[!,:max_oscars][1])
end

# construct a range between the minimum and maximim years of the movies
const years_range = begin
  result = DBInterface.execute(db, "select min(Year) as min_year, max(Year) as max_year from movies") |> DataFrame
  UnitRange(result[!,:min_year][1], result[!,:max_year][1])
end

const table_options = DataTableOptions(columns = Column(["Title", "Year", "Oscars", "Country", "Genre", "Director", "Cast"]))

# prepare the options for the various select inputs, using the data from the db
function movie_data(column)
  result = DBInterface.execute(db, "select distinct(`$column`) from movies") |> DataFrame
  c = String[]
  for entry in result[!,Symbol(column)]
    for e in split(entry, ',')
      push!(c, strip(e))
    end
  end
  pushfirst!(c |> unique! |> sort!, ALL)
end

# select the data from the db that matches the filters
function oscars(filters::Vector{<:String} = String[])
  query = "select * from movies where 1"
  for f in filters
    isempty(f) && continue
    query *= " and $f"
  end

  # @debug query

  DBInterface.execute(db, query) |> DataFrame
end

# picks a random movie - should be replaced by the movie selected from the UI #TODO
function selected_movie()
  result = DBInterface.execute(db, "select * from movies order by random() limit 1") |> DataFrame
  data = Dict{String,Any}()
  for col in names(result)
    val = result[1,col]
    data[col] = isa(val, Missing) ? "" : val
  end
  data
end

# checks if the filter is a value from db of placeholder "All"
function validvalue(filters::Vector{<:String})
  [endswith(f, "'%$(ALL)%'") || endswith(f, "'%%'") ? "" : f for f in filters]
end

# processes the plot's data based on filters
function plot_data()
  PlotData( x = (years_range.start:years_range.stop),
            y = (1:10),
            name = "Oscars by year",
            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
          )
end

function plot_data(df)
  df
  [
    PlotData(
      x = df.Runtime,
      y = df.Oscars,
      name = "number of Oscars",
      text = string.(df.Title, "(", df.Year, ")"),
      mode = "markers",
      plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    ),
    PlotData(
      x = df.Runtime,
      y = (x->length(findall(',', x))).(df.Cast),
      name = "number of casts",
      text = string.(df.Title, " (", df.Year, ")"),
      mode = "markers",
      plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
    )
  ]
end

function plot_layout(xtitle, ytitle)
  PlotLayout(
    xaxis = [PlotLayoutAxis(title = xtitle)],
    yaxis = [PlotLayoutAxis(xy = "y", title = ytitle)]
  )
end

export Oscar

@reactive mutable struct Oscar <: ReactiveModel
  filter_oscars::R{Int} = oscars_range.start
  filter_years::R{RangeData{Int}} = RangeData(years_range.start:years_range.stop)
  filter_country::R{String} = ALL
  filter_genre::R{String} = ALL
  filter_director::R{String} = ALL
  filter_cast::R{String} = ALL
  countries::Vector{<:String} = movie_data("Country")
  genres::Vector{<:String} = movie_data("Genre")
  directors::Vector{<:String} = movie_data("Director")
  cast::Vector{<:String} = movie_data("Cast")
  movies::R{DataTable} = DataTable(oscars(), table_options)
  movies_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)
  movies_selection::R{DataTableSelection} = DataTableSelection()
  selected_movie::R{Dict} = selected_movie()
  data::R{Vector{PlotData}} = [plot_data()]
  layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")
  @mixin data::PlotlyEvents
end

Stipple.js_mounted(::Oscar) = watchplots()

function handlers(model::Oscar)
  global hh
  @info "reloading handlers ..."
  hh = model
  onany(model.filter_oscars, model.filter_years, model.filter_country, model.filter_genre, model.filter_director, model.filter_cast, model.isready) do fo, fy, fc, fg, fd, fca, i
    model.isprocessing[] = true
    model.movies[] = DataTable(String[
      "`Oscars` >= '$(fo)'",
      "`Year` between '$(fy.range.start)' and '$(fy.range.stop)'",
      "`Country` like '%$(fc)%'",
      "`Genre` like '%$(fg)%'",
      "`Director` like '%$(fd)%'",
      "`Cast` like '%$(fca)%'"
    ] |> validvalue |> oscars, table_options)
    model.data[] = plot_data(model.movies.data)
    model.layout[] = plot_layout("Runtime [min]", "Number")
    model.isprocessing[] = false
  end

  on(model.data_selected) do data
    selectrows!(model, :movies, getindex.(data["points"], "pointIndex") .+ 1)
  end

  on(model.movies_selection) do selection
      ii = union(getindex.(selection, "__id")) .- 1
      for n in 1:length(model.data[])
        model["data[$n-1].selectedpoints"] = isempty(ii) ? nothing : ii
      end
      notify(model, js"data")
  end

  on(model.isready) do ready
    ready || return
    @async begin
      sleep(1)
      run(model, watchplots(:OscarStatsOscarsOscar))
    end
  end

  model
end

end