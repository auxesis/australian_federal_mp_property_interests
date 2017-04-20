Scraper for ABC's [list of properties](http://www.abc.net.au/news/2017-04-20/australian-politician-property-ownership-details/8453782) owned by members of the Australian Federal parliament.

The data has been collected from the Parliament's registers of interests, and massaged into a usable tabular form.

This scraper [runs on Morph](https://morph.io/auxesis/australian_federal_mp_property_interests). To get started [see Morph's documentation](https://morph.io/documentation).

## Making changes to the scraper

Ensure you have Ruby 2.3.1, then set up with:

``` bash
git clone https://github.com/auxesis/australian_federal_mp_property_interests.git
cd australian_federal_mp_property_interests
bundle
```

Then run the scraper:

``` bash
bundle exec ruby scraper.rb
```

You can load in some pre-canned test data from `sample.html` with:

``` bash
SCRAPER_ENV=dev bundle exec ruby scraper.rb
```
