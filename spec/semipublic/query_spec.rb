require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

require 'ostruct'

# TODO: make some of specs for Query.new shared.  the assertions and
# normalizations should happen for Query#update, Query#relative and
# Query#merge and should probably be in shared specs

# class methods
describe DataMapper::Query do
  before :all do
    class ::User
      include DataMapper::Resource

      property :name, String, :key => true

      belongs_to :referrer, :model => self
    end

    @repository = DataMapper::Repository.new(:default)
    @model      = User

    @fields       = [ :name ].freeze
    @links        = [ :referrer ].freeze
    @conditions   = { :name => 'Dan Kubb' }.freeze
    @offset       = 0
    @limit        = 1
    @order        = [ :name ].freeze
    @unique       = false
    @add_reversed = false
    @reload       = false

    @options = {
      :fields       => @fields,
      :links        => @links,
      :conditions   => @conditions,
      :offset       => @offset,
      :limit        => @limit,
      :order        => @order,
      :unique       => @unique,
      :add_reversed => @add_reversed,
      :reload       => @reload,
    }
  end

  it 'should respond to .new' do
    DataMapper::Query.should respond_to(:new)
  end

  describe '.new' do
    describe 'with a repository' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the repository' do
          @return.repository.should == @repository
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new('invalid', @model, @options)
          }.should raise_error(ArgumentError, '+repository+ should be DataMapper::Repository, but was String')
        end
      end
    end

    describe 'with a model' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the model' do
          @return.model.should == @model
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, 'invalid', @options)
          }.should raise_error(ArgumentError, '+model+ should be DataMapper::Model, but was String')
        end
      end
    end

    describe 'with a fields option' do
      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the fields' do
          @return.fields.should == @model.properties.values_at(*@fields)
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:fields] = [ 'name' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the fields' do
          @return.fields.should == @model.properties.values_at('name')
        end
      end

      describe 'that is an Array containing a Property' do
        before :all do
          @options[:fields] = @model.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the fields' do
          @return.fields.should == @model.properties.values_at(:name)
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:fields).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set fields to the model default properties' do
          @return.fields.should == @model.properties.defaults
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => :name))
          }.should raise_error(ArgumentError, '+options[:fields]+ should be Array, but was Symbol')
        end
      end

      describe 'that is an empty Array and the unique option is false' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [], :unique => false))
          }.should raise_error(ArgumentError, '+options[:fields]+ should not be empty if +options[:unique]+ is false')
        end
      end

      describe 'that is an Array containing an unknown Symbol' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ :unknown ]))
          }.should raise_error(ArgumentError, '+options[:fields]+ entry :unknown does not map to a property')
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ 'unknown' ]))
          }.should raise_error(ArgumentError, '+options[:fields]+ entry "unknown" does not map to a property')
        end
      end

      describe 'that is an Array containing an invalid object' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ 1 ]))
          }.should raise_error(ArgumentError, '+options[:fields]+ entry 1 of an unsupported object Fixnum')
        end
      end

      describe 'that is an Array containing an unknown Property' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:fields => [ DataMapper::Property.new(@model, :unknown, String) ]))
          }.should raise_error(ArgumentError, '+options[:field]+ entry :unknown does not map to a property')
        end
      end
    end

    describe 'with a links option' do
      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the links' do
          @return.links.should == @model.relationships.values_at(*@links)
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:links] = [ 'referrer' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the links' do
          @return.links.should == @model.relationships.values_at('referrer')
        end
      end

      describe 'that is an Array containing a Relationship' do
        before :all do
          @options[:links] = @model.relationships.values_at(:referrer)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the links' do
          @return.links.should == @model.relationships.values_at(:referrer)
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:links).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set links to an empty Array' do
          @return.links.should == []
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:links => :referral))
          }.should raise_error(ArgumentError, '+options[:links]+ should be Array, but was Symbol')
        end
      end

      describe 'that is an empty Array' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:links => []))
          }.should raise_error(ArgumentError, '+options[:links]+ should not be empty')
        end
      end

      describe 'that is an Array containing an unknown Symbol' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:links => [ :unknown ]))
          }.should raise_error(ArgumentError, '+options[:links]+ entry :unknown does not map to a relationship')
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:links => [ 'unknown' ]))
          }.should raise_error(ArgumentError, '+options[:links]+ entry "unknown" does not map to a relationship')
        end
      end

      describe 'that is an Array containing an invalid object' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:links => [ 1 ]))
          }.should raise_error(ArgumentError, '+options[:links]+ entry 1 of an unsupported object Fixnum')
        end
      end
    end

    describe 'with a conditions option' do
      describe 'that is a valid Hash' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the conditions' do
          @return.conditions.should == [ [ :eql, @model.properties[:name], @conditions[:name] ] ]
        end
      end

      describe 'that is a valid Array' do
        before :all do
          @options[:conditions] = [ 'name = ?', 'Dan Kubb' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the conditions' do
          @return.conditions.should == [ [ :raw, 'name = ?', [ 'Dan Kubb' ] ] ]
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:conditions).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set conditions to an empty Array' do
          @return.conditions.should == []
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => 'invalid'))
          }.should raise_error(ArgumentError, '+options[:conditions]+ should be Hash or Array, but was String')
        end
      end

      describe 'that is an empty Array' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:conditions => []))
          }.should raise_error(ArgumentError, '+options[:conditions]+ should not be empty')
        end
      end
    end

    describe 'with an offset option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the offset' do
          @return.offset.should == @offset
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:offset).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set offset to 0' do
          @return.offset.should == 0
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:offset => '0'))
          }.should raise_error(ArgumentError, '+options[:offset]+ should be Integer, but was String')
        end
      end

      describe 'that is less than 0' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:offset => -1))
          }.should raise_error(ArgumentError, '+options[:offset]+ must be greater than or equal to 0, but was -1')
        end
      end

      describe 'that is greater than 0 and a nil limit' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.except(:limit).update(:offset => 1))
          }.should raise_error(ArgumentError, '+options[:offset]+ cannot be greater than 0 if limit is not specified')
        end
      end
    end

    describe 'with a limit option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the limit' do
          @return.limit.should == @limit
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:limit).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set limit to nil' do
          @return.limit.should be_nil
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:limit => '1'))
          }.should raise_error(ArgumentError, '+options[:limit]+ should be Integer, but was String')
        end
      end

      describe 'that is less than 1' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:limit => 0))
          }.should raise_error(ArgumentError, '+options[:limit]+ must be greater than or equal to 1, but was 0')
        end
      end
    end

    describe 'with an order option' do
      describe 'that is an Array containing a Symbol' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the order' do
          @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a String' do
        before :all do
          @options[:order] = [ 'name' ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the order' do
          @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing a Property' do
        before :all do
          @options[:order] = @model.properties.values_at(:name)

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the order' do
          @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name]) ]
        end
      end

      describe 'that is an Array containing an Operator' do
        before :all do
          @options[:order] = [ :name.asc ]

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the order' do
          @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name], :asc) ]
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:order).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set order to the model default order' do
          @return.order.should == @model.default_order(@repository.name)
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:order => :name))
          }.should raise_error(ArgumentError, '+options[:order]+ should be Array, but was Symbol')
        end
      end

      describe 'that is an empty Array and the fields option contains a non-operator' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [], :fields => [ :name ]))
          }.should raise_error(ArgumentError, '+options[:order]+ should not be empty if +options[:fields] contains a non-operator')
        end
      end

      describe 'that is an Array containing an unknown String' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [ 'unknown' ]))
          }.should raise_error(ArgumentError, '+options[:order]+ entry "unknown" does not map to a property')
        end
      end

      describe 'that is an Array containing an invalid object' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:order => [ 1 ]))
          }.should raise_error(ArgumentError, '+options[:order]+ entry 1 of an unsupported object Fixnum')
        end
      end
    end

    describe 'with a unique option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the unique? flag' do
          @return.unique?.should == @unique
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:unique).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the query to not be unique' do
          @return.should_not be_unique
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:unique => nil))
          }.should raise_error(ArgumentError, '+options[:unique]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with an add_reversed option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the add_reversed? flag' do
          @return.add_reversed?.should == @add_reversed
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:add_reversed).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the query to not add in reverse order' do
          # TODO: think about renaming the flag to not sound 'clumsy'
          @return.should_not be_add_reversed
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:add_reversed => nil))
          }.should raise_error(ArgumentError, '+options[:add_reversed]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with a reload option' do
      describe 'that is valid' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the reload? flag' do
          @return.reload?.should == @reload
        end
      end

      describe 'that is missing' do
        before :all do
          @return = DataMapper::Query.new(@repository, @model, @options.except(:reload).freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the query to not reload' do
          @return.should_not be_reload
        end
      end

      describe 'that is invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, @options.update(:reload => nil))
          }.should raise_error(ArgumentError, '+options[:reload]+ should be true or false, but was nil')
        end
      end
    end

    describe 'with options' do
      describe 'that are unknown' do
        before :all do
          @options.update(@options.delete(:conditions))

          @return = DataMapper::Query.new(@repository, @model, @options.freeze)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should set the conditions' do
          @return.conditions.should == [ [ :eql, @model.properties[:name], @conditions[:name] ] ]
        end
      end

      describe 'that are invalid' do
        it 'should raise an exception' do
          lambda {
            DataMapper::Query.new(@repository, @model, 'invalid')
          }.should raise_error(ArgumentError, '+options+ should be Hash, but was String')
        end
      end
    end

    describe 'with no options' do
      before :all do
        @return = DataMapper::Query.new(@repository, @model)
      end

      it { @return.should be_kind_of(DataMapper::Query) }

      it 'should set options to an empty Hash' do
        @return.options.should == {}
      end
    end
  end
end

# instance methods
describe DataMapper::Query do
  before :all do
    class ::User
      include DataMapper::Resource

      property :name, String, :key => true

      belongs_to :referrer, :model => self
    end

    @repository = DataMapper::Repository.new(:default)
    @model      = User
    @options    = { :limit => 3 }
    @query      = DataMapper::Query.new(@repository, @model, @options)
    @original   = @query
  end

  before :all do
    @other_options = {
      :fields       => [ @model.properties[:name] ].freeze,
      :links        => [ @model.relationships[:referrer] ].freeze,
      :conditions   => [ 'name = ?', 'Dan Kubb' ].freeze,
      :offset       => 1,
      :limit        => 2,
      :order        => [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ].freeze,
      :unique       => true,
      :add_reversed => true,
      :reload       => true,
    }
  end

  it { @query.should respond_to(:==) }

  describe '#==' do
    describe 'when other is equal' do
      before :all do
        @return = @query == @query
      end

      it { @return.should be_true }
    end

    describe 'when other is equivalent' do
      before :all do
        @return = @query == @query.dup
      end

      it { @return.should be_true }
    end

    DataMapper::Query::OPTIONS.each do |name|
      describe "when other has an inequalvalent #{name}" do
        before :all do
          @return = @query == @query.merge(name => @other_options[name])
        end

        it { @return.should be_false }
      end
    end

    describe 'when other is a different type of object that can be compared, and is equivalent' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :fields        => @query.fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => @query.reload?,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query == @other
      end

      it { @return.should be_true }
    end

    describe 'when other is a different type of object that can be compared, and is not equivalent' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :fields        => @query.fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => true,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query == @other
      end

      it { @return.should be_false }
    end

    describe 'when other is a different type of object that cannot be compared' do
      before :all do
        @return = @query == 'invalid'
      end

      it { @return.should be_false }
    end
  end

  it { @query.should respond_to(:conditions) }

  describe '#conditions' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:dup) }

  describe '#dup' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:eql?) }

  describe '#eql?' do
    describe 'when other is equal' do
      before :all do
        @return = @query.eql?(@query)
      end

      it { @return.should be_true }
    end

    describe 'when other is eql' do
      before :all do
        @return = @query.eql?(@query.dup)
      end

      it { @return.should be_true }
    end

    DataMapper::Query::OPTIONS.each do |name|
      describe "when other has an not eql #{name}" do
        before :all do
          @return = @query.eql?(@query.merge(name => @other_options[name]))
        end

        it { @return.should be_false }
      end
    end

    describe 'when other is a different type of object' do
      before :all do
        @other = OpenStruct.new(
          :repository    => @query.repository,
          :model         => @query.model,
          :fields        => @query.fields,
          :links         => @query.links,
          :conditions    => @query.conditions,
          :order         => @query.order,
          :limit         => @query.limit,
          :offset        => @query.offset,
          :reload?       => @query.reload?,
          :unique?       => @query.unique?,
          :add_reversed? => @query.add_reversed?
        )

        @return = @query.eql?(@other)
      end

      it { @return.should be_false }
    end
  end

  it { @query.should respond_to(:fields) }

  describe '#fields' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:inspect) }

  describe '#inspect' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:limit) }

  describe '#limit' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:links) }

  describe '#links' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:merge) }

  describe '#merge' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:model) }

  describe '#model' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:offset) }

  describe '#offset' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:order) }

  describe '#order' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:relative) }

  describe '#relative' do
    describe 'with a Hash' do
      describe 'that is empty' do
        before :all do
          @return = @query.relative({})
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@query)
        end

        it 'should return a copy' do
          @return.should be_eql(@query)
        end
      end

      describe 'using a different repository as a Repository' do
        before :all do
          @repository = DataMapper::Repository.new(:other)
          @return = @query.relative(:repository => @repository)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should set the repository' do
          @return.repository.should equal(@repository)
        end
      end

      describe 'using a different repository as a Symbol' do
        before :all do
          @return = @query.relative(:repository => :other)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should set the repository' do
          @return.repository.should == DataMapper::Repository.new(:other)
        end
      end

      describe 'using different options' do
        before :all do
          @return = @query.relative(@other_options)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should update the fields' do
          @return.fields.should == @other_options[:fields]
        end

        it 'should update the links' do
          @return.links.should == @other_options[:links]
        end

        it 'should update the conditions' do
          @return.conditions.should == [ [ :raw, 'name = ?', [ 'Dan Kubb' ] ] ]
        end

        it 'should update the offset' do
          @return.offset.should == @other_options[:offset]
        end

        it 'should update the limit' do
          @return.limit.should == @other_options[:limit]
        end

        it 'should update the order' do
          @return.order.should == @other_options[:order]
        end

        it 'should update the unique' do
          @return.unique?.should == @other_options[:unique]
        end

        it 'should update the add_reversed' do
          @return.add_reversed?.should == @other_options[:add_reversed]
        end

        it 'should update the reload' do
          @return.reload?.should == @other_options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options = { :name => 'Dan Kubb' }

          @return = @query.relative(@options)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should update the conditions' do
          @return.conditions.should == [ [ :eql, @model.properties[:name], @options[:name] ] ]
        end
      end

      describe 'using an offset when query offset is greater than 0' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.relative(:offset => 1)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should update the offset to be relative to the original offset' do
          @return.offset.should == 2
        end
      end

      describe 'using an limit when query limit specified' do
        before :all do
          @query = @query.update(:offset => 1, :limit => 2)

          @return = @query.relative(:limit => 1)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it 'should not return self' do
          @return.should_not be_equal(@original)
        end

        it 'should update the limit' do
          @return.limit.should == 1
        end
      end
    end
  end

  it { @query.should respond_to(:reload?) }

  describe '#reload?' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:repository) }

  describe '#repository' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:reverse) }

  describe '#reverse' do
    before :all do
      @return = @query.reverse
    end

    it { @return.should be_kind_of(DataMapper::Query) }

    it 'should copy the Query' do
      @return.should_not be_equal(@original)
    end

    # TODO: push this into dup spec
    it 'should not reference original order' do
      @return.order.should_not be_equal(@original.order)
    end

    it 'should have a reversed order' do
      @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ]
    end

    it 'should be equivalent, except for order' do
      @return.to_hash.except(:order).should == @original.to_hash.except(:order)
    end
  end

  it { @query.should respond_to(:reverse!) }

  describe '#reverse!' do
    before :all do
      @return = @query.reverse!
    end

    it { @return.should be_kind_of(DataMapper::Query) }

    it { @return.should be_equal(@original) }

    it 'should have a reversed order' do
      @return.order.should == [ DataMapper::Query::Direction.new(@model.properties[:name], :desc) ]
    end
  end

  it { @query.should respond_to(:slice) }

  describe '#slice' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:to_hash) }

  describe '#to_hash' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:unique?) }

  describe '#unique?' do
    it 'should be awesome'
  end

  it { @query.should respond_to(:update) }

  describe '#update' do
    describe 'with a Query' do
      describe 'that is equivalent' do
        before :all do
          @other = DataMapper::Query.new(@repository, @model)

          @return = @query.update(@other)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }
      end

      describe 'using a different repository' do
        it 'should raise an exception' do
          lambda {
            @query.update(DataMapper::Query.new(DataMapper::Repository.new(:other), User))
          }.should raise_error(ArgumentError, '+other+ DataMapper::Query must be for the default repository, not other')
        end
      end

      describe 'using a different model' do
        before :all do
          class ::Clone
            include DataMapper::Resource

            property :name, String, :key => true
          end
        end

        it 'should raise an exception' do
          lambda {
            @query.update(DataMapper::Query.new(@repository, Clone))
          }.should raise_error(ArgumentError, '+other+ DataMapper::Query must be for the User model, not Clone')
        end
      end

      describe 'using different options' do
        before :all do
          @other = DataMapper::Query.new(@repository, @model, @options.update(@other_options))

          @return = @query.update(@other)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }

        it 'should update the fields' do
          @return.fields.should == @options[:fields]
        end

        it 'should update the links' do
          @return.links.should == @options[:links]
        end

        it 'should update the conditions' do
          @return.conditions.should == [ [ :raw, 'name = ?', [ 'Dan Kubb' ] ] ]
        end

        it 'should update the offset' do
          @return.offset.should == @options[:offset]
        end

        it 'should update the limit' do
          @return.limit.should == @options[:limit]
        end

        it 'should update the order' do
          @return.order.should == @options[:order]
        end

        it 'should update the unique' do
          @return.unique?.should == @options[:unique]
        end

        it 'should update the add_reversed' do
          @return.add_reversed?.should == @options[:add_reversed]
        end

        it 'should update the reload' do
          @return.reload?.should == @options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options.update(:name => 'Dan Kubb')
          @other = DataMapper::Query.new(@repository, @model, @options)

          @return = @query.update(@other)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }

        it 'should update the conditions' do
          @return.conditions.should == [ [ :eql, @model.properties[:name], @options[:name] ] ]
        end
      end
    end

    describe 'with a Hash' do
      describe 'that is empty' do
        before :all do
          @copy = @query.dup
          @return = @query.update({})
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }

        it 'should not change the Query' do
          @return.should == @copy
        end
      end

      describe 'using different options' do
        before :all do
          @return = @query.update(@other_options)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }

        it 'should update the fields' do
          @return.fields.should == @other_options[:fields]
        end

        it 'should update the links' do
          @return.links.should == @other_options[:links]
        end

        it 'should update the conditions' do
          @return.conditions.should == [ [ :raw, 'name = ?', [ 'Dan Kubb' ] ] ]
        end

        it 'should update the offset' do
          @return.offset.should == @other_options[:offset]
        end

        it 'should update the limit' do
          @return.limit.should == @other_options[:limit]
        end

        it 'should update the order' do
          @return.order.should == @other_options[:order]
        end

        it 'should update the unique' do
          @return.unique?.should == @other_options[:unique]
        end

        it 'should update the add_reversed' do
          @return.add_reversed?.should == @other_options[:add_reversed]
        end

        it 'should update the reload' do
          @return.reload?.should == @other_options[:reload]
        end
      end

      describe 'using extra options' do
        before :all do
          @options = { :name => 'Dan Kubb' }

          @return = @query.update(@options)
        end

        it { @return.should be_kind_of(DataMapper::Query) }

        it { @return.should be_equal(@original) }

        it 'should update the conditions' do
          @return.conditions.should == [ [ :eql, @model.properties[:name], @options[:name] ] ]
        end
      end
    end
  end
end
