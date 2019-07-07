import express from 'express'
import swaggerUi from 'swagger-ui-express'

import query from './ctb/query';
import invoke from './ctb/invoke';

const YAML = require('yamljs');
const swaggerDocument = YAML.load('./swagger.yaml');

let router = express.Router();




// router.
// router.get('/', query);
router.get('/',function (req,res){
    console.log(req.session);
    res.render('index.hbs');
})
router.get('/query/:fcn', query);
router.post('/invoke/:fcn', invoke);
router.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));


export default router