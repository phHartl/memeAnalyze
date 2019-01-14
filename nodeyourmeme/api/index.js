const request = require('request');
const cheerio = require('cheerio');

const config = require('../config');

function getSearchURL(term) {
    return config.BASE_URL + config.SEARCH_URL + term.split(' ').map(s => encodeURIComponent(s)).join('+');
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

async function findFirstSearchResult(term) {
    let body;
    try {
        body = await makeRequest(getSearchURL(term));
    }
    catch (e) {
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

function childrenToText(children) {
    let text = '';

    for (let i = 0; i < children.length; i++) {
        const child = children[i];

        if (child.type === 'text') {
            if (!/^\s*\[\d+]\s*$/.test(child.data))
            {
                text += child.data;
            }

            continue;
        }

        text += childrenToText(child.children);
    }

    return text;
}

function parseMemeBody(body, url) {
    let $ = cheerio.load(body);

    const isMeme = $('#maru > article > #entry_body > aside > dl > a')[0].attribs['href'].includes('meme');

    if(!isMeme){
        return null;
    }

    const name = $('.info h1 a')[0].children[0].data;
    const about = $('.bodycopy');
    const image = $('#maru > article > header > a')[0].attribs['href'];
    const views = $('dd.views')[0].attribs['title'].replace(/\D/g,'');
    let examples_parent = $('#various-examples').nextAll('center')[0];
    const recentImages = parseInt($('dd.photos')[0].attribs['title'].replace(/\D/g,''));
    if(examples_parent === undefined){
        examples_parent = $('#notable-examples').nextAll('center')[0];
        if(examples_parent === undefined){
            examples_parent = $('#examples').nextAll('center')[0];
        }
    }if(recentImages !== 0 && examples_parent === undefined) {
        console.log("Recent images but no examples")
        //There are some recent user made images but no examples -> travel to new side and crawl them?
    }
    let examples_images = [];

    if(examples_parent !== undefined) {

        $ = cheerio.load(examples_parent);

        const examples_node = $('a');

        $ = cheerio.load(examples_parent);

        for (let i = 0; i < examples_node.length; i++) {
            examples_images[i] = ($('a')[i].children[0].attribs['data-src']);
        }
    }

    const children = about.children();

    for (let i = 0; i < children.length; i++) {
        const child = children[i];

        if (child.attribs.id === 'about') {
            return {  name, about: childrenToText(children[i + 1].children), url: url, image: image, examples_images: examples_images, views: views};
        }
    }

    const paragraphs = about.find('p');

    if (paragraphs && paragraphs.length !== 0) {
        const text = childrenToText(paragraphs);

        if (text && text.trim() !== '') {
            return { name, about: text, url: url, image: image, examples_images: examples_images, views: views};
        }
    }

    return null;
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
    } catch (e) {
        if (tries > 0) {
            return doRandomSearch(--tries);
        }

        throw e;
    }

    const parsed = parseMemeBody(body, url);

    if (!parsed && tries > 0) {
        return doRandomSearch(--tries);
    }

    return parsed;
}

module.exports = { search: doSearch, random: doRandomSearch };