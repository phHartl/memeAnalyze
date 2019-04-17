var fs = require('fs'),
  request = require('request'),
  objectsToCsv = require('objects-to-csv'),
  vision = require('@google-cloud/vision');

module.exports = require('./api');

client = new vision.ImageAnnotatorClient();

//This function provides a way to crawl a specific meme
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

//Crawl a random meme
module.exports.random().then(function (result) {
  (async () => {
    let memes2D = await Promise.all(result);
    //Convert the corresponding 2D array into a 1D to save as csv
    let memes = [].concat(...memes2D);
    let csv = new objectsToCsv(memes);
    // Save to file:
    await csv.toDisk('./memes.csv');
  })();
}).catch(console.error);

//This functions takes the side page to crawl as argument and then crawls all related meme examples to those memes
module.exports.topImageMacros(1).then(function (result) {
  (async () => {
    let memes2D = await Promise.all(result);
    //Convert the corresponding 2D array into a 1D to save as csv
    let memes = [].concat(...memes2D);
    let csv = new objectsToCsv(memes);
    // Save to file:
    await csv.toDisk('./memes.csv');
  })();
});