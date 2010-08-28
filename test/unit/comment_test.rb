require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  context "A Comment" do
    setup do 
      @asset = Factory :asset
      build_focus_for @asset
      @comment = @comment1
    end
    
    should_have_keys :discussion_id, :response_to_id, :author_id, :upvotes, :body, :tags, :mentions, :created_at, :updated_at, :xap_id
    should_associate :author, :discussion, :events
    should_include_modules 'MongoMapper::Document'
    should_include_plugins :xapify
    
    context "in #response_to another" do
      setup do
        @comment2.response_to = @comment
      end
      
      should "know it is a #response?" do
        assert @comment2.response?
        assert !@comment.response?
      end

      should "store the #response_to_id" do
        assert_equal @comment.id, @comment2.response_to_id
      end
      
      should "find the #response_to comment" do
        assert_equal @comment, @comment2.response_to
      end
    end

    context "when upvoting" do
      setup do
        @user = Factory :user
        @comment.cast_vote_by(@user)
        @votes_before = @comment.reload.upvotes.count
        @comment.cast_vote_by(@user)
      end
      
      should "should add vote" do
        assert @comment.reload.upvotes.include?(@user.id)
      end
      
      should "should only score once " do
        assert_equal @votes_before, @comment.reload.upvotes.count
      end
    end
    
    should "have #keywords" do
      assert_equal @comment.tags, @comment.keywords
    end
    
    should "find #most_recent" do
      assert_contains Comment.most_recent, @comment1
      assert_contains Comment.most_recent, @comment2
      assert_contains Comment.most_recent, @comment3
    end
    
    should "find #mentioning" do
      assert_same_elements [@comment1, @comment2, @comment3], Comment.mentioning(@asset, :limit => 3)
    end
    
    should "find #trending_tags" do
      assert_equal ['tag2', 'tag4', 'tag1'], Comment.trending_tags(3).keys
    end
    
    should "#rank_tags correctly" do
      ranked = Comment.rank_tags :from => 3, :to => 8
      
      assert_equal 3, ranked['tag1']
      assert_equal 6, ranked['tag4']
      assert_equal 8, ranked['tag2']
    end
    
    should "know the #focus_type" do
      assert_equal "Asset", @comment.focus_type
    end
    
    should "know the #focus_id" do
      assert_equal @asset.id, @comment.focus_id
    end
    
    should "know the #focus" do
      assert_equal @asset, @comment.focus
    end
    
    should "#push_tags to discussion and focus" do
      assert_equal ['tag2', 'tag4', 'tag1'], @discussion.tags
      assert_equal ['tag2', 'tag4', 'tag1'], @asset.tags
    end
    
    context "parsing tags and mentions" do
      should "#parse_body for tags and mentions" do
        assert_same_elements ['tag1', 'tag2'], @comment1.tags
        assert_same_elements ['tag2', 'tag4'], @comment2.tags
        assert_same_elements ['tag2', 'tag4'], @comment3.tags

        assert_equal [@asset.zooniverse_id], @comment1.mentions
        assert_equal [@asset.zooniverse_id], @comment2.mentions
        assert_equal [@asset.zooniverse_id], @comment3.mentions
      end
      
      should "match tags" do
        assert_equal "tag1", "#tag1".scan(Comment::TAG).flatten.first
        assert_equal "tag-1", "#tag-1".scan(Comment::TAG).flatten.first
        assert_equal "tag_1", "#tag_1".scan(Comment::TAG).flatten.first
        assert_equal nil, "#t".scan(Comment::TAG).flatten.first
        assert_equal nil, "#t@g1".scan(Comment::TAG).flatten.first
        assert_equal "tag", "#tag 1".scan(Comment::TAG).flatten.first
      end
      
      should "match mentions" do
        assert_equal "AMZ10000aa", "a AMZ10000aa ".scan(Comment::MENTION).flatten.first
        assert_equal nil, "a amz10000aa ".scan(Comment::MENTION).flatten.first
        assert_equal nil, "a amz10000a ".scan(Comment::MENTION).flatten.first
      end
    end
  end
end