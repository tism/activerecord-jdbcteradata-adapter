require 'spec_helper'

require 'models/simple_article'
require 'models/lowercase_model'

describe 'Adapter' do

  context 'instance methods' do
    before(:all) do
      CreateArticles.up
      @adapter = Article.connection
    end

    it '#adapter_name' do
      @adapter.adapter_name.should eq('Teradata')
    end

    it '#supports_migrations?' do
      @adapter.supports_migrations?.should be_true
    end

    it '#native_database_types' do
      @adapter.native_database_types.count.should > 0
    end

    it '#database_name' do
      @adapter.database_name.should == 'weblog_development'
    end

    it '#active?' do
      @adapter.active?.should be_true
    end

    it '#exec_query' do
      article_1 = Article.create(:title => 'exec_query_1', :body => 'exec_query_1')
      article_2 = Article.create(:title => 'exec_query_2', :body => 'exec_query_2')
      articles = @adapter.exec_query('select * from articles')

      articles.select { |i| i['title'] == article_1.title }.first.should_not be_nil
      articles.select { |i| i['title'] == article_2.title }.first.should_not be_nil
    end

    it '#last_insert_id(table)' do
      article_1 = Article.create(:title => 'exec_query_1', :body => 'exec_query_1')
      article_1.id.should eq(@adapter.last_insert_id('articles'))

      article_2 = Article.create(:title => 'exec_query_2', :body => 'exec_query_2')

      article_1.id.should_not eq(article_2.id)

      article_2.id.should eq(@adapter.last_insert_id('articles'))
    end

    it '#tables' do
      @adapter.tables.should include('articles')
    end

    it '#table_exists?' do
      @adapter.table_exists?('articles').should be_true
    end

    it '#indexes' do
      id_index = @adapter.indexes('articles').first
      id_index.table.should eq('articles')
      id_index.name.should == ''
      id_index.unique.should be_true
      id_index.columns.should eq(%w(id))
    end

    it '#pk_and_sequence_for' do
      @adapter.pk_and_sequence_for('articles').should eq(['id', nil])
    end

    it '#primary_key' do
      @adapter.primary_key('articles').should eq('id')
    end

    after(:all) do
      CreateArticles.down
    end

  end

  context 'testing #lowercase_schema_reflection' do
    before(:each) do
      CreateShirts.up
      Shirt.reset_column_information
      @connection = Shirt.connection
    end

    it 'should be able to use uppercase attributes' do
      @connection.lowercase_schema_reflection = false
      shirt = Shirt.new
      shirt.COLOR = 'blue'
      shirt.STATUS_CODE = 'good'
      shirt.save

      Shirt.where(:COLOR => 'blue', :STATUS_CODE => 'good').count.should eq(1)
    end

    it 'should be able to use lowercase attributes when #lowercase_schema_reflection = true' do
      @connection.lowercase_schema_reflection = true

      shirt = Shirt.new
      shirt.color = 'red'
      shirt.status_code = 'very red'
      shirt.save

      Shirt.where(:color => 'red', :status_code => 'very red').count.should eq(1)
    end

    it 'should be able to use lowercase attributes when ActiveRecord::ConnectionAdapters::TeradataAdapter.lowercase_schema_reflection = true' do
      ActiveRecord::ConnectionAdapters::TeradataAdapter.lowercase_schema_reflection = true

      shirt = Shirt.new
      shirt.color = 'orange'
      shirt.status_code = 'very orange'
      shirt.save

      Shirt.where(:color => 'orange', :status_code => 'very orange').count.should eq(1)
    end

    it 'should be able to use uppercase attributes when ActiveRecord::ConnectionAdapters::TeradataAdapter.lowercase_schema_reflection = false' do
      ActiveRecord::ConnectionAdapters::TeradataAdapter.lowercase_schema_reflection = false

      shirt = Shirt.new
      shirt.COLOR = 'yellow'
      shirt.STATUS_CODE = 'somewhat yellow'
      shirt.save

      Shirt.where(:COLOR => 'yellow', :STATUS_CODE => 'somewhat yellow').count.should eq(1)
    end

    after(:each) do
      CreateShirts.down
    end
  end
end
