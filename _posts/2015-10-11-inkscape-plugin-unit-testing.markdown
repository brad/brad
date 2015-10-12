---
layout: post
title: "How to write unit tests for Inkscape plugins"
date: 2015-10-11T11:12:03-07:00
---

When I first put together my [Inkscape OpenSCAD DXF export plugin](https://github.com/brad/Inkscape-OpenSCAD-DXF-Export), I never
considered writing unit tests for it, assuming it would be impractical.
Years later, I revisited the possibility and found it to be not only practical,
but absolutely necessary. A bug was reported against the plugin that only
manifested in a recently released version of Inkscape which introduced a
backward incompatibility.

Now, I didn't want to go about manually testing different types of SVG elements
on both current versions of Inkscape, so I set about investigating what it would
take to write unit tests.

Triggering the export
---------------------

Through manually toying in the Python shell, I found that I could trigger the
plugin export by instantiating the plugins effect class and calling the
`affect` method with an array containing the path to an SVG file as an argument.
My plugin stores the results in a member variable, so I could compare that
against known good output. Something like this:

{% highlight python %}
from openscad_dxf import OpenSCADDXFEffect

effect = OpenSCADDXFEffect()
effect.affect(['tests/files/circle.svg'])
with open('tests/files/circle.dxf', 'r') as dxf_file:
    self.assertEqual(effect.dxf, dxf_file.read().rstrip())
{% endhighlight %}

Testing multiple Inkscape versions
----------------------------------

Testing multiple inkscape versions locally is a bit of a pain because I
couldn't find a way to have them both installed at once. Here's where
[Travis](https://travis-ci.org/) came in handy. If you aren't familiar with the
Travis service, I highly recommend checking it out. With Travis I was able to
specify a test matrix of multiple Python versions and multiple Inkscape versions
and the service now runs my unit tests with all combinations of the specified
Python and Inkscape versions. Here's the configuration I started with:

{% highlight yaml %}
language: python
python:
  - "pypy"
  - "2.7"
# Test both current major versions of Inkscape
env:
  - INKSCAPE_VERSION="0.48.3.1-1ubuntu1.1"
  - INKSCAPE_VERSION="0.91.0+37~ubuntu12.04.1"
# command to install dependencies
install:
  - sudo add-apt-repository -y ppa:inkscape.dev/stable
  - sudo apt-get update -qq
  - sudo apt-get install -qq "inkscape=$INKSCAPE_VERSION"
  - pip install -r test-requirements.txt
# command to run tests
script: nosetests --with-coverage --cover-branches
after_success: coveralls
{% endhighlight %}

Allow me to break down the important pieces here. First, we specify the Python
versions to test against. We only list `pypy`, and `2.7` here because there is
still some Inkscape plugin code (that my plugin depends on) that doesn't work
with Python versions greater than 3.

In the `env` section we specify the Inkscape versions to test against. The long
version strings used here are the versions of the packages in the
[Inkscape.dev Ubuntu PPA](https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable).

In the `install` section, we add the PPA, install the package, and `pip install`
any other Python testing packages required.

Finally, in the `script` section we run the tests. I like to run my tests with
coverage, so I can run `coveralls` after the tests to get a nice looking code
coverage report
[on the web](https://coveralls.io/github/brad/Inkscape-OpenSCAD-DXF-Export).

With this configuration in place in my repository, all I had to do was enable
the repository on [travis-ci.org](https://travis-ci.org) and push to GitHub to
let Travis do it's work.

Running Inkscape headless
-------------------------

In my case, I wasn't quite finished yet. For reasons I won't go into here, my
plugin needs to spawn a full GUI instance of Inkscape to work. When running the
tests locally, this is a non-issue. I just watch the windows pop in and out of
existence as the tests run. However, a Travis test server is a headless
environment which means it has no peripherals attached to it, including a
display. When I tried to run the tests using the configuration above, they
failed when trying to spawn Inkscape.

Fortunately, there is a simple way to get GUI processes to work in headless
environments. There is a handy service called
[xvfb](https://en.wikipedia.org/wiki/Xvfb) (X virtual framebuffer) which creates
a virtual display on which to show any GUI processes. We can start the service
on a Travis server with just a few extra lines of configuration:

{% highlight yaml %}
# Start xvfb so we can run Inkscape headless
before_install:
  - "export DISPLAY=:99.0"
  - "sh -e /etc/init.d/xvfb start"
{% endhighlight %}

With this configuration in place, all I have to do is push my changes and Travis
automatically verifies that the expected dxf files get produced in both current
Inkscape versions with the new code.

I hope this walkthrough of my experiences helps you to write unit tests for your
own Inkscape plugin. Please feel free to [browse the code](https://github.com/brad/Inkscape-OpenSCAD-DXF-Export) to see how I fleshed
out the tests from here.
