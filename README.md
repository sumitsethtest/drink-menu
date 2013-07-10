# Drink::Menu

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'drink-menu'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install drink-menu

## Usage

Drink Menu separates menu layout from menu definition. Menu definition looks like:


```ruby
class MainMenu
  extend DrinkMenu::MenuBuilder

  menuItem :progress do |item|
  end

  menu :sites_list, itemsFromCollection: Staticly.sitesList, titleProperty: :name

  menuItem :open_site, title: 'Open Site', submenu: :sites_list

  menuItem :create_site, title: 'Create Site'
  menuItem :export, title: 'Export to Folder...'
  menuItem :import, title: 'Import Folder as Site...'
  menuItem :force_rebuild, title: 'Force Rebuild'
  menuItem :about, title: 'About Staticly'
  menuItem :quit, title: 'Quit'


  iconImage = NSImage.imageNamed "status-icon-off"
  iconImage.template = true

end
```

and then layout is as simple as:

```ruby

class MainMenu
  extend DrinkMenu::MenuBuilder

  statusBarMenu :main_menu, icon: iconImage, statusItemViewClass: StatusItemView do
    open_site
    create_site
    ___
    export
    import
    force_rebuild
    ___
    about
    quit
  end

end
```

More detailed documentation coming soon.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
