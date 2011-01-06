require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase
  context "Collections controller" do
    setup do
      @controller = CollectionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end
    
    context "#show not logged in" do
      setup do
        @collection = build_collection
        build_focus_for @collection
        conversation_for @collection
        get :show, { :id => @collection.zooniverse_id }
      end
      
      should respond_with :success
      should render_template :show
      
      should "Display the collection name" do
        assert_select 'h1.collection-title', :text => /.*#{ @collection.name}.*#{ @collection.user.name }.*/m
      end
      
      should "display discussions list" do
        assert_select '.rhc .discussions'
        assert_select '.rhc .discussions:nth-child(1) p a', :text => @discussion.subject
      end
      
      should "display mentions list" do
        assert_select '.rhc .mentions h2', :text => 'Mentions'
        assert_select '.rhc .mentions .item:nth-child(1) a', :text => @discussion.subject
      end
      
      should "display collection tags" do
        assert_select '#tags-for-focus h2', :text => I18n.t('homepage.keywords')
        assert_select '#tags-for-focus ul li a', :text => @collection.keywords.first
      end
      
      should "display collection assets" do
        assert_select ".collection-asset-container .col > a", 2 * @collection.assets.length
      end
      
      should "display login" do
        assert_select '#not-logged-in'
      end
      
      should "display comment list" do
        assert_select '.short-comments'
        assert_select '.short-comments .short-comment:nth-child(1) .body .name a', :text => @conversation.comments.first.author.name
      end
    end
      
    context "#show logged in as creator" do
      setup do
        @collection = build_collection
        build_focus_for @collection
        conversation_for @collection
        standard_cas_login(@collection.user)
        get :show, { :id => @collection.zooniverse_id }
      end
      
      should respond_with :success
      should render_template :show
      
      should "display edit link" do
        assert_select ".asset-actions ul li a", :text => "Edit"
      end
      
      should "display short comment form" do
        assert_select '.short-comment-form form'
      end
      
      should "display upvoting" do
        assert_select '.vote-controls span a', :text => "RECOMMEND"
      end
      
      should "display reporting" do
        assert_select '.vote-controls span a', :text => "REPORT"
      end
    end
      
    context "#edit as the owner" do
      setup do
        @collection = build_collection
        standard_cas_login(@collection.user)
        get :edit, { :id => @collection.zooniverse_id }
      end
      
      should respond_with :success
      should render_template :edit
    end
    
    context "#edit as a different user" do
      setup do
        @collection = build_collection
        standard_cas_login
        get :edit, { :id => @collection.zooniverse_id }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
    end
    
    context "#edit as a moderator" do
      setup do
        @collection = build_collection
        moderator_cas_login
        get :edit, { :id => @collection.zooniverse_id }
      end
      
      should respond_with :success
      should render_template :edit
    end
    
    context "#new" do
      setup do
        get :new
      end
      
      should respond_with :success
      should render_template :new
    end
    
    context "#create Collection" do
      setup do
        @asset = Factory :asset
        standard_cas_login
        
        options = {
          :collection_kind => {
            :id => "Collection"
          },
          :collection => {
            :name => "My Collection",
            :description => "Is awesome",
            :asset_ids => [@asset.id],
            :user_id => @user.id
          }
        }
        post :create, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_create'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
    end
    
    context "#create LiveCollection" do
      setup do
        standard_cas_login
        
        options = {
          :collection_kind => {
            :id => "Keyword Set"
          },
          :keyword => {
            1 => 'tag1',
            2 => 'tag2'
          },
          :collection => {
            :name => "My Collection",
            :description => "Is awesome",
            :user_id => @user.id
          }
        }
        post :create, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_create'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
    end
    
    context "#update Collection as the owner" do
      setup do
        @collection = Factory :collection
        standard_cas_login(@collection.user)
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Collection"
          },
          :collection => {
            :description => "Is more awesome"
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_updated'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
      
      should "update values" do
        assert_equal "Is more awesome", @collection.reload.description
      end
    end
    
    context "#update Collection as a different user" do
      setup do
        @collection = Factory :collection
        standard_cas_login
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Collection"
          },
          :collection => {
            :description => "Is more awesome"
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not update values" do
        assert_equal "This is collection", @collection.reload.description
      end
    end
    
    context "#update Collection as a moderator" do
      setup do
        @collection = Factory :collection
        moderator_cas_login
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Collection"
          },
          :collection => {
            :description => "Is more awesome"
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_updated'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
      
      should "update values" do
        assert_equal "Is more awesome", @collection.reload.description
      end
    end
    
    context "#update LiveCollection as the owner" do
      setup do
        @collection = Factory :live_collection
        standard_cas_login(@collection.user)
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Live Collection"
          },
          :keyword => {
            1 => 'big',
            2 => 'purple',
            3 => 'truck'
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_updated'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
      
      should "update values" do
        assert_same_elements %w(big purple truck), @collection.reload.tags
      end
    end
    
    context "#update LiveCollection as a different user" do
      setup do
        @collection = Factory :live_collection
        standard_cas_login
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Live Collection"
          },
          :keyword => {
            1 => 'big',
            2 => 'purple',
            3 => 'truck'
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not update values" do
        assert_same_elements %w(tag2 tag4), @collection.reload.tags
      end
    end
    
    context "#update LiveCollection as a moderator" do
      setup do
        @collection = Factory :live_collection
        moderator_cas_login
        
        options = {
          :id => @collection.zooniverse_id,
          :collection_kind => {
            :id => "Live Collection"
          },
          :keyword => {
            1 => 'big',
            2 => 'purple',
            3 => 'truck'
          }
        }
        post :update, options
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_updated'))
      should respond_with :found
      should "redirect to collection page" do
        assert_redirected_to collection_path(assigns(:collection).zooniverse_id)
      end
      
      should "update values" do
        assert_same_elements %w(big purple truck), @collection.reload.tags
      end
    end
    
    context "#destroy Collection not logged in" do
      setup do
        @collection = Factory :collection
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Collection" }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not destroy collection" do
        assert_nothing_raised { @collection.reload }
      end
    end
    
    context "#destroy Collection by owner" do
      setup do
        @collection = Factory :collection
        standard_cas_login(@collection.user)
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Collection" }
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_destroyed'))
      should respond_with :found
      
      should "redirect to user profile" do
        assert_redirected_to user_path(@collection.user)
      end
      
      should "destroy and archive collection" do
        assert_raise(MongoMapper::DocumentNotFound) { @collection.reload }
        archive = Archive.first(:kind => "Collection", :original_id => @collection.id)
        
        assert archive
        assert_equal @user.id, archive.destroying_user_id
      end
    end
    
    context "#destroy Collection by other user" do
      setup do
        @collection = Factory :collection
        standard_cas_login
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Collection" }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not destroy collection" do
        assert_nothing_raised { @collection.reload }
      end
    end
    
    context "#destroy Collection by moderator" do
      setup do
        @collection = Factory :collection
        moderator_cas_login
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Collection" }
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_destroyed'))
      should respond_with :found
      
      should "redirect to user profile" do
        assert_redirected_to user_path(@user)
      end
      
      should "destroy and archive collection" do
        assert_raise(MongoMapper::DocumentNotFound) { @collection.reload }
        archive = Archive.first(:kind => "Collection", :original_id => @collection.id)
        
        assert archive
        assert_equal @user.id, archive.destroying_user_id
      end
    end
    
    context "#destroy LiveCollection not logged in" do
      setup do
        @collection = Factory :live_collection
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Keyword Set" }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "destroy collection" do
        assert_nothing_raised { @collection.reload }
      end
    end
    
    context "#destroy LiveCollection by owner" do
      setup do
        @collection = Factory :live_collection
        standard_cas_login(@collection.user)
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Keyword Set" }
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_destroyed'))
      should respond_with :found
      
      should "redirect to user profile" do
        assert_redirected_to user_path(@collection.user)
      end
      
      should "destroy and archive collection" do
        assert_raise(MongoMapper::DocumentNotFound) { @collection.reload }
        archive = Archive.first(:kind => "LiveCollection", :original_id => @collection.id)
        
        assert archive
        assert_equal @user.id, archive.destroying_user_id
      end
    end
    
    context "#destroy LiveCollection by other user" do
      setup do
        @collection = Factory :live_collection
        standard_cas_login
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Keyword Set" }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not destroy collection" do
        assert_nothing_raised { @collection.reload }
      end
    end
    
    context "#destroy LiveCollection by moderator" do
      setup do
        @collection = Factory :live_collection
        moderator_cas_login
        post :destroy, { :id => @collection.zooniverse_id, :collection_kind => "Keyword Set" }
      end
      
      should set_the_flash.to(I18n.t('controllers.collections.flash_destroyed'))
      should respond_with :found
      
      should "redirect to user profile" do
        assert_redirected_to user_path(@user)
      end
      
      should "destroy and archive collection" do
        assert_raise(MongoMapper::DocumentNotFound) { @collection.reload }
        archive = Archive.first(:kind => "LiveCollection", :original_id => @collection.id)
        
        assert archive
        assert_equal @user.id, archive.destroying_user_id
      end
    end
    
    context "#add as owner" do
      setup do
        @asset = Factory :asset
        @collection = build_collection
        standard_cas_login(@collection.user)
        post :add, { :id => @collection.zooniverse_id, :asset_id => @asset.id, :format => :js }
      end
      
      should respond_with :success
      
      should "add asset" do
        assert_contains @collection.reload.asset_ids, @asset.id
      end
    end
    
    context "#add as other user" do
      setup do
        @asset = Factory :asset
        @collection = build_collection
        standard_cas_login
        post :add, { :id => @collection.zooniverse_id, :asset_id => @asset.id, :format => :js }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not add asset" do
        assert_does_not_contain @collection.reload.asset_ids, @asset.id
      end
    end
    
    context "#remove as owner" do
      setup do
        @asset = Factory :asset
        @collection = Factory :collection, :asset_ids => [ @asset.id ]
        standard_cas_login(@collection.user)
        post :remove, { :id => @collection.zooniverse_id, :asset_id => @asset.zooniverse_id, :format => :js }
      end
      
      should respond_with :success
      
      # should set_the_flash.to(I18n.t('controllers.collections.removed'))
      should "set the flash to \"The object has been removed\"" do
        assert_match /.*notice.*#{ I18n.t('controllers.collections.removed') }.*/, response.body
      end
      
      should "remove asset" do
        assert_does_not_contain @collection.reload.asset_ids, @asset.id
      end
    end
    
    context "#remove as other user" do
      setup do
        @asset = Factory :asset
        @collection = Factory :collection, :asset_ids => [ @asset.id ]
        standard_cas_login
        post :remove, { :id => @collection.zooniverse_id, :asset_id => @asset.zooniverse_id, :format => :js }
      end
      
      should set_the_flash.to(I18n.t('controllers.application.not_yours'))
      should respond_with :found
      
      should "redirect to front page" do
        assert_redirected_to root_path
      end
      
      should "not remove asset" do
        assert_contains @collection.reload.asset_ids, @asset.id
      end
    end
  end
end
