# ![Autotune Logo](https://raw.githubusercontent.com/wiki/voxmedia/autotune/images/autotune-logo.png)

 
**Current project status**: v1.0 ALPHA!

---

Autotune is a centralized management system for your charts, graphics, quizzes and other tools,
brought to you by the Editorial Products team at Vox Media.

## Documentation

See project [wiki](https://github.com/voxmedia/autotune/wiki) for documentation on getting started.

- [Getting started](https://github.com/voxmedia/autotune/wiki/getting-started)
- [Setup](https://github.com/voxmedia/autotune/wiki/setup)
- [How does it work?](https://github.com/voxmedia/autotune/wiki/How-does-it-work%3F)
- [Blueprints](https://github.com/voxmedia/autotune/wiki/Getting-started#blueprints)
  - [Using an existing blueprint](https://github.com/voxmedia/autotune/wiki/Using-a-blueprint)
  - [Creating a new blueprint](https://github.com/voxmedia/autotune/wiki/How-to-create-a-blueprint)
  - [Example blueprints](https://github.com/voxmedia/autotune/wiki/Example-blueprints)
- [Troubleshooting](https://github.com/voxmedia/autotune/wiki/Troubleshooting)
- [Reporting bugs](https://github.com/voxmedia/autotune/wiki/Reporting-bugs)
- [Contribution guidelines](https://github.com/voxmedia/autotune/wiki/Contribution-guidelines)

## Running tests

Automated tests are broken up into backend Ruby tests and front-end javascript
tests. To run the backend tests...

```sh
cd autotune
bundle install
bundle exec rake db:migrate RAILS_ENV=test
bundle exec rake test
```

And to run the front-end tests

```sh
cd autotune
bundle install
npm install
npm test
```


## Credits

_Architecture and development:_ Ryan Mark

_UI design:_ Josh Laincz and Jason Santa Maria

_Contributions:_ Kavya Sukumar, Casey Miller, Skip Baney

And lots of help from Vox Media's product team

## License

Copyright (c) 2015, Vox Media, Inc.
All rights reserved.

BSD license

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
