# ganymede

[Ganymede](https://github.com/steem-third-party/ganymede) is a collection of web implementations exploring various ruby scripts and api calls posted on the STEEM blockchain, see:

[https://steemit.com/created/radiator](https://steemit.com/created/radiator)

This project is hosted publicly here:

* [steem-ganymede.herokuapp.com](https://steem-ganymede.herokuapp.com/)
* [golos-ganymede.herokuapp.com](https://golos-ganymede.herokuapp.com/)

![](https://upload.wikimedia.org/wikipedia/commons/1/17/Ganymede_-_PIA02278.jpg)

*Ganymede, Jupiter's largest satellite, by Voyager 1 on the afternoon of March 5, 1979 from a range of 253,000 kilometers (151,800 miles).*

This project also serves to demonstrate a Ruby on Rails project that can access the STEEM blockchain using the [Radiator](https://github.com/inertia186/radiator) gem.

---

## Features

* Discussions
  * Vote Ready - Finds new posts that are ready for voting.
  * Promoted by Third Parties - Posts that have received promotion by someone other than the author.
  * Predicted to Trend - Uses a heuristic library to project the payout of posts (experimental).
  * Flag War - Determines which posts are in the middle of a flag war.
  * On Trending
    * Reputation - Groups trending page by reputation.
    * Flagged - Groups trending page by flags.
    * Ignored - Groups trending page by mutes.
* Follow - Lists accounts followed/ignored by other accounts.
* Accounts
  * Upvoted/Downvote - Lists the top voting accounts.
    * Also lets you enter any account to see what their latest votes have been.
    * Download the lists as a text file.
* ATOM/RSS Feeds - Allows you to follow a particular page to track over time.
* Support for both STEEM and GOLOS blockchains.
  * Achieved by setting environment variables:
    * `API_URL` - default: `https://node.steem.ws:443`
    * `DOWNVOTES_JSON_URL` - default: `https://steemdb.com/api/downvotes`
    * `FALLBACK_API_URL` - default: `https://this.piston.rocks:443`
    * `RSHARES_JSON_URL` - default: `https://steemdb.com/api/rshares`
    * `SITE_LOGO` - default: `https://i.imgur.com/uCaoQzf.png`
    * `SITE_PREFIX` - default: `http://steemit.com`
* Easy to host on heroku or as a stand-alone electron app.

## Future Features

* Background processing when RPC takes too long.
* Optional [SteemData](https://steemdata.com/) integration to MongoDB for even faster loads.  You rock @furion!

## Install

### Quick Installation (standalone)

```bash
$ git clone https://github.com/steem-third-party/ganymede.git
$ cd ganymede
$ ./bin/electron-shell.sh
```

### Full Install (Linux)

These steps assume you have no ruby development tools at all.  You might want to try the Quick Install if you are already doing ruby development.

First, you'll need `git`.

```bash
$ sudo apt-get install git
```

Next, you'll need `ruby`.  You can get detailed steps for this on [rvm.io](http://rvm.io/).

```bash
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
$ curl -sSL https://get.rvm.io | bash -s stable
$ source ~/.rvm/scripts/rvm
$ rvm install ruby-head
$ rvm use ruby-head --create
$ gem install bundler
```

You'll also need a proper JavaScript runtime.  You might be able to skip this step if you already have one.

```bash
$ sudo apt-get install npm
```

Now, the actual install.

```bash
$ git clone https://github.com/steem-third-party/ganymede.git
$ cd ganymede
$ bundle install
$ rails s
```

Now, browse to [localhost:3000](http://localhost:3000)

## Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://github.com/steem-third-party/ganymede.git`
* Navigate into the new folder
  * `cd ganymede`
* Basic tests can be invoked as follows:
  * `rake`
* To run tests with parallelization and local code coverage:
  * `HELL_ENABLED=true rake`

## Get in touch!

If you're using Ganymede, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on STEEM.
  
## License

I don't believe in intellectual "property".  If you do, consider Ganymede as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
