require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
enable :sessions

#Detta är det första som laddas in när man öppnar sidan. Den tar en till index hemsidan via slim. 
get('/') do
    slim(:index)
end

#Detta är get routen när man sign upar ett nytt konto. 
get('/sign_up') do
    slim(:sign_up)
end 

#Detta är post routen när man sign upar ett nytt konto. Här används även bcrypt för att kryptera lösenordet som användaren skriver in. Sedan sätts det krypterad lösenordet samt användarnament och ett unikt ID in i databasen för att seda redirecta till startsidan så man kan logga in med uppgifterna man nyss skrivit in. 
post('/sign_up') do
    db = SQLite3::Database.new("db/thampis.db")
    db.results_as_hash = true

    existing_user = db.execute("SELECT username FROM user_login WHERE username=?", params["username"])

    if existing_user.length > 0
        redirect(:sign_up)
    end

    password = BCrypt::Password.create(params['password'])

    db.execute("INSERT INTO user_login(username, password) VALUES (?, ?)", [params["username"], password])

    redirect('/')
end

#Detta är get routen när man ska logga in
get('/login') do
    slim(:login)
end 

#Detta är login routen när man ska logga in. Här jämförs det som man skrivit in i lösenordsfältet med det som finns i databasen. Om det är samma skickas man till sin profilsida där man kan skapa ett inlägg. Om de tinte är samma skickas man tillbaka till förstasidan. 
post('/login') do
    db = SQLite3::Database.new("db/thampis.db")
    db.results_as_hash = true

    session[:inlagg] = db.execute("SELECT text FROM inlagg WHERE username=?", [params["username"]])
    inlagg = session[:inlagg]

    existing_user = db.execute("SELECT password FROM user_login WHERE username=?", [params["username"]])

    if existing_user.length == 0
        redirect(:login)
    end

    password_hash = existing_user[0]["password"]

    password_match = BCrypt::Password.new(password_hash) == params["password"]

    if password_match
        session[:username] = params["username"]
        redirect("/profile/#{params["username"]}")
    else
        redirect(:login)
    end
end

#Detta är get routen när man skickas till profilsidan. Med den skickas även sessions och params så att man kan göra inlägg som är personliga. 
get('/profile/:username') do
    slim(:profile, locals:{user:params["username"], inlagg: session[:inlagg]})
    
end

#Detta är ger routen när man har gjort ett inlägg. 
get('/inlagg') do
    slim(:inlagg, locals:{user:params["username"], inlagg: session[:inlagg]})
end 

#Detta är post routen när man gör ett inlägg. Man lägger in texten som man skrivit in i databasen under användarnamnet. 
post('/inlagg') do
    db = SQLite3::Database.new("db/thampis.db")
    db.results_as_hash = true
    
    db.execute("INSERT INTO inlagg(username, text) VALUES (?,?)", [session[:username], params["text"]])

    session[:inlagg] = db.execute("SELECT text FROM inlagg WHERE username=?", [params["username"]])
    inlagg = session[:inlagg]

    redirect("/profile/#{session[:username]}")
end

#Detta är ger routen för forumet
get('/forum') do
    slim(:forum, locals:{user:params["username"], forum: session[:forum]})
end 

#Detta är post routen för forumet som inte riktigt fungerar. 
post('/forum') do
    db = SQLite3::Database.new("db/thampis.db")
    db.results_as_hash = true
    session[:forum] = db.execute("SELECT * FROM inlagg")
    forum = session[:forum]

    redirect(:forum)
end