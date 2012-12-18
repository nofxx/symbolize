# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper_ar'

#
# Test model
class User < ActiveRecord::Base
  symbolize :other
  symbolize :language, :in => [:pt, :en]
  symbolize :sex, :in => [true, false], :scopes => true
  symbolize :status , :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => true, :methods => true
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac   => 'Mac OS X',
    :win   => 'Videogame'
  }, :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => %w{ good bad ugly}, :methods => true, :i18n => false, :allow_nil => true
  symbolize :cool, :in => [true, false], :scopes => true

  symbolize :role, :in => [:reader, :writer, :some_existing_attr], :i18n => false, :methods => true, :default => :reader
  symbolize :country, :in => [:us, :gb, :pt, :ru], :capitalize => true, :i18n => false  # note: the default value is provided in db migration

  has_many :extras, :dependent => :destroy, :class_name => "UserExtra"
  has_many :access, :dependent => :destroy, :class_name => "UserAccess"
end

class UserSkill < ActiveRecord::Base
  symbolize :kind, :in => [:agility, :magic]
end

class UserExtra < ActiveRecord::Base
  symbolize :key, :in => [:one, :another]
end

class Permission < ActiveRecord::Base
  validates_presence_of :name
  symbolize :kind, :in => [:temp, :perm], :default => :perm
  symbolize :lvl, :in => (1..9).to_a, :i18n => false#, :default => 1
end

# Make with_scope public-usable for testing
#if ActiveRecord::VERSION::MAJOR < 3
class << ActiveRecord::Base
  public :with_scope
end
#end


