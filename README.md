# Pop Up Archive

<table>
  <tr>
    <th>
      Ruby Version
    </th>
    <td>
      2.0.0
    </td>
  </tr>
  <tr>
    <th>
      Rails Version
    </th>
    <td>
      4.2.1
    </td>
  </tr>
  <tr>
    <th>
      Production Deployment
    </th>
    <td>
      git@heroku.com:pop-up-archive.git - http://pop-up-archive.herokuapp.com
    </td>
  </tr>
</table>

### Recommended setup

This guide expects that you have git and homebrew installed, and have a ruby environment set up with 2.0.0-p247 (using RVM or rbenv). We also assume you are using Pow, and have the development site running at http://pop-up-archive.dev. This is not required, but some aspects of the guide may not be appropriate for different configurations.

On OS X:

    brew install redis elasticsearch postgres
    git clone git@github.com:popuparchive/pop-up-archive.git
    curl get.pow.cx | sh
    gem install powder bundler
    cd pop-up-archive
    bundle install
    powder link
    cp config/env_vars.example config/env_vars

On Ubuntu:

    sudo apt-get install imagemagick libmagickwand-dev libxslt-dev postgresql libpq-dev nodejs npm
    git clone git@github.com:popuparchive/pop-up-archive.git
    gem install bundler
    cd pop-up-archive
    bundle install
    cp config/env_vars.example config/env_vars


#### Environment variables

In order to mimic the way Heroku works, many application configuration settings are defined with environment variables. If you are using foreman/etc you may have a different way of accomplishing this. You can also use the included support for the config/env_vars file.

##### You should not check config/env_vars into source control

You will need to set the SECRET_TOKEN value for the app to start (the default value is too short). The other default value may not be required. If need to point the app to a database or database user different than what is in the included database.yml, you should do that with an environment variable. Once complete:

    bundle exec rake db:create
    rake db:setup

If you receive a Postgres connection error or role error, you may need to create a Postgres user:

    createuser -s -r <USERNAME FROM database.yml>

### Development

    powder open

The site should now be running. If you need to use sidekiq, or elasticsearch, you may need to start other services manually.

#### Loading a database dump

If you want to debug production issues on your development machine, grab a dump from heroku, or have someone with the necessary access rights do that for you, by running:

```
$ heroku pgbackups:capture
$ curl -o latest.dump `heroku pgbackups:url`
```

#### Rebuilding elasticsearch index

After loading new data from a db dump or performing a similar operation, you will need to rebuild the elasticsearch index.

To do this run:

```
$ rake search:index
```

That will invoke the rake task in `lib/tasks/search.rake`.

### Testing

All that should be required is running `guard` in the project root. You can also just run `rake`.

We have the project on Travis-CI. If you submit a pull request, I assume it should check on that. I don't know.

NOTE that the Elasticsearch tests require that port 9250 is available on localhost. If you are running tests
on a Linux box, for example, you may need to alter iptables or other firewall service to open that port.


### Copyright & License

The Pop Up Archive software is released under the MIT License.
