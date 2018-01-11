const express = require('express');
const fs = require('fs');
const bodyParser = require('body-parser')
var app = express();
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

app.get('/demo',
    function(req,res)
    {
	console.log(req.query);

        res.send({get: "data"});
    }
);

app.post('/upload', (req, res) => {
    var dirStorage = 'upload/';

    console.log(req);

    // extract filename from the header
    var filename = req.headers['file'];

    // streamed file
    var file = fs.createWriteStream(dirStorage + `${filename}`);
    
    // pipe request stream to file
    req.pipe(file);

    res.send({upload: "success"})

})

app.get('/upload', (req, res) => {
    res.sendFile('upload.html' , { root : __dirname});
})

app.post('/demo', (req, res) => {
    console.log(req.body);
    res.send({post: "data"});
})

app.listen(3333, ()=>{ console.log("starting..."); });
