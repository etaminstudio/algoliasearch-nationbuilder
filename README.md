# algoliasearch-nationbuilder

Sync NationBuilder People data with Algolia

# Requirements

- an [Algolia](https://www.algolia.com) account
- a [NationBuilder](http://nationbuilder.com) nation

This project works as a proxy between NationBuilder webhooks and Algolia API, so you don't need a database.

# Setup

Copy `.env.example` to `.env` and set your Algolia and NationBuilder credentials.

Install the dependencies

    bundle install

Start the server locally

    foreman start

# Deployment

This project can be easily deployed to Heroku, just set the variables from `.env` as Config Variables.