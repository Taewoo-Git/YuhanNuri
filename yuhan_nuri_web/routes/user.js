const express=require('expres');
const router =express.Router();

const cheerio=require('cheerio-httpcli');
const moment = require('moment');

const db=require9('../public/res/js/mariadb_config.js')();
const con=db.init();

db.open(con);


module.exports=router;
