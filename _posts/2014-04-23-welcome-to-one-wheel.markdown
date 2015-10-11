---
layout: post
title: "Welcome to One Wheel"
date: 2014-04-23T22:07:37-07:00
---

UPDATE (2015-10-10): This site is no longer powered by Ghost, but instead by
Jekyll. I'm keeping this page up however for historical purposes.

--------------------

This site is powered by the relatively new blog platform called [Ghost](http://ghost.org) and running on Red Hat's cloud platform: [OpenShift](https://www.openshift.com/). Both are open source software, so I figured—in the spirit of openness—I should share how I got these technologies working together. If you'd like to follow along, the free tier of Open Shift service gives you 3 gears, which is more than enough to run Ghost.

Why?
---
If you want to get straight to the how, feel free to [skip ahead](#how).

### Why Ghost

![](/assets/images/ghost-logo.png)

Ghost aims to be a simple blogging platform and nothing more. The biggest core feature in my mind is the beautiful simplicity of the editor, which makes writing content the top priority. Using markdown with an automatically updating preview pane allows you to write without your hands ever leaving the keyboard. Use keyboard shortcuts to insert placeholders for images and links, then when finished writing you can go through and add all the real images and links. See the [feature list](https://ghost.org/features/) for a full run down.

### Why OpenShift

![](/assets/images/openshift-logo.png)

OpenShift is a completely open source platform as a service (PaaS) for hosting apps made with all the modern popular web languages/frameworks (including NodeJS of course, which is what Ghost is built on). The fact that it's open source means you aren't locked in. If you don't like openshift.com, you can take your app to an alternative host, or roll your own from the [OpenShift Origin Server](https://github.com/openshift/origin-server). Definitely try [openshift.com](http://www.openshift.com) though. They have a free tier so you can try before you buy.

<a name="how"></a>How?
---

### Install `rhc`
First, you need to install and setup the OpenShift command line client. Red Hat has [decent instructions](https://www.openshift.com/get-started#cli) for how to do it on multiple platforms so I won't repeat that information here.

### Quickstart
Thankfully for me, the hardest part is already done. The folks at Red Hat must like Ghost because they have already created an [OpenShift Quickstart](https://github.com/openshift-quickstart/openshift-ghost-quickstart) for Ghost. It is just one of many [Quickstarts](https://github.com/openshift-quickstart) they have created for some other great open source projects, like Drupal, Plone, and Tomcat just to name a few. Now that you have `rhc` installed, drop into a command prompt and run the following:
```
rhc app create ghost nodejs-0.10 --scaling --env NODE_ENV=production --from-code https://github.com/openshift-quickstart/openshift-ghost-quickstart.git
```
Replace `ghost` with the name of your application. Using the `--scaling` option allows you scale your app up to handle the load if needed. You cannot change this later so if you want your app to be scalable you need to use this option now.

After creating the app with `rhc`, you should be able to see it at `https://<appname>-<domain>.rhcloud.com/`, replacing `<appname>` with your application's name and `<domain>` with your OpenShift domain name. Yep, it already works! Now to customize it.

### OpenShift Web Console
Login to the OpenShift [web console](https://openshift.redhat.com/app/console/applications) and you should see your new app. Tap on your app to see the detail page where you can view and change various settings. On the detail page, you will see your git repository URL. Use it to clone the repository to your computer. Anytime you push a change to the master branch in that repo, OpenShift automatically deploys the changes.

### Database setup
If you know you aren't going to scale and you aren't worrying about performance issues, you can skip this step because the quickstart comes configured with sqlite out of the box. For everyone else, you should use MySQL or PostgreSQL (at the time of this writing Ghost supports sqlite, MySQL, and PostgreSQL). Thankfully, it's just a few simple clicks from your app detail page to add a database cartridge.

After adding a DB cartridge you should have a list of configuration options to use in Ghost. Save these options for the next step.

### config.js
Open the `config.js` file in the root of the repository you cloned from OpenShift. This file contains all the configuration options for Ghost, but we are only concerned with the production configuration, so scroll down to the production section. If you are changing the database, replace the database section with something like the following.

```
database: {
    client: 'pg',
    connection: {
        host     : process.env.OPENSHIFT_POSTGRESQL_DB_HOST,
        port     : process.env.OPENSHIFT_POSTGRESQL_DB_PORT,
        user     : 'user',
        password : 'password',
        database : 'database',
        charset  : 'utf8'
    },
    debug: false
},
```
Replace the values for `user`, `password` and `database` with your own information. If you didn't make note of it earlier, you can get it from the web console at this point. If you chose to use MySQL, you can use `process.env.OPENSHIFT_MYSQL_DB_HOST` for the host and `process.env.OPENSHIFT_MYSQL_DB_PORT` for the port.

I also highly recommend setting up the mail settings now. Without proper mail settings, your ghost installation will not be able to send email. To use Gmail, replace the mail section with something like the following:
```
mail: {
    transport: 'SMTP',
    options: {
        service: 'Gmail',
        auth: {
            user: 'gmailaddress',
            pass: 'password'
        }
    }
}
```
You can also change the `url` value to whatever custom domain you may be using. If you do this you will also want to add your domain as an alias in the OpenShift web console.

### Sign in
Now that we're all set up, we can try signing in. Go to `https://<appname>-<domain>.rhcloud.com/ghost` and create a username/password. Uh oh, did you get a 503 error? Not to worry, this is a known error that is being worked on, but your user was created successfully. Just go back to `https://<appname>-<domain>.rhcloud.com/` to logon and test out your new Ghost system.

Fin
---
Happy ghost writing! Please feel free to ask me any questions or post more solutions in the comments.
