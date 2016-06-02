Symbolize (attribute values)
=========

# No longer maintained


## Please check this other gems:

# Mongoid

https://github.com/thetron/mongoid-enum


# ActiveModel & POROs

https://github.com/brainspec/enumerize


This plugin introduces an easy way to use symbols for values of attributes.
Symbolized attributes return a ruby symbol (or nil) as their value
and can be set using :symbols or "strings".



Install
-------

Gem


    gem install symbolize


Gemfile

    gem 'symbolize'


About
-----

Just use "symbolize :attribute" in your model, and the specified
attribute will return symbol values and can be set using symbols
(setting string values works, which is important when using forms).

On schema DBs, the attribute should be a string (varchar) column.


Usage
-----


ActiveRecord:

    class Contact < ActiveRecord::Base

      symbolize :kind, :in => [:im, :mobile, :email], :scopes => true


Mongoid:

    class Contact
      include Mongoid::Symbolize

      symbolize :kind, :in => [:im, :mobile, :email], :scopes => true


Other examples:

    symbolize :os, :in => {
        :linux   => "Linux",
        :mac     => "Mac OS X"
    }, :scopes => true

    # Allow blank
    symbolize :gui,  :in => [:gnome, :kde, :xfce], :allow_blank => true

    # Don`t i18n
    symbolize :browser, :in => [:firefox, :opera], :i18n => false, :methods => true

    # Scopes
    symbolize :angry, :in => [true, false], :scopes => true # AR
    symbolize :angry, :type => Boolean, :scopes => true # Mongoid

    # Don`t validate
    symbolize :lang, :in => [:ruby, :js, :c, :erlang], :validate => false

    # Default
    symbolize :kind, :in => [:admin, :manager, :user], :default => :user


in/within
---------

You can provide a hash like for values allowed on the field, e.g.:
{:value => "Human text"} or an array of keys to run i18n on.
Booleans are also supported. See below.


Validate
--------

Set to false to avoid the validation of the input.
Useful for a dropdown with an "other" option textfield.

    symbolize :color, :in => [:green, :red, :blue], :validate => false

There's is also allow_(blank|nil): As you expect.


method
------

If you provide the method option, some fancy boolean methods will be added:
In our User example, browser has this option, so you can do:

    @user.firefox?
    @user.opera?

case insensitive methods
--------------------

If you provide the case_insensitive_methods option, some fancy boolean methods will be added:
In our User example, browser has this option, so you can do:

    @user.firefox?
    @user.FIREFOX?
    @user.opera?
    @user.OPERA?


Booleans
--------

Its possible to use boolean fields also. Looks better in Mongoid.

  # ActiveRecord
  symbolize :switch, :in => [true, false]

  # Mongoid
  symbolize :switch, :type => Boolean

  ...
    switch:
      "true": On
      "false": Off
      "nil": Unknown


i18n
----

If you don`t provide a hash with values, it will try i18n:

    activerecord:
    or
    mongoid:
      symbolizes:
        user:
          gui:
            gnome: Gnome Desktop Enviroment
            kde: K Desktop Enviroment
            xfce: XFCE4
          gender:
            female: Girl
            male: Boy

In some cases, if automatic lookup failes, you may want to try to translate it manully

    user.get_gender_text   # here gender is symbolized field

You can skip i18n lookup with :i18n => false

    symbolize :style, :in => [:rock, :punk, :funk, :jazz], :i18n => false


Scopes
------

With the ':scopes => true' option, you may filter/read/write easily:

    User.gender(:female).each ... # => User.where({ :gender => :female })


Now, if you provide the ':scopes => :shallow' option, fancy named scopes
will be added to the class directly. In our User example, gender has
male/female options, so you can do:

    User.female.each ...  # => User.where({ :gender => :female })


You can chain named scopes as well:

    User.female.mac => User.all :conditions => { :gender => :female, :so => :mac }

For boolean colums you can use

    User.angry     => User.find(:all, :conditions => { :angry => true })
    User.not_angry => User.find(:all, :conditions => { :angry => false })

    ( or with_[attribute] and without_[attribute] )


Default
-------

As the name suggest, the symbol you choose as default will be set
in new objects automatically. Mongoid only for now.

    symbolize :mood, :in => [:happy, :sad, :euphoric], :default => (MarvinDay ? :sad : :happy)

    User.new.mood # It may print :happy


Rails Form Example
------------------

You may call `Class.get_<attribute>_values` anywhere to get a nice array.
Works nice with dropdowns. Examples:

    class Coffee
      symbolize :genetic, :in => [:arabica, :robusta, :blend]
    end

    - form_for(@coffee) do |f|
      = f.label :genetic
      = f.select :genetic, Coffee.get_genetic_values

Somewhere on a view:

    = select_tag :kind, Coffee.get_genetic_values

Specs
-----

Run the adapter independently:

    $ rspec spec/symbolize/mongoid_spec.rb
    $ rspec spec/symbolize/active_record_spec.rb


Notes
-----

This fork:
http://github.com/nofxx/symbolize
