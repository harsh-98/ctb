import express from 'express';
import fs from 'fs';
import path from 'path';
import cookieParser from 'cookie-parser'
import exphbs from 'express-handlebars'
import passportLocal from 'passport-local';
import passport from 'passport'
// import expSession from 'express-session'
import cookieSession from 'cookie-session'
// Logging
import morgan from 'morgan';


import route from './route';
require('dotenv').config()

const app = express();
app.use(cookieParser())
app.use(cookieSession({
  name: 'session',
  keys: ['woewonfnkfnksanknasiftn','anfknaskfnakn']
}))

morgan.token('body', function getId(req) {
  return JSON.stringify(req.body)
})

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan(':method :url :response-time'));

// for static files
let options = {
  dotfiles: 'ignore',
  index: false
}
app.use(express.static(path.join(__dirname, 'public'),
  options))

// views
app.set('view engine', '.hbs')
app.set('views', path.join(__dirname, '/src/views'))
app.engine('.hbs', exphbs({
  defaultLayout: 'index',
  layoutsDir: 'src/views', // this overrides the /src/views/layouts
  extname: '.hbs',
  partialsDir: [
    'src/views/partials'
  ]
}))

let LocalStrategy = passportLocal.Strategy;




app.use(passport.initialize());
app.use(passport.session());
// app.use(expSession({
// 	secret: 'anyStringOfText',
// 	saveUnInitialized: true,
// 	resave: true
// }))

passport.use(new LocalStrategy(
  {
    usernameField: 'username',
    passwordField: 'password'
  },
  function (username, password, done) {
    console.log("strategy")
    if (process.env.USERNAME == username && process.env.PASSWORD == password) {
      return done(null, { username, id: 1 });
    }
    return done(null, false);
  }
));

passport.serializeUser(function (user, done) {
  console.log("serial")
  done(null, user);
});

passport.deserializeUser(function (user, done) {
  console.log("deserial")
  console.log(user)
  done(null, user);
});


app.get('/login',
  function (req, res, next) {
    passport.authenticate('local', function (err, user, info) {
      if (!user) { res.redirect(`/login`); }
      if (user) {
        req.logIn(user, function (err) {
          res.redirect('/');
        })
      }
    })(req, res, next)
  }
);

// Load up the routes
app.use(route);


// Start the API
app.listen(8000);
console.log('info', `api running on port 8000`);
