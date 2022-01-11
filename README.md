# Prometheus COVID

A shim service that gathers ArcGIS covid stats into a format Prometheus can read

Currently hard-coded to Vancouver Island

## Running the service

Run locally with

```
npm run dev
```

or in prod with


```
npm start
```

## Deployment / Hosting

I deployed this to AWS Lambda using [apex `up`](https://github.com/apex/up) - even hitting it every 15s keeps me _well within_ AWS's free tier.

You could deploy it anywhere a node service can run, including your local machine / network. I just prefer the hands-off nature of lambda.
