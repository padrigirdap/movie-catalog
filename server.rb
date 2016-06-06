require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  @actors = db_connection { |conn| conn.exec("SELECT name, id FROM actors ORDER BY name LIMIT 50;") }
  erb :'actors/index'
end

get '/actors/:id' do
  id = params["id"]

  @actor_info = db_connection { |conn| conn.exec(%(
     SELECT actors.name, movies.title, cast_members.character, movies.id
     FROM cast_members
     INNER JOIN movies
     ON cast_members.movie_id = movies.id
     INNER JOIN actors
     ON cast_members.actor_id = actors.id
     WHERE actors.id = #{id})) }

     erb :'actors/show'
end

get '/movies' do
  @movies = db_connection { |conn| conn.exec(%(
    SELECT movies.title, movies.id, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres
    ON movies.genre_id = genres.id
    LEFT JOIN studios
    ON movies.studio_id = studios.id
    ORDER BY title))}
  erb :'movies/index'
end

get '/movies/:id' do
  movie_id = params["id"]

  @movie_info = db_connection { |conn| conn.exec(%(
    SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, cast_members.character, actors.name AS actor, actors.id AS id
    FROM movies
    INNER JOIN genres
    ON movies.genre_id = genres.id
    INNER JOIN studios
    ON movies.studio_id = studios.id
    JOIN cast_members
    ON cast_members.movie_id = movies.id
    JOIN actors
    ON actors.id = cast_members.actor_id
    WHERE movies.id = #{movie_id}
    ))}

    erb :'movies/show'
end
