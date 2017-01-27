#null v0.1.2
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom-lang.org/)
[![pod: v0.1.2](http://img.shields.io/badge/pod-v0.1.2-yellow.svg)](http://www.fantomfactory.org/pods/afEggbox)
![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)

## Overview

Eggbox is a website for uploading, viewing and downloading Fantom pods. Eggbox is [fanr](http://fantom.org/doc/docFanr/Tool.html) compatible and backed by MongoDB.

To see Eggbox in action, visit [http://eggbox.fantomfactory.org/](http://eggbox.fantomfactory.org/).

Use Eggbox to host your very own pod repository, be it at home or at work! Eggbox is easy to setup and simple to configure.

Eggbox features:

- Editable Pod properties
- Enhanced Fandoc documentation
  - syntax highlighting
  - table support
  - link to images in pods
  - broken link reporting

- [Atom](http://tools.ietf.org/html/rfc4287) (RSS) feeds for individual pods
- [Open Graph](http://ogp.me/) markup on pod summary pages
- [Sitemap](http://www.sitemaps.org/) XML generation
- Basic [Gravatar](http://en.gravatar.com/) integration

## Install

Install `Eggbox` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afEggbox

Or install `Eggbox` with [fanr](http://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afEggbox

To use in a [Fantom](http://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afEggbox 0.1"]

## Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afEggbox/) - the Fantom Pod Repository.

## Quick Start

1. Start an instance of MongoDB:

        C:\> mongod
        
        MongoDB starting
        db version v3.0.5
        waiting for connections on port 27017


2. If Eggbox was installed as a pod, start the website with:

        C:\>fan afEggbox 8069
           ___    __                 _____        _
          / _ |  / /_____  _____    / ___/__  ___/ /_________  __ __
         / _  | / // / -_|/ _  /===/ __// _ \/ _/ __/ _  / __|/ // /
        /_/ |_|/_//_/\__|/_//_/   /_/   \_,_/__/\__/____/_/   \_, /
                 Alien-Factory BedSheet v1.4.12, IoC v2.0.10 /___/
        
        IoC Registry built in 303ms and started up in 892ms
        
        Bed App 'Eggbox' listening on http://localhost:8069/



  Or if using the [Eggbox standalone application](#standaloneApp), just run the script. (Edit the script to change the port.)


3. Point your browser to [http://localhost:8069/](http://localhost:8069/) and Job Done!

  ![Quickstart Screenshot](http://eggbox.fantomfactory.org/pods/afEggbox/doc/quickstart-screenshot.png)



## Standalone Installation

Eggbox may be run as a (portable) standalone application without the need to have Fantom installed. Just download the `.zip` file from [Eggbox Downloads Page](https://bitbucket.org/AlienFactory/afeggbox/downloads), extract, and run the bundled script.

Note that the standalone application *does* require `java` to be installed and available on the command line.

## Configuration

The website is configured with various properties which may be set as environment variables, or overridden by a `config.properties` file. The `config.properties` should be in the current / same directory that the website is started in.

### MongoDB URL

This defines the MongoDB instance Eggbox should connect to. It takes the form of the standard [MongoDB connection URL](http://eggbox.fantomfactory.org/pods/afMongo/api/ConnectionManagerPooled):

    afEggbox.mongoDbUrl = mongodb://db1.example.net:2500/?connectTimeoutMS=30000

Defaults to `mongodb://localhost:27017/eggbox`

### Public URL

The public URL is used in [Sitemap](http://www.sitemaps.org/) generation, [Atom (RSS)](http://tools.ietf.org/html/rfc4287) feeds, [og:image](http://ogp.me/#metadata) meta tags, and other components that require an absolute URL. It is used to set the BedSheet [host](http://eggbox.fantomfactory.org/pods/afBedSheet/api/BedSheetConfigIds#host) config property.

    afEggbox.publicUrl = http://eggbox.fantomfactory.org

Defaults to `http://localhost:<port>`

### Contact Details

The contact details, as shown as a link in the bottom left hand corner of all Eggbox pages, are set via the following properties:

    afEggbox.contactName  = Micky Mouse
    afEggbox.contactEmail = micky.mouse@disney.com

Contact details are disabled by default.

### Google Analytics

If the following properties are set then, Google's Universal Analytics script is included on all public pages.

    afEggbox.googleAccNo     = XX-99999999-9
    afEggbox.googleAccDomain = //eggbox.fantomfactory.org/

See [Google Analytics's Pod](http://eggbox.fantomfactory.org/pods/afGoogleAnalytics) for more details.

Google analytics is disabled by default.

### Error Reporting

Eggbox can email a detailed error report whenever an unhandled error occurs on the server. To enable, set the following properties:

    afEggbox.errorEmails.smtpHost     = mail.example.com
    afEggbox.errorEmails.smtpPort     = 25
    afEggbox.errorEmails.smtpUsername = micky.mouse
    afEggbox.errorEmails.smtpPassword = password
    afEggbox.errorEmails.smtpSsl      = false
    afEggbox.errorEmails.sendTo       = micky.mouse@disney.com

Email sending is disabled by default.

### Event Logging

Eggbox can log events to MongoDB. To enable, set the following properties to true:

    afEggbox.logDownloads = true
    afEggbox.logActivity  = true

The event info is not currently used, but may be used to present statistics in future repository releases.

Event logging is disabled by default.

### Admin User

The admin user has access to, and may edit, all pods. The admin user is any user with the same email address as this property.

    afEggbox.adminEmail = micky.mouse@disney.com

The admin user is disable by default.

### Auto Login

If this property is set, then should *anyone* visit a private URL, they will be automatically logged in as this user.

    afEggbox.autoLoginEmail = micky.mouse@disney.com

Note that the user must already exist on the system.

Auto login is disabled by default.

> TIP: By setting `afEggbox.adminEmail` and `afEggbox.autoLoginEmail` to the same email address (and having people bookmark a private URL such as `/my/pods`) you create an open pod repository accessible to all.

## About Page

Eggbox may have an optional *About* page. To enable, create an `about.fandoc` file in the current / same directory that the website is started in, next to `config.properties`. Existence of this file enables the *About* link in the top nav bar. The file is rendered as the *About* page.

The *About* page is disabled by default.

## Environment Overrides

Sometimes it is convenient to have different configurations for different environments, such as `dev` or `test`. All the Eggbox properties may have environment specific properties that override the normal properties. Just prefix them with the environment:

    afEggbox.mongoDbUrl      = mongodb://localhost:27017/eggbox
    dev.afEggbox.mongoDbUrl  = mongodb://localhost:27017/eggbox-dev
    test.afEggbox.mongoDbUrl = mongodb://localhost:27017/eggbox-test

Using the properties above will make Eggbox connect to the `eggbox` database by default, but it will connect to `eggbox-dev` in a `dev` environment and to `eggbox-test` in `test`.

The environment is set via the command line `env` argument:

    C:\>fan afEggbox -env test 8069

Note that all Eggbox properties may be overridden in the same manner.

## Sample config.properties

Here is a sample `config.properties` for you to cut'n'paste. Uncomment / remove the leading `#` symbol, from any line you wish to use.

```
# config.properties for Eggbox
# ****************************
#
# See http://eggbox.fantomfactory.org/pods/afEggbox
#

#afEggbox.mongoDbUrl               = mongodb://localhost:27017/eggbox

#afEggbox.publicUrl                = http://example.com

#afEggbox.contactName              = Micky Mouse
#afEggbox.contactEmail             = micky.mouse@disney.com

#afEggbox.googleAccNo              = XX-99999999-9
#afEggbox.googleAccDomain          = //example.com/

#afEggbox.errorEmails.smtpHost     = mail.example.com
#afEggbox.errorEmails.smtpPort     = 25
#afEggbox.errorEmails.smtpUsername = micky.mouse
#afEggbox.errorEmails.smtpPassword = password
#afEggbox.errorEmails.smtpSsl      = false
#afEggbox.errorEmails.sendTo       = micky.mouse@disney.com

#afEggbox.logDownloads             = true
#afEggbox.logActivity              = true

#afEggbox.adminEmail               = micky.mouse@disney.com
#afEggbox.autoLoginEmail           = micky.mouse@disney.com
```

## Acknowledgements

The following, non-Fantom, libraries and services are used by Eggbox:

- [AnchorJs](http://bryanbraun.github.io/anchorjs/)
- [Bootstrap](http://getbootstrap.com/)
- [D3.js](https://d3js.org/)
- [Gravatar](http://en.gravatar.com/)
- [Jasny Bootstrap Row Link](http://jasny.github.io/bootstrap/javascript/#rowlink)
- [jQuery](https://jquery.com/)
- [jQuery Throttle / Debounce](http://benalman.com/projects/jquery-throttle-debounce-plugin/)
- [RequireJs](http://requirejs.org/)
- [Shields.io](http://shields.io/)
- [Tinysort](http://tinysort.sjeiti.com/)

Cheers!

