# nodeyourmeme 3.0
Know your meme web scraper API for node.js!

Based on nodeyourmeme by ArcticZeroo (https://github.com/beastwilson/nodeyourmeme), heavily expanded to be used in research.

This module can search for any term, get a random meme or crawl hole pages of image macro subsection and return all corresponding information including:
- base image
- name
- base url
- views
- year
- origin
- tags
- about
- meme incarnation images
- meme incarnation texts (using Google Cloud OCR) -> setup: https://cloud.google.com/docs/authentication/production
## Usage:
```javascript
const nodeyourmeme = require('nodeyourmeme');

nodeyourmeme.search('Philosoraptor').then(function (result) {
  (async () => {
    let memes2D = await Promise.all(result);
    //Convert the corresponding 2D array into a 1D to save as csv
    let memes = [].concat(...memes2D);
    let csv = new objectsToCsv(memes);
    // Save to file:
    await csv.toDisk('./memes.csv');
  })();
}).catch(console.error);


module.exports.topImageMacros(1).then(function (result) {
  (async () => {
    let memes2D = await Promise.all(result);
    let memes = [].concat(...memes2D);
    let csv = new objectsToCsv(memes);
    await csv.toDisk('./memes.csv');
  })();
});

```

## Methods:

The following methods return a "meme promise", which is a promise that resolves to an object with the properties `url`(image url to specific meme), `text` (text detected by OCR) `templateName` (the name of the base meme), `templateAbout` (the text from the "about" section of the meme), `templateURL` (url of base meme), `templateViews` (view count of base meme), `templateYear` (base meme year provided), `templateOrigin` (origin of base meme) and `templateTags` (base meme given tags).

`search(term)` - Takes a string input for the search term

`random()` - Gets a random meme

`topImageMacros(pageNumber)` - Gets all information to specific side of sub category image macros sorted by views