var fs = require('fs'),
  request = require('request'),
  objectsToCsv = require('objects-to-csv'),
  vision = require('@google-cloud/vision');

module.exports = require('./api');

client = new vision.ImageAnnotatorClient();

module.exports.search('Philosoraptor').then(function (result) {
  (async () => {
    let memes2D = await Promise.all(result);
    //Convert the corresponding 2D array into a 1D to save as csv
    let memes = [].concat(...memes2D);
    let csv = new objectsToCsv(memes);
    // Save to file:
    await csv.toDisk('./memes.csv');
  })();
}).catch(console.error);
//
// module.exports.random().then(function (result) {
//   textRecognitionByGoogle(result.image).then(function (res) {
//     console.log("Google text recognition of main image\n" +res[0].description);
//   });
//   fs.writeFile(result.name+".txt", result.about, function (err) {
//
//   });
//   download(result.image,result.name+ '.jpg', function () {
//     console.log("downloaded main picture");
//   });
//   for (let i = 0; i < result.examples_images.length; i++) {
//     download(result.examples_images[i],result.name+"_example"+[i]+".jpg", function () {
//       console.log("downloaded example")
//     })};
// }).catch(console.error);

var download = function (uri, filename, callback) {
  request.head(uri, function (err, res, body) {
    console.log('content-type:', res.headers['content-type']);
    console.log('content-length:', res.headers['content-length']);

    request(uri).pipe(fs.createWriteStream(filename)).on('close', callback);
  });
};

// module.exports.topImageMacros(1).then(function (result) {
//   (async () => {
//     let memes2D = await Promise.all(result);
//     //Convert the corresponding 2D array into a 1D to save as csv
//     let memes = [].concat(...memes2D);
//     let csv = new objectsToCsv(memes);
//     // Save to file:
//     await csv.toDisk('./memes.csv');
//   })();
// });