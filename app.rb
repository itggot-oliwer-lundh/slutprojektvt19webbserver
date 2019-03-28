require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
enable :sessions

get('/') do
    slim(:index)
end
