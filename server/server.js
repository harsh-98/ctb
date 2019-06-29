const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
import {main} from './query';
import invoke from './invoke';
// Logging
const morgan = require('morgan');

morgan.token('body', function getId (req) {
    return JSON.stringify(req.body)
  })
var accessLogStream = fs.createWriteStream(path.join(__dirname, 'access.log'), { flags: 'a' })

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// app.use(morgan(':body :method :url :response-time', { stream: accessLogStream }))
app.use(morgan(':method :url :response-time'))

// Load up the routes
console.log(main);
app.get('/', main);
app.post('/invoke', invoke);
app.post('/query', main);

// Start the API
app.listen(8000);
console.log('info', `api running on port 8000`);
