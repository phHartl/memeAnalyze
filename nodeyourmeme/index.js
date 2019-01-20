var fs = require('fs'),
  request = require('request'),
  vision = require('@google-cloud/vision');

module.exports = require('./api');

client = new vision.ImageAnnotatorClient();

module.exports.search('Philosoraptor').then(function (result) {
  textRecognitionByGoogle(result.image).then(function (res) {
    console.log("Google text recognition of main image\n" +res[0].description);
  });
  fs.writeFile(result.name + ".txt", result.about, function (err) {

  });
  download(result.image, result.name + '.jpg', function () {
    console.log("downloaded main picture");
  });
  for (let i = 0; i < result.examples_images.length; i++) {
    download(result.examples_images[i], result.name + "_example" + [i + 1] + ".jpg", function () {
      console.log("downloaded example")
    })
  }
  ;
  module.exports.searchPhotos(result.url).then(function (res) {
    for (let i = 0; i < res.recent_examples.length; i++) {
      download(res.recent_examples[i], result.name + '_recentExample' +[i]+ ".jpg", function () {
        console.log("downloaded recent example");
      })
    }
  });
}).catch(console.error);

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
//   console.log(result);
// });

//Performs an API Request -> JSON File with credentials needed
function textRecognitionByGoogle(fileName) {
  return new Promise(function (resolve, reject) {
    client
      .textDetection(fileName)
      .then(results => {
        const detections = results[0].textAnnotations;
        if (detections.length !== 0) {
          resolve(detections);
        } else {
          reject("no text detected")
        }
      });
  })
};