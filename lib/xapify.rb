# Adds Xapian indexing to a model
module Xapify
  include XapianFu
  
  module ClassMethods
    # Sets the fields or methods to index (optionally with a type)
    #  xapify_fields :fields, :method => Hash
    def xapify_fields(*args)
      opts = args.extract_options!
      
      class << self
        attr_accessor :xap_db, :xap_fields
      end
      
      @xap_fields = { :_id => { :store => true, :type => String } }
      args.each do |arg|
        kind = String
        
        if key?(arg)
          kind = keys[arg].type
        elsif arg.is_a? Hash
          kind = arg.values.first
          arg = arg.keys.first
        end
        
        @xap_fields[arg.to_sym] = { :store => true, :type => kind }
      end
      
      if Rails.env == 'test'
        @xap_db = Xapify::XapianDb.new(:create => true, :fields => @xap_fields)
      else
        Dir.mkdir("#{Rails.root}/index") unless File.exists?("#{Rails.root}/index")
        Dir.mkdir("#{Rails.root}/index/#{Rails.env}") unless File.exists?("#{Rails.root}/index/#{Rails.env}")
        
        # Switch to in-memory to avoid writelocks
        # @xap_db = Xapify::XapianDb.new(:create => true, :fields => @xap_fields)
        @xap_db = Xapify::XapianDb.new(:dir => "#{Rails.root}/index/#{Rails.env}/#{name}.db", :create => true, :fields => @xap_fields)
      end
    end
    
    # Returns xapian search records
    #  results = Model.search "search string", *options
    #    :from_mongo => true          # load the records from mongo
    #    :collapse => :field          # Group by and sort on the count for this field
    #    :page => x, :per_page => y   # Paginates the results (results.total_pages is available)
    def search(*args)
      opts = args.extract_options!
      opts = { :from_mongo => false }.update(opts)
      string = args.first
      
      db = @xap_db
      
      begin
        docs = db.search(string, opts)
      rescue
        return []
      end
      
      collected = docs.collect do |doc|
        hash = {}
        @xap_fields.each_key do |key|
          hash[key] = [Array, Hash].include?(@xap_fields[key][:type]) ? JSON.load(doc.values[key]) : doc.values[key]
        end
        
        hash[:collapse_count] = doc.match.collapse_count if opts.has_key?(:collapse)
        hash
      end
      
      collected = collected.sort{ |a, b| b[:collapse_count] <=> a[:collapse_count] } if opts.has_key?(:collapse)
      collected = collected.map{ |doc| find(doc[:_id]) }.select{ |c| c } if opts[:from_mongo]
      
      collected.instance_variable_set "@total_pages", docs.total_pages
      def collected.total_pages; @total_pages; end
      
      collected
    end
  end

  module InstanceMethods
    # Callback to add the record to xapian
    def update_xapian
      update_timestamps if new?
      db = self.class.xap_db
      
      doc_hash = {}
      doc_hash[:id] = self.xap_id
      self.class.xap_fields.each do |field|
        doc_hash[field.first.to_sym] = self.send(field.first.to_sym) unless field== :_id
      end
      
      counter = 0
      
      begin
        inserted = db.add_doc doc_hash
        counter += 1
      rescue
        sleep(0.1)
        retry unless counter > 50
      end
      
      self.xap_id = inserted.id
    end
    
    # Callback to remove the record from xapian
    def remove_from_xapian
      self.class.xap_db.documents.delete(self.xap_id)
    end
  end
  
  # Sets up callbacks and keys
  def self.configure(base)
    base.before_save :update_xapian
    base.after_destroy :remove_from_xapian
    base.key :xap_id, Fixnum
  end
end

MongoMapper::Plugins.send :include, Xapify
