const express = require('express');
const app = express();
import {main} from './query';
import invoke from './invoke';
// Logging
const morgan = require('morgan');
const logger = require('./logger');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('short', { stream: logger.stream }));

// Load up the routes
console.log(main);
app.get('/', main);
app.post('/invoke', invoke);
app.post('/query', main);

// Start the API
app.listen(8000);
logger.log('info', `api running on port 8000`);
