module DrinkMenu
  class Menu
    extend Forwardable

    def_delegators :@menu,
      :menuBarHeight, :numberOfItems,
      :itemArray, :isTornOff,
      :supermenu, :setSupermenu, :supermenu=,
      :autoenablesItems, :setAutoenablesItems, :autoenablesItems=,
      :font, :setFont, :font=,
      :title, :setTitle, :title=,
      :minimumWidth, :setMinimumWidth, :minimumWidth=,
      :size, :propertiesToUpdate,
      :menuChangedMessagesEnabled, :setMenuChangedMessagesEnabled, :menuChangedMessagesEnabled=,
      :allowsContextMenuPlugins, :setAllowsContextMenuPlugins, :allowsContextMenuPlugins=,
      :highlightedItem, :delegate, :setDelegate, :delegate=

    attr_reader :menuItems, :menu, :builder, :label
    attr_accessor :statusItem, :statusItemIcon, :memberCommand, :statusItemTitle, :memberTitleProperty, :itemAddedSubject

    def self.statusMenuWithLabel(label, icon: image, statusItemViewClass: statusItemViewClass, &block)
      new(label, &block).tap do |menu|
        menu.createStatusItemWithIcon image, viewClass: statusItemViewClass
      end
    end

    def self.statusMenuWithLabel(label, icon: image, &block)
      new(label, &block).tap do |menu|
        menu.createStatusItemWithIcon image
      end
    end

    def self.statusMenuWithLabel(label, title: title, &block)
      new(label, &block).tap do |menu|
        menu.createStatusItemWithTitle title
      end
    end

    def self.menuWithLabel(label, title: title, menuItem: needsMenuItem, &block)
      new(label, &block).tap do |menu|
        menu.title = title
        menu.createMenuItemWithTitle title if needsMenuItem
      end
    end


    def self.menuWithLabel(label, title: title, &block)
      new(label, &block).tap do |menu|
        menu.title = title
      end
    end

    def self.menuWithLabel(label, itemsFromCollection: collection, titleProperty: titleProperty)
      new(label).tap do |menu|
        menu.memberTitleProperty = titleProperty

        menu.itemAddedSubject = RACSubject.subject

        @allItemsSignal =
          menu.itemAddedSubject.flattenMap(->(value){
            value.command.map(->(v){
              [label, menu[v.tag]]
            })
          })

        menu.memberCommand = @allItemsSignal.multicast(RACReplaySubject.subject)
        menu.memberCommand.connect

        collection.arrangedObjects.each do |member|
          menu.addMenuItemForMember member
        end

        collection.addObserver menu, forKeyPath: "arrangedObjects", options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld), context: nil

      end
    end

    def initialize(label, &block)
      @menuItems = {}
      @label = label
      @builder = block
      @menu = NSMenu.alloc.init
      @needsStatusItem = false
      @needsMenuItem = false
    end

    def <<(item)
      previousItemTag = @menuItems.keys.last || 0
      item.tag = previousItemTag + 1
      @menuItems[item.tag] = item
      @menu.addItem item.menuItem
    end

    def menuItemFromMenu!
      @mainMenuItem ||= MenuItem.itemWithLabel(label, title: title, submenu: self)
    end

    def addMenuItemForMember(member)
      item = MenuItem.itemWithLabel(member.hash.to_s, title: member.send(memberTitleProperty))
      item.representedObject = member
      item.rac_stateSignal = memberCommand.signal.map ->((_,value)){
        value.representedObject == item.representedObject
      }

      self << item
      itemAddedSubject.sendNext(item)

    end

    def observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
      return unless keyPath == "arrangedObjects"
      if itemArray.length < object.arrangedObjects.length
        member = object.arrangedObjects.lastObject
        addMenuItemForMember(member)
      end
    end

    # Only works when built with menuWithLabel:itemsFromCollection:titleProperty
    def subscribeToMembers(&block)
      memberCommand.signal.subscribeNext(block)
    end

    def subscribe(itemLabel, &block)
      self[itemLabel].subscribe(&block)
    end

    def createMenuItemWithTitle(title)
      @needsMenuItem = true
      @statusItemTitle = title
    end

    def createStatusItemWithTitle(title)
      @needsStatusItem = true
      @statusItemTitle = title
    end

    def createStatusItemWithIcon(image)
      @needsStatusItem = true
      @statusItemIcon = image
    end

    def createStatusItemWithIcon(image, viewClass: viewClass)
      @needsStatusItem = true
      @statusItemViewClass = viewClass
      @statusItemIcon = image
    end

    def selectItem(label)
      item = self[label]
      item.command.execute(item)
    end

    def selectItemByMember(member)
      item = @menuItems.values.find do |i|
        i.representedObject == member
      end
      item.command.execute(item)
    end

    def [](labelOrTag)
      if labelOrTag.is_a? Fixnum
        @menuItems[labelOrTag]
      else
        @menuItems.values.find do |item|
          item.label == labelOrTag
        end
      end
    end

    def needsStatusItem?
      @needsStatusItem
    end

    def needsMenuItem?
      @needsMenuItem
    end

    def createStatusItem!
      statusBar = NSStatusBar.systemStatusBar
      @statusItem = statusBar.statusItemWithLength(NSSquareStatusItemLength)
      @statusItem.highlightMode = true

      @statusItem.menu = menu

      if @statusItemViewClass
        statusItemView = @statusItemViewClass.viewWithStatusItem(@statusItem)
        @statusItem.menu.delegate = @statusItemView
        @statusItem.view = statusItemView
      end

      @statusItem.title = @statusItemTitle
      @statusItem.image = @statusItemIcon

      @statusItem
    end

  end
end
