var fs = require('fs'),
  request = require('request');

module.exports = require('./api');

module.exports.search('Weird Flex').then(function (result) {
    fs.writeFile(result.name+".txt", result.about, function (err) {

    });
    download(result.image,result.name+ '.jpg', function () {
      console.log("downloaded main picture");
    });
    for (let i = 0; i < result.examples_images.length; i++) {
      download(result.examples_images[i],result.name+"_example"+[i+1]+".jpg", function () {
        console.log("downloaded example")
    })};
}).catch(console.error);

module.exports.random().then(function (result) {
  fs.writeFile(result.name+".txt", result.about, function (err) {

  });
  download(result.image,result.name+ '.jpg', function () {
    console.log("downloaded main picture");
  });
  for (let i = 0; i < result.examples_images.length; i++) {
    download(result.examples_images[i],result.name+"_example"+[i]+".jpg", function () {
      console.log("downloaded example")
    })};
}).catch(console.error);

var download = function(uri, filename, callback){
  request.head(uri, function(err, res, body){
    console.log('content-type:', res.headers['content-type']);
    console.log('content-length:', res.headers['content-length']);

    request(uri).pipe(fs.createWriteStream(filename)).on('close', callback);
  });
};