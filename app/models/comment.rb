# A Comment on a Discussion by a User
class Comment
  include MongoMapper::Document
  plugin Xapify
  
  key :discussion_id, ObjectId
  key :response_to_id, ObjectId
  key :author_id, ObjectId, :required => true
  key :upvotes, Array
  key :body, String, :required => true
  key :tags, Array
  key :mentions, Array # mentioned Focii, whether these make their way up to the discussion level is TBD
  timestamps!
  
  xapify_fields :discussion_id, :focus_type, :focus_id, :body, :keywords, :mentions, :created_at
  
  belongs_to :discussion
  belongs_to :author, :class_name => "User"
  many :events, :as => :eventable
  
  after_create :push_tags
  
  def keywords
    self.tags
  end
  
  def response_to=(comment)
    self.response_to_id = comment.id
    self.save if self.changed?
    @cached_response_to = comment
  end
  
  def response_to
    @cached_response_to ||= Comment.find(self.response_to_id)
  end
  
  def is_a_response?
    self.response_to_id.nil? ? false : true
  end
  
  # Atomic operation to let a User vote for a Comment
  def cast_vote_by(user)
    return if author.id == user.id
    Comment.collection.update({ '_id' => self.id }, {'$addToSet' => { 'upvotes' => user.id } })
  end
  
  def self.most_recent(no=10)
    Comment.limit(no).sort(['created_at', -1]).all(:created_at.gt => Time.now - 1.day)
  end
  
  # Finds comments mentioning a focus
  def self.mentioning(focus, *args)
    opts = { :limit => 10, :order => ['created_at', -1] }
    opts = opts.update(args.first) unless args.first.nil?
    Comment.limit(opts[:limit]).sort(opts[:order]).all(:mentions => focus.zooniverse_id)
  end
  
  # Gets the top most used tags
  def self.trending_tags(no=10)
     map = <<-MAP
     function() {
       this.tags.forEach( function(tag) {
         emit(tag, { count: 1 });
       });
     }
     MAP

     reduce = <<-REDUCE
     function(key, values) {
       var total = 0;
       for(var i = 0; i < values.length; i++) {
         total += values[i].count;
       }

       return { count: total };
     }
     REDUCE
     
     tags = Comment.collection.map_reduce(map, reduce).find().sort(['value.count', -1]).limit(no).to_a
     
     collected = {}
     tags.each{ |tag| collected[tag['_id']] = tag['value']['count'].to_i }
     collected
  end
  
  def focus_type
    self.discussion.nil? ? nil : self.discussion.focus_type
  end
  
  def focus_id
    self.discussion.nil? ? nil : self.discussion.focus_id
  end
  
  def focus
    return nil unless focus_type && focus_id
    focus_type.constantize.find(focus_id)
  end
  
  def push_tags
    self.tags.each do |tag|
      Discussion.collection.update({ :_id => self.discussion_id }, { "$inc" => { "taggings.#{tag}" => 1 } })
      focus_type.constantize.collection.update({ :_id => focus_id }, { "$inc" => { "taggings.#{tag}" => 1 } }) if focus_type && focus_id
    end
  end
end
