class CollectionsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter, :only => [:new, :edit, :add]
  respond_to :js, :only => [:add, :remove]
  
  def show
    if params[:id] =~ /^CMZS/
      @focus = @collection = Collection.find_by_zooniverse_id(params[:id])
    else
      @focus = @collection = LiveCollection.find_by_zooniverse_id(params[:id])
    end
    
    @discussion = @collection.conversation
    @mentions = Discussion.mentioning(@collection)
    @comment = Comment.new
    @comments = @collection.conversation.comments
    
    @tags = @collection.keywords
  end
  
  def new
    @collection = Collection.new
    @asset = Asset.find_by_zooniverse_id(params[:object_id]) if params[:object_id]
  end
  
  def edit
    @collection = Collection.find_by_zooniverse_id(params[:id])
  end
  
  def create
    if params[:collection_kind][:id] == "Live Collection"
      @collection = LiveCollection.new(params[:collection])
      @collection.tags = params[:keyword].values
    elsif params[:collection_kind][:id] == "Collection"
      @collection = Collection.new(params[:collection])
    end
    
    @collection.user = current_zooniverse_user
    
    if @collection.save
      flash[:notice] = I18n.t 'controllers.collections.flash_create'
      if @collection.is_a?(LiveCollection)
        redirect_to live_collection_path(@collection.zooniverse_id)
      elsif @collection.is_a?(Collection)
        redirect_to collection_path(@collection.zooniverse_id)
      end
    else
      render :action => 'edit'
    end
  end
  
  def update
    if params[:collection_kind][:id] == "Live Collection"
      @collection = LiveCollection.find(params[:id])
    elsif params[:collection_kind][:id] == "Collection"
      @collection = Collection.find(params[:id])
    end
    
    if @collection.is_a?(LiveCollection)
      @collection.tags = params[:keyword].values
    end
    
    if @collection.update_attributes(params[:collection])
      flash[:notice] = I18n.t 'controllers.collections.flash_updated'
      if @collection.is_a?(LiveCollection)
        redirect_to live_collection_path(@collection.zooniverse_id)
      elsif @collection.is_a?(Collection)
        redirect_to collection_path(@collection.zooniverse_id)
      end
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    if params[:collection_kind] == "Live Collection"
      @collection = LiveCollection.find_by_zooniverse_id(params[:id])
    elsif params[:collection_kind] == "Collection"
      @collection = Collection.find_by_zooniverse_id(params[:id])
    end
    
    if @collection.user == current_zooniverse_user
      @collection.destroy
      flash[:notice] = I18n.t 'controllers.collections.flash_destroyed'
    else
      flash[:alert] = I18n.t 'controllers.collections.not_yours'
    end
    
    redirect_to collections_path
  end
  
  def add
    @collection = Collection.find_by_zooniverse_id(params[:id])
    @asset = Asset.find(params[:asset_id])
    
    unless current_zooniverse_user == @collection.user
      flash[:notice] = I18n.t 'controllers.collections.not_yours'
    end
    
    if @collection.asset_ids.include? @asset.id
      flash[:notice] = I18n.t 'controllers.collections.already_added'
    else
      @collection.asset_ids << @asset.id
      
      if @collection.save
        flash[:notice] = I18n.t('controllers.collections.added')
        @success = true
      end
    end
  end
  
  def remove
    @collection = Collection.find_by_zooniverse_id(params[:id])
    @asset = Asset.find(params[:asset_id])
    
    @collection.asset_ids.delete_if { |id| id == @asset.id }
    
    if @collection.save
      
    end
  end
end
