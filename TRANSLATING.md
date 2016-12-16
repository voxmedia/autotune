# Translating Autotune to your language

We are using [i18n-js](https://github.com/fnando/i18n-js) to translate the user interface.
This library provides translation facilites using the same mechanism as the Rails I18n API.


## Getting started:

Copy the file _config/locale/autotune.yml_ to _config/locale/autotune-mylang.yml_ and edit as needed. Keep in mind that
you *need* to change the 'en:' key to 'mylang:' in order to avoid overwriting other languages.

To set the language within an initializer (for example a file under _config/initializers/locale.rb_) do:

```ruby
I18n.default_locale = :mylang
```

Restart the application and it should work (missing keys will default to their English values).


# Resources:

[Rails I18n API Guide](http://guides.rubyonrails.org/i18n.html)
[I18n-js](https://github.com/fnando/i18n-js)
