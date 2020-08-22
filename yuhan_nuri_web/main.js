const port = 3000;

const express = require('express');
const session = require('express-session');
const app = express();
const dotenv = require('dotenv');

const userRouter=require('./routes/user');

dotenv.config();

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');
app.engine('html', require('ejs').renderFile);
app.use(express.static(__dirname + '/public'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(
    session({
        secret: process.env.COOKIE_SECRET,
        resave: false,
        saveUninitialized: false,
    })
);

app.use('/user',userRouter);


app.listen(port, () => {
    console.log('Listening on port ' + port + '\n');
});

app.get('/', function (req, res) { //이건 걍 여기다가
    res.sendFile(__dirname + '/public/login.html');
});



app.get('/main', function (req, res) { //MR.애매모호
    console.log('Session', req.session);
    res.render('main', {
        username: req.session.userInfo.stuName,
    });
});


