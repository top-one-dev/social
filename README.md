# Goji.live

Goji.live is an open source and fully decentralized social network. It is the new social network of Goji.network. We are launching to create a safe space for holistic health conversation to flourish, in the growing age of big tech social network censorhip. 

The Goji.live project is based on the Gab-Social project, which in turn is based on [Mastodon](https://github.com/tootsuite/mastodon) project, and is licensed under the terms and conditions of AGPL-3.0. We selected to fork Gab, despite controversy surrounding their platform, simply because they had developed group feature and had implemented some features to allow for paid premium memberships (a freemium model), as we did not want to depend on donations for viability. 

We intend to add a number of new features and improvements that others will be also free to use and build upon. 

## Deployment

**Tech stack:**

- **Ruby on Rails** powers the REST API and other web pages
- **React.js** and Redux are used for the dynamic parts of the interface
- **Node.js** powers the streaming API

**Requirements:**

- **PostgreSQL** 9.5+
- **Redis**
- **Ruby** 2.4+
- **Node.js** 8+

## Local development

To get started developing on Goji.live, you will need to run a version of it locally.
The following instructions assume you are already familiar with using a terminal program.
1. Install Prerequesite [Git](https://git-scm.com/downloads), [Node.js LTS](https://nodejs.org/en/), [Yarn](https://yarnpkg.com/en/docs/install), [Vagrant](https://www.vagrantup.com/), and [VirtualBox](https://www.virtualbox.org/), if you haven't already.
2. Open a terminal window and change into your working directory with `cd ~/work`
3. Clone this repository with `git clone https://github.com/gojinetwork/gojilive.git`
4. Change into the project directory with `cd gojilive`
5. Run `vagrant up` to provision the virtual machine. This will take a while.
6. Finally, run `vagrant ssh -c "cd /vagrant && foreman start"` to start the local web server.
7. Visit http://0.0.0.0:3000 in your web browser to see Goji's splash screen. If it doesn't load, or styling is missing, wait another minute and refresh the page.
8. Log in with the username `admin` and password `administrator`
9. Have fun developing on Goji!

## License

Copyright (C) 2020 Goji Network Inc., and other contributors (see [AUTHORS.md](AUTHORS.md), forked)

Copyright (C) 2016-2019 Eugen Rochko & other Goji.live contributors

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
