const limit = require('simple-rate-limiter');
//Limit parallel request to prevent getting IP banned by knowyourmeme.com
const request = limit(require("request")).to(7).per(3000);
const cheerio = require('cheerio');

const config = require('../config');

function getSearchURL(term) {
    return config.BASE_URL + config.SEARCH_URL + term.split(' ').map(s => encodeURIComponent(s)).join('+');
}

/**
 * Data structure to save a meme: url, OCR text, name, about, templateURL, base image & meta data
 */
class Meme {
    constructor(url, text, templateName, templateAbout, templateUrl, templateImage, templateViews, templateYear, templateOrigin, templateTags) {
        this.url = url;
        this.text = text;
        this.templateName = templateName;
        this.templateAbout = templateAbout;
        this.templateUrl = templateUrl;
        this.templateImage = templateImage;
        this.templateViews = templateViews;
        this.templateYear = templateYear;
        this.templateOrigin = templateOrigin;
        this.templateTags = templateTags;
    }
}

function makeRequest(url) {
    return new Promise((resolve, reject) => {
        request({
            uri: url,
            headers: {
                'User-Agent': config.USER_AGENT
            }
        }, (err, res, body) => {
            if (err != null) {
                reject((typeof err !== 'object') ? new Error(err) : err);
                return;
            }

            // if the request was not a success for some reason
            if (res.statusCode.toString()[0] !== '2') {
                reject(new Error('Status Code ' + res.statusCode));
                return;
            }

            resolve(body);
        });
    })
}

/**
 * Finds url to searched term
 * @param term meme name
 * @returns {Promise<string>} - A promise resolving to the first results URL
 */
async function findFirstSearchResult(term) {
    let body;
    try {
        body = await makeRequest(getSearchURL(term));
    } catch (e) {
        throw e;
    }

    if (body.includes('Sorry, but there were no results for')) {
        throw new Error('No results found.');
    }

    const $ = cheerio.load(body);

    const grid = $('.entry-grid-body');
    const searchItem = grid.find('tr td a')[0];

    return config.BASE_URL + searchItem.attribs.href;
}

/**
 * This function provides the main crawling logic by getting all images of a provided template (moderator and user content)
 * @param body HTML document of meme template to be crawled
 * @param url URL of html document
 * @returns {Promise<null|Array>} - A promise resolving to all crawled meme incarnations with their data - see class meme
 */
async function parseMemeBody(body, url) {
    let $ = cheerio.load(body);

    const isMeme = $('#maru > article > #entry_body > aside > dl > a')[0].attribs['href'].includes('meme');

    if (!isMeme) {
        return null;
    }

    const name = $('.info h1 a')[0].children[0].data;
    const about = $('.bodycopy #about').next().text();
    const image = $('#maru > article > header > a')[0].attribs['href'];
    const views = $('dd.views')[0].attribs['title'].replace(/\D/g, '');
    const year = $('dt').filter(function () {
        return $(this).text().trim() === 'Year';
    }).next().text().trim();

    const origin = $('dt').filter(function () {
        return $(this).text().trim() === 'Origin';
    }).next().text().trim();

    const tags = $('dt').filter(function () {
        return $(this).text().trim() === 'Tags';
    }).next().text().trim();

    let examples_parent = $('#various-examples').nextAll().has('a img')[0];
    const hasRecentImages = parseInt($('dd.photos')[0].attribs['title'].replace(/\D/g, ''));
    //Make sure to get all possible variation of examples
    if (examples_parent === undefined) {
        examples_parent = $('#notable-examples').nextAll().has('a img')[0];
        if (examples_parent === undefined) {
            examples_parent = $('#examples').nextAll().has('a img')[0];
        }
    }
    if (hasRecentImages !== 0 && examples_parent === undefined) {
        console.log("Recent images but no examples");
    }
    let examples_images = [];
    console.log("Meme currently progressing:\n" + name);
    if (examples_parent !== undefined) {

        $ = cheerio.load(examples_parent);

        const examples_node = $('a img');

        for (let i = 0; i < examples_node.length; i++) {
            examples_images[i] = (examples_node[i].attribs['data-src'].replace('small', 'original').replace('masonry', 'original')); //Imageurl is stored inside this html attribute -> sometimes only small url is stored - RegEx
        }

        console.log("Done with main page crawling");
    } else {
        console.log("Meme has no examples provided");
    }
    //Additionally get user uploaded images -> doing a ton of requests here
    let memes = [];
    if (hasRecentImages !== 0) {
        let maxPages = Math.ceil(hasRecentImages/20); //Caution -> hasRecentImages/20 is max but you will get ip banned doing this without limiting your requests
        for (let i = 0; i < maxPages; i++) {
            let memesPerPage = await findPhotosForEntry(url, i).then(async function (res) {
                let currentImages = res.recent_examples;
                let currentMemes = [];
                for (let j = 0; j < currentImages.length; j++) {
                    await textRecognitionByGoogle(currentImages[j]).then(function (res) {
                        currentMemes[j] = (new Meme(currentImages[j], res[0].description, name, about, url, image, views, year, origin, tags));
                    });
                }
                return currentMemes;
            });
            memes.push.apply(memes, memesPerPage);
        }
        console.log("Crawled all user generated images for\n" + name);
        return memes;
    } else {
        console.log("Meme has no user examples");
        for (let i = 0; i < examples_images.length; i++) {
            memes[i] = new Meme(examples_images[i], "", name, about, url, image, views, year, origin, tags)
        }
        return memes;
    }
}

