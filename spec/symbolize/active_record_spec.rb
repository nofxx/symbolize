# -*- coding: utf-8 -*-
require 'spec_helper'

#
# Test model
class User < ActiveRecord::Base
  symbolize :other
  symbolize :language, :in => [:pt, :en]
  symbolize :sex, :in => [true, false], :scopes => true, :allow_nil => true
  symbolize :status, :in => [:active, :inactive], :i18n => false, :capitalize => true, :scopes => :shallow, :methods => true
  symbolize :so, :allow_blank => true, :in => {
    :linux => 'Linux',
    :mac => 'Mac OS X',
    :win => 'Videogame',
  },             :scopes => true
  symbolize :gui, :allow_blank => true, :in => [:cocoa, :qt, :gtk], :i18n => false
  symbolize :karma, :in => %w(good bad ugly), :methods => true, :i18n => false, :allow_nil => true
  symbolize :city, :in => %w(sf nyc), :case_insensitive_methods => true, :i18n => false, :allow_nil => true
  symbolize :cool, :in => [true, false], :scopes => true

  symbolize :role, :in => [:reader, :writer, :some_existing_attr], :i18n => false, :methods => true, :default => :reader
  symbolize :country, :in => [:us, :gb, :pt, :ru], :capitalize => true, :i18n => false  # note: the default value is provided in db migration

  has_many :extras, :dependent => :destroy, :class_name => 'UserExtra'
  has_many :access, :dependent => :destroy, :class_name => 'UserAccess'
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
  symbolize :lvl, :in => (1..9).to_a, :i18n => false # , :default => 1
end

class PermissionSubclass < Permission
  symbolize :sub_lvl
end

