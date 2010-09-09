# A Comment on a Discussion by a User
class Comment
  include MongoMapper::Document
  
  key :discussion_id, ObjectId
  key :response_to_id, ObjectId
  key :author_id, ObjectId, :required => true
  key :upvotes, Array
  key :body, String, :required => true
  key :_body, Array
  key :tags, Array
  key :mentions, Array # mentioned Focii, whether these make their way up to the discussion level is TBD
  timestamps!
  
  belongs_to :discussion
  belongs_to :author, :class_name => "User"
  many :events, :as => :eventable
  
  after_validation_on_create :parse_body
  before_create :split_body
  after_create :create_tags
  
  TAG = /#([-\w\d]{3,40})/im
  MENTION = /([A|C|D]MZ\w{7})/m
  
  def self.search(*args)
    opts = { :page => 1, :per_page => 10, :order => :created_at.desc, :field => :_body }.update(args.extract_options!)
    opts[:per_page] = opts[:limit] if opts.has_key?(:limit)
    opts[:fields] = [opts[:fields]] unless opts[:fields].is_a?(Array)
    
    criteria = opts[:criteria] || {}
    criteria.merge!(opts[:field].all => args.first.split)
    where(criteria).sort(opts[:order]).paginate(:page => opts[:page], :per_page => opts[:per_page])
  end
  
  # Sets the comment being responded to
  def response_to=(comment)
    self.response_to_id = comment.id
    self.save if self.changed?
    @cached_response_to = comment
  end
  
  # The comment being responded to
  def response_to
    @cached_response_to ||= Comment.find(self.response_to_id)
  end
  
  # True if this comment is a response
  def response?
    self.response_to_id.nil? ? false : true
  end
  
  # Atomic operation to let a User vote for a Comment
  def cast_vote_by(user)
    return if author.id == user.id
    Comment.collection.update({ '_id' => self.id }, {'$addToSet' => { 'upvotes' => user.id } })
  end
  
  # The most recent comments
  def self.most_recent(limit = 10)
    Comment.limit(limit).sort([:created_at, :desc]).all
  end
  
  # Finds comments mentioning a focus
  def self.mentioning(focus, *args)
    opts = { :limit => 10, :order => [:created_at, :desc] }
    opts = opts.update(args.first) unless args.first.nil?
    Comment.limit(opts[:limit]).sort(opts[:order]).all(:mentions => focus.zooniverse_id)
  end
  
  # Gets the top most used tags
  def self.trending_tags(limit = 10)
    collected = {}
    Tag.sort(:count.desc).limit(limit).each{ |tag| collected[tag.name] = tag.count }
    collected
  end
  
  # Normalizes and interpolates trending_tags onto a range
  #  Comment.rank_tags :from => 0, :to => 8
  def self.rank_tags(*args)
    opts = { :from => 0, :to => 10 }.merge(args.extract_options!)
    new_range = opts[:to] - opts[:from]
    
    trended = trending_tags
    return {} if trended.empty?
    min, max = trended.values.minmax
    old_range = max - min.to_f
    return {} if old_range == 0
    
    trended.each_pair do |tag, count|
      trended[tag] = (opts[:from] + ((count - min) / old_range) * new_range).round
    end
  end
  
  # The focus type of this comment
  def focus_type
    self.discussion.nil? ? nil : self.discussion.focus_type
  end
  
  # The focus id of this comment
  def focus_id
    self.discussion.nil? ? nil : self.discussion.focus_id
  end
  
  # The focus of this comment
  def focus
    return nil unless focus_type && focus_id
    focus_type.constantize.find(focus_id)
  end
  
  def split_body
    self._body = self.body.split
  end
  
  # Finds tags and mentions in the comment body
  def parse_body
    self.tags = self.body.scan(TAG).flatten
    self.mentions = self.body.scan(MENTION).flatten
  end
  
  # Adds tags from this comment to the discussion and focus
  def create_tags
    if focus_type == "Asset"
      Asset.collection.update({ :_id => focus_id }, { :$addToSet => { :tags => { :$each => self.tags } } })
    end
    
    self.tags.uniq.each do |tag_name|
      Tag.collection.update({ :name => tag_name }, { :$inc => { :count => 1 } }, :upsert => true)
      
      unless focus_id.nil?
        Tagging.collection.update({ :name => tag_name, :focus_id => focus_id, :focus_type => focus_type }, {
          :$addToSet => { :discussion_ids => self.discussion_id, :comment_ids => self.id },
          :$inc => { :count => 1 }
        }, :upsert => true)
      end
    end
  end
end