describe "Symbolize" do

  it "should respond to symbolize" do
    ActiveRecord::Base.should respond_to :symbolize
  end

  it "should have a valid blueprint" do
    # Test records
    u = User.create(:name => 'Bob' , :other => :bar,:status => :inactive, :so => :mac, :gui => :gtk, :language => :en, :sex => false, :cool => false)
    u.errors.messages.should be_blank
  end

  it "should work nice with default values from active model" do
    u = User.create(:name => 'Niu' , :other => :bar, :so => :mac, :gui => :gtk, :language => :en, :sex => false, :cool => false)
    u.errors.messages.should be_blank
    u.status.should eql(:active)
    u.should be_active
  end

  describe "User Instantiated" do
    subject {
      User.create(:name => 'Anna', :other => :fo, :status => status, :so => so, :gui => :qt, :language => :pt, :sex => true, :cool => true)
    }
    let(:status) { :active }
    let(:so) { :linux }

    describe "test_symbolize_string" do
      let(:status) { 'inactive' }
      its(:status) { should == :inactive }
      #      @user.status_before_type_cast.should eql(:inactive)
      # @user.read_attribute(:status).should eql('inactive')
    end

    describe "test_symbolize_symbol" do
      its(:status) { should == :active }
      its(:status_before_type_cast) { should == :active }
      # @user.read_attribute(:status).should eql('active')
    end

    describe "should work nice with numbers" do
      let(:status) { 43 }
      its(:status) { should be_present }
      # @user.status_before_type_cast.should be_nil
      # @user.read_attribute(:status).should be_nil
    end

    describe "should acts nice with nil" do
      let(:status) { nil }
      its(:status) { should be_nil }
      its(:status_before_type_cast) { should be_nil }
      it { subject.read_attribute(:status).should be_nil }
    end

    describe "should acts nice with blank" do
      let(:status) { "" }
      its(:status) { should be_nil }
      its(:status_before_type_cast) { should be_nil }
      it { subject.read_attribute(:status).should be_nil }
    end

    describe "test_symbols_quoted_id" do
      pending { subject.status.quoted_id.should eql("'active'") }
    end

    it "should not validates other" do
      subject.other = nil
      subject.should be_valid
      subject.other = ""
      subject.should be_valid
    end

    it "should get the correct values" do
      User.get_status_values.should eql([["Active", :active],["Inactive", :inactive]])
      User::STATUS_VALUES.should eql({:inactive=>"Inactive", :active=>"Active"})
    end

    it "should get the values for RailsAdmin" do
      User.status_enum.should eql([["Active", :active],["Inactive", :inactive]])
    end

    describe "test_symbolize_humanize" do
      its(:status_text) { should eql("Active") }
    end

    it "should get the correct values" do
      User.get_gui_values.should =~ [["cocoa", :cocoa], ["qt", :qt], ["gtk", :gtk]]
      User::GUI_VALUES.should eql({:cocoa=>"cocoa", :qt=>"qt", :gtk=>"gtk"})
    end

    describe "test_symbolize_humanize" do
      its(:gui_text) { should eql("qt") }
    end

    it "should get the correct values" do
      User.get_so_values.should =~ [["Linux", :linux], ["Mac OS X", :mac], ["Videogame", :win]]
      User::SO_VALUES.should eql({:linux => "Linux", :mac => "Mac OS X", :win => "Videogame"})
    end

    describe "test_symbolize_humanize" do
      its(:so_text) { should eql("Linux") }
    end

    describe "test_symbolize_humanize" do
      let(:so) { :mac }
      its(:so_text) { should eql("Mac OS X") }
    end

    it "should stringify" do
      subject.other_text.should eql("fo")
      subject.other = :foo
      subject.other_text.should eql("foo")
    end

    describe "should validate status" do
      let(:status) { nil }
      it { should_not be_valid }
      it { should have(1).errors }
    end

    it "should not validate so" do
      subject.so = nil
      subject.should be_valid
    end

    it "test_symbols_with_weird_chars_quoted_id" do
      subject.status = :"weird'; chars"
      subject.status_before_type_cast.should eql(:"weird'; chars")
      #    assert_equal "weird'; chars", @user.read_attribute(:status)
      #   assert_equal "'weird''; chars'", @user.status.quoted_id
    end

    it "should work fine through relations" do
      subject.extras.create(:key => :one)
      UserExtra.first.key.should eql(:one)
    end

    it "should play fine with null db columns" do
      new_extra = subject.extras.build
      new_extra.should_not be_valid
    end

    it "should play fine with null db columns" do
      new_extra = subject.extras.build
      new_extra.should_not be_valid
    end

    describe "i18n" do

      it "should test i18n ones" do
        subject.language_text.should eql("Português")
      end

      it "should get the correct values" do
        User.get_language_values.should =~ [["Português", :pt], ["Inglês", :en]]
      end

      it "should get the correct values" do
        User::LANGUAGE_VALUES.should eql({:pt=>"pt", :en=>"en"})
      end

      it "should test boolean" do
        subject.sex_text.should eql("Feminino")
        subject.sex = false
        subject.sex_text.should eql('Masculino')
      end

      it "should get the correct values" do
        User.get_sex_values.should eql([["Feminino", true],["Masculino", false]])
      end

      it "should get the correct values" do
        User::SEX_VALUES.should eql({true=>"true", false=>"false"})
      end

      it "should translate a multiword class" do
        @skill = UserSkill.create(:kind => :magic)
        @skill.kind_text.should eql("Mágica")
      end

      it "should return nil if there's no value" do
        @skill = UserSkill.create(:kind => nil)
        @skill.kind_text.should be_nil
      end

    end

    describe "Methods" do

      it "should play nice with other stuff" do
        subject.karma.should be_nil
        User::KARMA_VALUES.should eql({:bad => "bad", :ugly => "ugly", :good => "good"})
      end

      it "should provide a boolean method" do
        subject.should_not be_good
        subject.karma = :ugly
        subject.should be_ugly
      end

      it "should work" do
        subject.karma = "good"
        subject.should be_good
        subject.should_not be_bad
      end

    end

    describe "Methods" do

      it "is dirty if you change the attribute value" do
        subject.language.should == :pt
        subject.language_changed?.should be_false

        return_value = subject.language = :en
        return_value.should == :en
        subject.language_changed?.should be_true
      end

      it "is not dirty if you set the attribute value to the same value" do
        subject.language.should == :pt
        subject.language_changed?.should be_false

        return_value = subject.language = :pt
          return_value.should == :pt
        subject.language_changed?.should be_false
      end

    end

  end

  describe "more tests on Permission" do

    it "should use default value on object build" do
      Permission.new.kind.should eql(:perm)
    end

    it "should not interfer on create" do
      Permission.create!(:name => "p7", :kind =>:temp, :lvl => 7)
      Permission.find_by_name("p7").kind.should eql(:temp)
    end

    it "should work on create" do
      pm = Permission.new(:name => "p7", :lvl => 7)
      pm.should be_valid
      pm.save.should be_true
    end

    it "should work on create" do
      Permission.create!(:name => "p8", :lvl => 9)
      Permission.find_by_name("p8").kind.should eql(:perm)
    end

    it "should work on edit" do
      Permission.create!(:name => "p8", :lvl => 9)
      pm = Permission.find_by_name("p8")
      pm.kind = :temp
      pm.save
      Permission.find_by_name("p8").kind.should eql(:temp)
    end

    it "should work with default values" do
      pm = Permission.new(:name => "p9")
      pm.lvl = 9
      pm.save
      Permission.find_by_name("p9").lvl.to_i.should eql(9)
    end

  end

  describe "Named Scopes" do

    before do
      @anna = User.create(:name => 'Anna', :other => :fo, :status => :active  , :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true)
      @mary = User.create(:name => 'Mary', :other => :fo, :status => :inactive, :so => :mac,   :language => :pt, :sex => true, :cool => true)
    end

    it "test_symbolized_finder" do
      User.where({ :status => :inactive }).all.map(&:name).should eql(['Mary'])
      User.find_all_by_status(:inactive).map(&:name).should eql(['Mary'])
    end

    it "test_symbolized_with_scope" do
      User.with_scope(:find => { :conditions => { :status => :inactive }}) do
        User.all.map(&:name).should eql(['Mary'])
      end
    end

    it "should have main named scope" do
      User.inactive.should == [@mary]
    end

    it "should have other to test better" do
      User.linux.should == [@anna]
    end

    # it "should have 'with' helper" do
    #   User.with_sex.should == [@anna]
    # end

    # it "should have 'without' helper" do
    #   User.without_sex.should == [@bob]
    # end

    # it "should have 'attr_name' helper" do
    #   User.cool.should == [@anna]
    # end

    # it "should have 'not_attr_name' helper" do
    #   User.not_cool.should == [@bob]
    # end

  end


  describe ": Default Value" do
    before(:each) do
      @user = User.new(:name => 'Anna', :other => :fo, :status => :active  , :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true)
    end

    it "should be considered during validation" do
      @user.valid?
      @user.errors.full_messages.should == []
    end

    it "should be taken from the DB schema definition" do
      @user.country.should == :pt
      @user.country_text.should == "Pt"
    end

    it "should be applied to new, just saved, and reloaded objects, and also play fine with :methods option" do
      @user.role.should == :reader
      @user.role_text.should == "reader"
      @user.should be_reader
      @user.save!
      @user.role.should == :reader
      @user.should be_reader
      @user.reload
      @user.role.should == :reader
      @user.should be_reader
    end

    it "should be overridable" do
      @user.role = :writer
      @user.role.should == :writer
      @user.should be_writer
      @user.save!
      @user.role.should == :writer
      @user.should be_writer
      @user.reload
      @user.role.should == :writer
      @user.should be_writer
    end

    # This feature is for the next major version (b/o the compatibility problem)
    pending "should detect name collision caused by ':methods => true' option" do
      lambda {
        User.class_eval do
          # 'reader?' method is already defined, so the line below should raise an error
          symbolize :some_attr, :in => [:reader, :guest], :methods => true
        end
      }.should raise_error(ArgumentError)
    end

  end
end