/**
 * Crawls a whole page of images for provided meme template
 * @param url template url
 * @param page webpage number
 * @returns {Promise<*>} A promsie resolving to the image urls
 */
async function findPhotosForEntry(url, page) {
    if (page === undefined) {
        page = 1;
    }
    let body;
    try {
        body = await makeRequest(url + config.PHOTO_URL + config.SORT_URL + config.PAGE_URL + page);
    } catch (e) {
        throw e;
    }
    return searchPhotos(body);
}

async function searchPhotos(body) {
    let recent_examples = [];
    $ = cheerio.load(body);
    let recentImagesGallery = $('#photo_gallery').children('.item');
    for (let i = 0; i < recentImagesGallery.length; i++) {
        recent_examples[i] = recentImagesGallery[i].children[1].children[1].attribs['data-src'].replace('masonry', 'original');
    }
    return {recent_examples: recent_examples}
};

/**
 * This function crawls all entries to a certain page of the sub category image macros
 * @param page number of page to be crawled (e.g. 1)
 * @returns {Promise<Array>} - A promise resovling to an array of meme objects (examples)
 */
async function getImageMacros(page) {
    if (page === undefined) {
        page = 1;
    }
    let body;
    try {
        body = await makeRequest(config.BASE_URL + config.IMAGE_MACRO_URL + config.PAGE_URL + page + config.IMAGE_MACRO_SORT);
    } catch (e) {
        throw e;
    }
    const imageMacrosUrls = findGridItemUrls(body);
    let memes = [];
    for (let i = 0; i < imageMacrosUrls.length; i++) {
        memes[i] = parseMemeBody(await makeRequest(imageMacrosUrls[i]), imageMacrosUrls[i]);
    }
    return memes;
}

function findGridItemUrls(body) {
    const $ = cheerio.load(body);

    const grid = $('.entry-grid-body');
    const gridItems = grid.find('tr td a.photo');

    let gridItemURLs = [];

    for (let i = 0; i < gridItems.length; i++) {
        gridItemURLs[i] = config.BASE_URL + gridItems[i].attribs.href;
    }
    return gridItemURLs;
}

/**
 * Search for a given term.
 * @param term {string} - The search term for which to search on.
 * @returns {Promise.<object>} - A promise which resolves to a meme object
 */
async function doSearch(term) {
    let resultUrl;
    try {
        resultUrl = await findFirstSearchResult(term);
    } catch (e) {
        throw e;
    }

    let body;
    try {
        body = await makeRequest(resultUrl);
    } catch (e) {
        throw e;
    }

    return parseMemeBody(body, resultUrl);
}

/**
 * Get a random meme.
 * @returns {Promise.<object>} - A promise which resolves to a meme object
 */
async function doRandomSearch(tries = 3) {
    let body;
    let url = config.BASE_URL + config.RANDOM_URL;
    try {
        body = await makeRequest(url);
        let $ = cheerio.load(body);
        //Get the corresponding url we have been redirected to
        url = $('link[rel=canonical]').attr('href');
    } catch (e) {
        if (tries > 0) {
            return doRandomSearch(--tries);
        }

        throw e;
    }

    const parsed = await parseMemeBody(body, url);

    if (!parsed && tries > 0) {
        return doRandomSearch(--tries);
    }

    return parsed;
}

/**
 * Performs an OCR request to setup you need a JSON file with credentials ready on your system (https://cloud.google.com/docs/authentication/production)
 * @param fileName URL to image which needs to be recognized
 * @returns {Promise<any>} - A promise containing the text response
 */
function textRecognitionByGoogle(fileName) {
    return new Promise(function (resolve, reject) {
        client
            .textDetection(fileName)
            .then(results => {
                const detections = results[0].textAnnotations;
                if (detections.length !== 0) {
                    resolve(detections);
                } else {
                    resolve([{description: ""}]);
                }
            });
    })
};

module.exports = {
    search: doSearch,
    random: doRandomSearch,
    searchPhotos: findPhotosForEntry,
    topImageMacros: getImageMacros,
};