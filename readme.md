#Fantom Pod Repository v0.0.2
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.0.2](http://img.shields.io/badge/pod-v0.0.2-yellow.svg)](http://www.fantomfactory.org/pods/afPodRepo)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

Pod Repository is a website for uploading, viewing and downloading Fantom pods. It is [fanr](http://fantom.org/doc/docFanr/Tool.html) compatible and backed by MongoDB.

To see Pod Repository in action, visit [http://pods.fantomfactory.org/](http://pods.fantomfactory.org/). If you like what you see and wish to host your own Pod Repository, at work or at home, then the setup couldn't be simpler!

Pod Repository features:

- Editable Pod properties
- Enhanced Fandoc documentation
  - syntax hightlighting
  - table support
  - link to images in pods
  - broken link reporting

- [Atom](http://tools.ietf.org/html/rfc4287) (RSS) feeds for individual pods
- [Open Graph](http://ogp.me/) markup on pod summary pages
- [Sitemap](http://www.sitemaps.org/) XML generation
- Basic [Gravatar](http://en.gravatar.com/) integration

## Install

Install `Fantom Pod Repository` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afPodRepo

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afPodRepo 0.0"]

## Documentation

Full API & fandocs are available on the [Fantom Pod Repository](http://pods.fantomfactory.org/pods/afPodRepo/).

## Quick Start

1. Start an instance of MongoDB:

        C:\> mongod
        
        MongoDB starting
        db version v3.0.5
        waiting for connections on port 27017


2. Start the Fantom Pod Repository website:

        C:\>fan afPodRepo 8069
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                 Alien-Factory BedSheet v1.4.12, IoC v2.0.10 /___/
        
        IoC Registry built in 303ms and started up in 892ms
        
        Bed App 'Fantom Pod Repository' listening on http://localhost:8069/


3. Point your browser to [http://localhost:8069/](http://localhost:8069/) and Job Done!

  ![Quickstart Screenshot](http://pods.fantomfactory.org/pods/afPodRepo/doc/quickstart-screenshot.png)



## Configuration

The website is configured with various properties which may be set as environment variables, or overridden by a `config.properties` file. The `config.properties` should be in the current / same directory that the website is started in.

### MongoDB URL

This defines the MongoDB instance the Pod Repository should connect to. It takes the form of the standard [MongoDB connection URL](http://pods.fantomfactory.org/pods/afMongo/api/ConnectionManagerPooled):

    afPodRepo.mongoDbUrl = mongodb://db1.example.net:2500/?connectTimeoutMS=30000

Defaults to `mongodb://localhost:27017/podrepo`

### Public URL

The public URL is used in [Sitemap](http://www.sitemaps.org/) generation, [Atom (RSS)](http://tools.ietf.org/html/rfc4287) feeds, [og:image](http://ogp.me/#metadata) meta tags, and other components that require an absolute URL. It is used to set the BedSheet [host](http://pods.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds#host) config property.

    afPodRepo.publicUrl = http://pods.fantomfactory.org

Defaults to `http://localhost:<port>`

### Contact Details

The contact details, as shown as a link in the bottom left hand corner of all Pod Repository pages, are set via the following properties:

    afPodRepo.contactName  = Micky Mouse
    afPodRepo.contactEmail = micky.mouse@disney.com

Contact details are disabled by default.

### Google Analytics

If the following properties are set then, Google's Universal Analytics script is included on all public pages.

    afPodRepo.googleAccNo     = XX-99999999-9
    afPodRepo.googleAccDomain = //pods.fantomfactory.org/

See [Google Analytics's Pod](http://pods.fantomfactory.org/pods/afGoogleAnalytics/api/index) for more details.

Google analytics is disabled by default.

### Error Reporting

The Pod Repository can email a detailed error report whenever an unhandled error occurs on the server. To enable, set the following properties:

    afPodRepo.errorEmails.smtpHost     = mail.example.com
    afPodRepo.errorEmails.smtpPort     = 25
    afPodRepo.errorEmails.smtpUsername = micky.mouse
    afPodRepo.errorEmails.smtpPassword = password
    afPodRepo.errorEmails.smtpSsl      = false
    afPodRepo.errorEmails.sendTo       = micky.mouse@disney.com

Email sending is disabled by default.

### Event Logging

The Pod Repository can log events to MongoDB. To enable, set the following properties to true:

    afPodRepo.logDownloads = true
    afPodRepo.logActivity  = true

The event info is not currently used, but may be used to present statistics in future repository releases.

Event logging is disabled by default.

### Admin User

The admin user has access to, and may edit, all pods. The admin user is any user with the same email address as this property.

    afPodRepo.adminEmail = micky.mouse@disney.com

The admin user is disable by default.

### Auto Login

If this property is set, then should *anyone* visit a private URL, they will be automatically logged in as this user.

    afPodRepo.autoLoginEmail = micky.mouse@disney.com

Note that the user must already exist on the system.

Auto login is disabled by default.

> TIP: By setting `afPodRepo.adminEmail` and `afPodRepo.autoLoginEmail` to the same email address (and having people bookmark a private URL such as `/my/pods`) you create an open Pod Repository accessible to all.

## About Page

The Pod Repository may have an optional *About* page. To enable, create an `about.fandoc` file in the current / same directory that the website is started in, next to `config.properties`. Existence of this file enables the *About* link in the top nav bar. The file is rendered as the *About* page.

The *About* page is disabled by default.

## Environment Overrides

Sometimes it is convenient to have different configurations for different environments, such as `dev` or `test`. All the Pod Repository properties may have environment specific properties that override the normal properties. Just prefix them with the environment:

    afPodRepo.mongoDbUrl      = mongodb://localhost:27017/podrepo
    dev.afPodRepo.mongoDbUrl  = mongodb://localhost:27017/podrepo-dev
    test.afPodRepo.mongoDbUrl = mongodb://localhost:27017/podrepo-test

Using the properties above will make the Pod Repository connect to the `podrepo` database by default, but it will connect to `podrepo-dev` in a `dev` environment and to `podrepo-test` in `test`.

The environment is set via the command line `env` argument:

    C:\>fan afPodRepo -env test 8069

Note that all the Pod Repository properties may be overridden in the same manner.

## Sample config.properties

Here is a sample `config.properties` for you to cut'n'paste. Uncomment / remove the leading `#` symbol, from any line you wish to use.

```
# config.properties for Pod Repository
# ************************************
#
# See http://pods.fantomfactory.org/pods/afPodRepo
#

#afPodRepo.mongoDbUrl               = mongodb://localhost:27017/podrepo

#afPodRepo.publicUrl                = http://example.com

#afPodRepo.contactName              = Micky Mouse
#afPodRepo.contactEmail             = micky.mouse@disney.com

#afPodRepo.googleAccNo              = XX-99999999-9
#afPodRepo.googleAccDomain          = //example.com/

#afPodRepo.errorEmails.smtpHost     = mail.example.com
#afPodRepo.errorEmails.smtpPort     = 25
#afPodRepo.errorEmails.smtpUsername = micky.mouse
#afPodRepo.errorEmails.smtpPassword = password
#afPodRepo.errorEmails.smtpSsl      = false
#afPodRepo.errorEmails.sendTo       = micky.mouse@disney.com

#afPodRepo.logDownloads             = true
#afPodRepo.logActivity              = true

#afPodRepo.adminEmail               = micky.mouse@disney.com
#afPodRepo.autoLoginEmail           = micky.mouse@disney.com
```

## Acknowledgements

The following, non-Fantom, libraries and services are used by Pod Repository:

- [AnchorJs](http://bryanbraun.github.io/anchorjs/)
- [Bootstrap](http://getbootstrap.com/)
- [Gravatar](http://en.gravatar.com/)
- [Jasny Bootstrap Row Link](http://jasny.github.io/bootstrap/javascript/#rowlink)
- [jQuery](https://jquery.com/)
- [RequireJs](http://requirejs.org/)

Cheers!