describe 'Symbolize' do
  before do
    [User, Permission].each(&:delete_all)
  end

  it 'should respond to symbolize' do
    expect(ActiveRecord::Base).to respond_to :symbolize
  end

  it 'should have a valid blueprint' do
    # Test records
    u = User.create(:name => 'Bob', :other => :bar, :status => :inactive,
                    :so => :mac, :gui => :gtk, :language => :en, :cool => false)
    expect(u.errors.messages).to be_blank
  end

  it 'should work nice with default values from active model' do
    u = User.create(:name => 'Niu', :other => :bar, :so => :mac,
                    :language => :en, :cool => false)
    expect(u.errors.messages).to be_blank
    expect(u.status).to eql(:active)
    expect(u).to be_active
  end

  describe '.symbolized_attributes' do
    it 'returns the symbolized attribute for the class' do
      expect(UserExtra.symbolized_attributes).to eq ['key']
      expect(Permission.symbolized_attributes).to match_array %w(kind lvl)
      expect(PermissionSubclass.symbolized_attributes).to match_array %w(kind lvl sub_lvl)
    end
  end

  describe 'User Instantiated' do
    subject do
      User.create(:name => 'Anna', :other => :fo, :status => status, :so => so,
                  :gui => :qt, :language => 'pt', :sex => true, :cool => true)
    end
    let(:status) { :active }
    let(:so) { :linux }

    describe 'test_symbolize_string' do
      let(:status) { 'inactive' }

      describe '#status' do
        subject { super().status }
        it { is_expected.to eq(:inactive) }
      end
      #      @user.status_before_type_cast.should eql(:inactive)
      # @user.read_attribute(:status).should eql('inactive')
    end

    describe 'test_symbolize_symbol' do
      describe '#status' do
        subject { super().status }
        it { is_expected.to eq(:active) }
      end

      describe '#status_before_type_cast' do
        subject { super().status_before_type_cast }
        it { is_expected.to eq(:active) }
      end

      describe '#status_before_type_cast' do
        subject { super().attributes['language'] }
        it { is_expected.to eq(:pt) }
      end
    end

    describe 'should work nice with numbers' do
      let(:status) { 43 }

      describe '#status' do
        subject { super().status }
        it { is_expected.to be_present }
      end
      # @user.status_before_type_cast.should be_nil
      # @user.read_attribute(:status).should be_nil
    end

    describe 'should acts nice with nil' do
      let(:status) { nil }

      describe '#status' do
        subject { super().status }
        it { is_expected.to be_nil }
      end

      describe '#status_before_type_cast' do
        subject { super().status_before_type_cast }
        it { is_expected.to be_nil }
      end
      it { expect(subject.read_attribute(:status)).to be_nil }
    end

    describe 'should acts nice with blank' do
      let(:status) { '' }

      describe '#status' do
        subject { super().status }
        it { is_expected.to be_nil }
      end

      describe '#status_before_type_cast' do
        subject { super().status_before_type_cast }
        it { is_expected.to be_nil }
      end
      it { expect(subject.read_attribute(:status)).to be_nil }
    end

    it 'should not validates other' do
      subject.other = nil
      expect(subject).to be_valid
      subject.other = ''
      expect(subject).to be_valid
    end

    it 'should get the correct values' do
      expect(User.get_status_values).to eql([['Active', :active], ['Inactive', :inactive]])
      expect(User::STATUS_VALUES).to eql(:inactive => 'Inactive', :active => 'Active')
    end

    it 'should get the values for RailsAdmin' do
      expect(User.status_enum).to eql([['Active', :active], ['Inactive', :inactive]])
    end

    describe 'test_symbolize_humanize' do
      describe '#status_text' do
        subject { super().status_text }
        it { is_expected.to eql('Active') }
      end
    end

    it 'should get the correct values' do
      expect(User.get_gui_values).to match_array([['cocoa', :cocoa], ['qt', :qt], ['gtk', :gtk]])
      expect(User::GUI_VALUES).to eql(:cocoa => 'cocoa', :qt => 'qt', :gtk => 'gtk')
    end

    describe 'test_symbolize_humanize' do
      describe '#gui_text' do
        subject { super().gui_text }
        it { is_expected.to eql('qt') }
      end
    end

    it 'should get the correct values' do
      expect(User.get_so_values).to match_array([['Linux', :linux], ['Mac OS X', :mac], ['Videogame', :win]])
      expect(User::SO_VALUES).to eql(:linux => 'Linux', :mac => 'Mac OS X', :win => 'Videogame')
    end

    describe 'test_symbolize_humanize' do
      describe '#so_text' do
        subject { super().so_text }
        it { is_expected.to eql('Linux') }
      end
    end

    describe 'test_symbolize_humanize' do
      let(:so) { :mac }

      describe '#so_text' do
        subject { super().so_text }
        it { is_expected.to eql('Mac OS X') }
      end
    end

    it 'should stringify' do
      expect(subject.other_text).to eql('fo')
      subject.other = :foo
      expect(subject.other_text).to eql('foo')
    end

    describe 'should validate status' do
      let(:status) { nil }
      it { is_expected.not_to be_valid }
      it 'has 1 error' do
        expect(subject.errors.size).to eq(1)
      end
    end

    it 'should not validate so' do
      subject.so = nil
      expect(subject).to be_valid
    end

    it 'test_symbols_with_weird_chars_quoted_id' do
      subject.status = :"weird'; chars"
      expect(subject.status_before_type_cast).to eql(:"weird'; chars")
    end

    it 'should work fine through relations' do
      subject.extras.create(:key => :one)
      expect(UserExtra.first.key).to eql(:one)
    end

    it 'should play fine with null db columns' do
      new_extra = subject.extras.build
      expect(new_extra).not_to be_valid
    end

    it 'should play fine with null db columns' do
      new_extra = subject.extras.build
      expect(new_extra).not_to be_valid
    end

    describe 'i18n' do

      it 'should test i18n ones' do
        expect(subject.language_text).to eql('Português')
      end

      it 'should get the correct values' do
        expect(User.get_language_values).to match_array([['Português', :pt], ['Inglês', :en]])
      end

      it 'should get the correct values' do
        expect(User::LANGUAGE_VALUES).to eql(:pt => 'pt', :en => 'en')
      end

      it 'should test boolean' do
        expect(subject.sex_text).to eql('Feminino')
        subject.sex = false
        expect(subject.sex_text).to eql('Masculino')
      end

      it 'should recognize 0 as false on boolean fields' do
        subject.update_attribute(:sex, '0')
        expect(subject.sex).to eq(false)
      end

      it 'should recognize 1 as true on boolean fields' do
        subject.update_attribute(:sex, '1')
        expect(subject.sex).to eq(true)
      end

      it 'should get the correct values' do
        expect(User.get_sex_values).to eql([['Feminino', true], ['Masculino', false]])
      end

      it 'should get the correct values' do
        expect(User::SEX_VALUES).to eql(true => 'true', false => 'false')
      end

      it 'should translate a multiword class' do
        @skill = UserSkill.create(:kind => :magic)
        expect(@skill.kind_text).to eql('Mágica')
      end

      it "should return nil if there's no value" do
        @skill = UserSkill.create(:kind => nil)
        expect(@skill.kind_text).to be_nil
      end

    end

    describe 'Methods' do

      it 'should play nice with other stuff' do
        expect(subject.karma).to be_nil
        expect(User::KARMA_VALUES).to eql(:bad => 'bad', :ugly => 'ugly', :good => 'good')
      end

      it 'should provide a boolean method' do
        expect(subject).not_to be_good
        subject.karma = :ugly
        expect(subject).to be_ugly
      end

      it 'should work' do
        subject.karma = 'good'
        expect(subject).to be_good
        expect(subject).not_to be_bad
      end

    end

    describe 'Case Insensitive Methods' do
      it 'provides case insensitive boolean methods' do
        expect(subject).to respond_to(:sf?)
        expect(subject).to respond_to(:SF?)
        expect(subject).to respond_to(:nyc?)
        expect(subject).to respond_to(:NYC?)
      end
    end

    describe 'Changes' do

      it 'is dirty if you change the attribute value' do
        expect(subject.language).to eq(:pt)
        expect(subject.language_changed?).to be false

        return_value = subject.language = :en
        expect(return_value).to eq(:en)
        expect(subject.language_changed?).to be true
      end

      it 'is not dirty if you set the attribute value to the same value' do
        expect(subject.language).to eq(:pt)
        expect(subject.language_changed?).to be false

        return_value = subject.language = :pt
        expect(return_value).to eq(:pt)
        expect(subject.language_changed?).to be false
      end

      it 'is not changed if you set the attribute value to the same value' do
        subject.language = :pt
        expect(subject.changed).to be_empty
      end

      it 'is not dirty if you set the value to the same but as string' do
        expect(subject.language).to eq(:pt)
        expect(subject.language_changed?).to be false

        subject.language = 'pt'
        expect(subject.language_changed?).to be false
      end

      it 'is not dirty if you set the default attribute value to the same value' do
        user = User.create!(:language => :pt, :sex => true, :cool => true)
        expect(user.status).to eq(:active)
        expect(user).not_to be_changed

        user.status = :active
        expect(user).not_to be_changed
      end

      it 'is not dirty if you set the default attribute value to the same value (string)' do
        user = User.create!(:language => :pt, :sex => true, :cool => true)
        expect(user.status).to eq(:active)
        expect(user).not_to be_changed

        user.status = 'active'
        expect(user).not_to be_changed
      end
    end

  end

  describe 'more tests on Permission' do

    it 'should use default value on object build' do
      expect(Permission.new.kind).to eql(:perm)
    end

    it 'should not interfer on create' do
      Permission.create!(:name => 'p7', :kind => :temp, :lvl => 7)
      expect(Permission.find_by_name('p7').kind).to eql(:temp)
    end

    it 'should work on create' do
      pm = Permission.new(:name => 'p7', :lvl => 7)
      expect(pm).to be_valid
      expect(pm.save).to be true
    end

    it 'should work on create' do
      Permission.create!(:name => 'p8', :lvl => 9)
      expect(Permission.find_by_name('p8').kind).to eql(:perm)
    end

    it 'should work on edit' do
      Permission.create!(:name => 'p8', :lvl => 9)
      pm = Permission.find_by_name('p8')
      pm.kind = :temp
      pm.save
      expect(Permission.find_by_name('p8').kind).to eql(:temp)
    end

    it 'should work with default values' do
      pm = Permission.new(:name => 'p9')
      pm.lvl = 9
      pm.save
      expect(Permission.find_by_name('p9').lvl.to_i).to eql(9)
    end

    it 'should work with attributes' do
      Permission.create!(:name => 'p88', :kind => 'temp', :lvl => 8)
      expect(Permission.find_by_name('p88').kind).to eql(:temp)
    end

  end

  describe 'Named Scopes' do

    before do
      @anna = User.create(:name => 'Anna', :other => :fo, :status => :active, :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true)
      @mary = User.create(:name => 'Mary', :other => :fo, :status => :inactive, :so => :mac,   :language => :pt, :sex => true, :cool => true)
    end

    it 'test_symbolized_finder' do
      expect(User.where(:status => :inactive).all.map(&:name)).to eql(['Mary'])
    end

    it 'test_symbolized_scoping' do
      User.where(:status => :inactive).scoping do
        expect(User.all.map(&:name)).to eql(['Mary'])
      end
    end

    it 'should have main named scope' do
      expect(User.inactive).to eq([@mary])
    end

    it 'should have other to test better' do
      expect(User.so(:linux)).to eq([@anna])
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

  describe ': Default Value' do
    before(:each) do
      @user = User.new(:name => 'Anna', :other => :fo, :status => :active, :so => :linux, :gui => :qt, :language => :pt, :sex => true, :cool => true)
    end

    it 'should be considered during validation' do
      @user.valid?
      expect(@user.errors.full_messages).to eq([])
    end

    it 'should be taken from the DB schema definition' do
      expect(@user.country).to eq(:pt)
      expect(@user.country_text).to eq('Pt')
    end

    it 'should be applied to new, just saved, and reloaded objects, and also play fine with :methods option' do
      expect(@user.role).to eq(:reader)
      expect(@user.role_text).to eq('reader')
      expect(@user).to be_reader
      @user.save!
      expect(@user.role).to eq(:reader)
      expect(@user).to be_reader
      @user.reload
      expect(@user.role).to eq(:reader)
      expect(@user).to be_reader
    end

    it 'should be overridable' do
      @user.role = :writer
      expect(@user.role).to eq(:writer)
      expect(@user).to be_writer
      @user.save!
      expect(@user.role).to eq(:writer)
      expect(@user).to be_writer
      @user.reload
      expect(@user.role).to eq(:writer)
      expect(@user).to be_writer
    end

    # This feature is for the next major version (b/o the compatibility problem)
    it "should detect name collision caused by ':methods => true' option" do
      pending 'next major version'
      expect do
        User.class_eval do
          # 'reader?' method is already defined, so the line below should raise an error
          symbolize :some_attr, :in => [:reader, :guest], :methods => true
        end
      end.to raise_error(ArgumentError)
    end

  end
end
